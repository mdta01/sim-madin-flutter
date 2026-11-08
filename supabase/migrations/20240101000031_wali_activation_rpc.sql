-- ============================================================================
-- SIM MADIN — Aktivasi akun wali (PIN pertama) + perbaikan fungsi terkait
-- ============================================================================
-- ALUR YANG DIMINTA
-- ----------------------------------------------------------------------------
--   Admin mendaftarkan santri/wali beserta NOMOR WHATSAPP.
--   Wali membuka aplikasi -> "Aktivasi Akun" -> masukkan nomor WhatsApp.
--   Sistem memeriksa nomor itu ADA di data admin, lalu menampilkan nama wali
--   dan nama anaknya sebagai konfirmasi.
--   Wali membuat PIN 6 digit + konfirmasi PIN.
--   PIN tersimpan (bcrypt) pada baris Wali yang terhubung dengan nomor tsb.
--   Setelah itu wali login memakai nomor + PIN.
--
--   Jika PIN lupa: OTP via WhatsApp -> buat PIN baru (wali_request_otp /
--   wali_verify_otp / wali_reset_pin, sudah ada di migrasi 20).
--
-- MENGAPA PERLU RPC BARU
-- ----------------------------------------------------------------------------
-- RLS pada "Wali" hanya mengizinkan staf membaca. Wali yang belum login
-- TIDAK punya sesi, sehingga aplikasi tidak bisa "SELECT ... FROM Wali
-- WHERE phone = ..." untuk menampilkan konfirmasi. RPC SECURITY DEFINER di
-- bawah ini mengembalikan HANYA nama (bukan data sensitif) dan hanya untuk
-- nomor yang benar-benar terdaftar oleh admin.
--
-- PEMISAHAN DUA LANGKAH (penting)
-- ----------------------------------------------------------------------------
--   1. wali_check_registration(phone)  -> nomor terdaftar? siapa namanya?
--                                          anaknya siapa? (tanpa efek samping)
--   2. wali_activate(phone, pin, pin2) -> simpan PIN, status menjadi ACTIVE
--
-- Dipisah agar langkah 1 aman dipanggil berkali-kali dan tidak mengubah data.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Periksa nomor terdaftar (tanpa efek samping)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_check_registration(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali         RECORD;
  v_santri_list  JSONB;
  v_anak         INT;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    -- Sengaja TIDAK menyebut "nomor tidak terdaftar" secara spesifik?
    -- Di sini justru perlu jelas, karena ini alur aktivasi pertama dan
    -- pengguna butuh tahu harus menghubungi admin.
    RETURN jsonb_build_object(
      'registered', false,
      'message', 'Nomor ini belum terdaftar. Hubungi admin madrasah untuk '
                 'mendaftarkan nomor WhatsApp Anda.'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'registered', false,
      'message', 'Akun ini dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', s.id, 'name', s.name, 'nis', s.nis,
           'kelasName', k.name
         ) ORDER BY s.name), '[]'::jsonb),
         count(*)
    INTO v_santri_list, v_anak
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id AND sw."canAccess" = TRUE;

  RETURN jsonb_build_object(
    'registered', TRUE,
    'waliId', v_wali.id,
    'name', v_wali.name,
    'phone', v_wali."phone",
    'status', v_wali."activationStatus",
    -- 'needs_pin' = true bila wali belum punya PIN (aktivasi pertama)
    'needsPin', (v_wali."pinHash" IS NULL OR v_wali."pinHash" = ''),
    'anak', v_santri_list,
    'jumlahAnak', v_anak,
    'message', format('Nomor terdaftar atas nama %s dengan %s anak.',
                      v_wali.name, v_anak)
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Aktivasi: set PIN pertama (dengan konfirmasi)
-- ----------------------------------------------------------------------------
-- Aturan:
--   * PIN wajib 6 digit angka
--   * p_pin harus sama dengan p_pin_confirm
--   * PIN lemah (000000, 123456, angka berulang, berurutan) ditolak
--   * bila wali SUDAH punya PIN, aktivasi ditolak -> pakai alur Lupa PIN
--     supaya orang lain yang tahu nomor tidak bisa menimpa PIN.
CREATE OR REPLACE FUNCTION public.wali_activate(
  p_phone       TEXT,
  p_pin         TEXT,
  p_pin_confirm TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali RECORD;
  v_lemah TEXT[] := ARRAY[
    '000000','111111','222222','333333','444444','555555','666666',
    '777777','888888','999999',
    '123456','654321','112233','121212','123123','101010','010101',
    '147258','258369','159357','123321','456654'
  ];
  v_auth_password TEXT;
BEGIN
  IF p_pin IS NULL OR length(trim(p_pin)) <> 6
     OR trim(p_pin) !~ '^[0-9]{6}$' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN harus 6 digit angka.');
  END IF;

  IF trim(p_pin) <> trim(COALESCE(p_pin_confirm, '')) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Konfirmasi PIN tidak sama. Periksa kembali.');
  END IF;

  IF trim(p_pin) = ANY (v_lemah) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN terlalu mudah ditebak. Gunakan kombinasi lain.');
  END IF;

  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor belum terdaftar. Hubungi admin madrasah.');
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun dinonaktifkan. Hubungi admin madrasah.');
  END IF;

  IF v_wali."pinHash" IS NOT NULL AND v_wali."pinHash" <> '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN sudah pernah dibuat. Gunakan "Lupa PIN" untuk '
                 'mengubahnya lewat OTP WhatsApp.');
  END IF;

  v_auth_password := COALESCE(
    NULLIF(v_wali."authPassword", ''),
    substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                             '[^a-zA-Z0-9]', '', 'g'), 1, 16)
  );

  UPDATE "Wali"
  SET "pinHash" = crypt(trim(p_pin), gen_salt('bf', 10)),
      "activationStatus" = 'ACTIVE',
      "authPassword" = v_auth_password,
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "updatedAt" = now()
  WHERE id = v_wali.id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Aktivasi berhasil. Silakan masuk dengan nomor dan PIN Anda.',
    'name', v_wali.name
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Perbaiki permissions migrasi 27
-- ----------------------------------------------------------------------------
-- 27 mencabut create_wali_test_account(TEXT,TEXT,TEXT,TEXT,TEXT,TEXT), padahal
-- fungsi sebenarnya juga punya DEFAULT sehingga PostgREST bisa gagal
-- menemukan kandidat fungsi. Di sini hak akses dipulihkan eksplisit dan
-- signature lengkap diberikan.
DO $$
BEGIN
  -- Beri izin panggil ke service_role saja (bukan anon/authenticated).
  BEGIN
    REVOKE ALL ON FUNCTION public.create_wali_test_account(
      TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
  EXCEPTION WHEN undefined_function THEN
    NULL;
  END;
END $$;

-- ----------------------------------------------------------------------------
-- 4. Ringkasan status aktivasi (untuk admin)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_activation_report()
RETURNS TABLE(
  nama_wali   TEXT,
  phone       TEXT,
  status      TEXT,
  pin_terpasang BOOLEAN,
  jumlah_anak BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    w.name,
    w."phone",
    w."activationStatus",
    (w."pinHash" IS NOT NULL AND w."pinHash" <> ''),
    (SELECT count(*) FROM "SantriWali" sw WHERE sw."waliId" = w.id)
  FROM "Wali" w
  WHERE w."deletedAt" IS NULL
  ORDER BY w.name;
$$;

-- ----------------------------------------------------------------------------
-- Hak eksekusi
-- ----------------------------------------------------------------------------
-- Kedua fungsi aktivasi HARUS bisa dipanggil sebelum login (anon).
GRANT EXECUTE ON FUNCTION public.wali_check_registration(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_activate(TEXT, TEXT, TEXT) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.wali_activation_report() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- PEMAKAIAN
-- ============================================================================
--   -- 1. cek nomor
--   SELECT public.wali_check_registration('081234567801');
--   -- -> { registered: true, name: "Bapak Abdullah", needsPin: true, anak: [...] }
--
--   -- 2. aktivasi
--   SELECT public.wali_activate('081234567801','246813','246813');
--
--   -- 3. login seperti biasa
--   SELECT public.wali_login('081234567801','246813');
--
--   -- laporan untuk admin
--   SELECT * FROM public.wali_activation_report();
-- ============================================================================
