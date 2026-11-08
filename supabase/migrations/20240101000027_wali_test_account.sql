-- ============================================================================
-- SIM MADIN — Akun uji Wali siap pakai
-- ============================================================================
-- MASALAH
-- ----------------------------------------------------------------------------
-- Tidak ada satu pun migrasi seed yang membuat baris `Wali`. `docs/PHASES.md`
-- bahkan mencatatnya: "need to seed Wali record with PIN first".
--
-- Akibatnya tidak ada kredensial uji yang bisa dipakai di aplikasi wali.
--
-- SYARAT LOGIN WALI (dari `wali_login` RPC, migration 21 + 16)
-- ----------------------------------------------------------------------------
-- Aplikasi wali TIDAK memakai email+password. Logikanya:
--   1. Pengguna mengisi Nomor WhatsApp + PIN 6 digit.
--   2. RPC `wali_login(p_phone, p_pin)` mencari baris `Wali` yang nomornya
--      cocok setelah dinormalisasi (`normalize_phone`), jadi 0812…, 62812…,
--      dan +62812… semuanya cocok.
--   3. Baris itu harus memenuhi SEMUA syarat berikut:
--        a. activationStatus = 'ACTIVE'   (PENDING/SUSPENDED ditolak)
--        b. pinHash = bcrypt dari PIN     (prefix '$2' + crypt() cocok)
--        c. lockedUntil NULL / sudah lewat (5 PIN salah -> kunci 15 menit)
--        d. deletedAt IS NULL
--   4. Setelah PIN benar, RPC mengembalikan `authPassword`; aplikasi memakai
--      email + authPassword itu untuk sign-in ke Supabase Auth agar RLS
--      berlaku.
--   5. Ada baris `SantriWali` dengan `canAccess = true` (kalau tidak, daftar
--      anak kosong dan dashboard tampil tanpa data).
--
-- ISI MIGRASI INI
-- ----------------------------------------------------------------------------
--   1. Perbaiki `provision_wali_profile()` agar menghasilkan wali yang
--      benar-benar bisa login (status ACTIVE, PIN ter-hash, authPassword,
--      tautan santri). Versi sebelumnya memakai 'PENDING' sehingga login
--      SELALU ditolak dengan "Akun belum aktif".
--   2. `create_wali_test_account()` — buat akun wali uji lengkap dalam satu
--      pemanggilan, termasuk membuat baris `Santri` bila NIS belum ada.
--
-- CATATAN KEAMANAN
-- ----------------------------------------------------------------------------
-- Fungsi ini membuat kredensial dengan PIN yang diketahui. JANGAN dipakai di
-- produksi. Semua fungsi hanya bisa dipanggil service_role.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. provision_wali_profile — versi benar (bisa login)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_wali_profile(
  p_email        TEXT,
  p_nis_santri   TEXT DEFAULT NULL,
  p_relationship TEXT DEFAULT 'AYAH',
  p_phone        TEXT DEFAULT NULL,
  p_pin          TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id   TEXT;
  v_name      TEXT;
  v_phone     TEXT;
  v_email     TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
  v_pin       TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  v_email := lower(trim(p_email));

  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email), u.phone
    INTO v_user_id, v_name, v_phone
  FROM "User" u WHERE lower(u.email) = v_email;

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  v_phone := COALESCE(NULLIF(trim(p_phone), ''), v_phone);
  IF v_phone IS NULL OR v_phone = '' THEN
    RETURN QUERY SELECT FALSE,
      'Nomor WhatsApp wajib: isi lewat parameter p_phone atau kolom User.phone. '
      'Tanpa nomor, wali tidak bisa login.';
    RETURN;
  END IF;

  -- PIN default 123456 kalau tidak diberikan (hanya untuk akun uji).
  v_pin := COALESCE(NULLIF(trim(p_pin), ''), '123456');

  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    -- PERBAIKAN PENTING: sebelumnya 'PENDING', dan wali_login menolak semua
    -- status selain 'ACTIVE' — jadi akun hasil provisioning tidak pernah
    -- bisa login.
    INSERT INTO "Wali" (id, "userId", name, phone, email,
                        "activationStatus", "pinHash", "authPassword",
                        "createdAt", "updatedAt")
    VALUES (v_wali_id, v_user_id, v_name, v_phone, v_email,
            'ACTIVE',
            crypt(v_pin, gen_salt('bf', 10)),
            substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                     '[^a-zA-Z0-9]', '', 'g'), 1, 16),
            now(), now());
  ELSE
    -- Pastikan wali yang sudah ada juga memenuhi syarat login.
    UPDATE "Wali"
    SET phone = v_phone,
        email = COALESCE(NULLIF(email, ''), v_email),
        "activationStatus" = 'ACTIVE',
        "pinHash" = CASE
          WHEN p_pin IS NULL OR trim(p_pin) = '' THEN "pinHash"
          ELSE crypt(v_pin, gen_salt('bf', 10))
        END,
        "authPassword" = COALESCE(NULLIF("authPassword", ''),
          substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                   '[^a-zA-Z0-9]', '', 'g'), 1, 16)),
        "failedLoginAttempts" = 0,
        "lockedUntil" = NULL,
        "updatedAt" = now()
    WHERE id = v_wali_id;
  END IF;

  IF p_nis_santri IS NULL OR trim(p_nis_santri) = '' THEN
    RETURN QUERY SELECT TRUE,
      format('Wali siap login (Wali.id = %s). Nomor: %s. Tautkan santri '
             'dengan NIS agar dashboard berisi data.', v_wali_id, v_phone);
    RETURN;
  END IF;

  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = trim(p_nis_santri) AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Santri dengan NIS %s tidak ditemukan. Buat dulu (atau pakai '
             'create_wali_test_account() yang membuatnya otomatis).', p_nis_santri);
    RETURN;
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                            relationship, "isPrimary", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id, TRUE,
          p_relationship, TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Wali siap login. Nomor: %s, PIN: %s. Tertaut ke santri NIS %s.',
           v_phone, v_pin, trim(p_nis_santri));
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. create_wali_test_account — akun uji lengkap sekali panggil
-- ----------------------------------------------------------------------------
-- Membuat: User + UserRole WALI + Wali (ACTIVE, PIN ter-hash, authPassword)
--          + Santri (kalau belum ada) + SantriWali.
-- Santri butuh kelasId opsional; kalau ada Kelas dipakai yang pertama.
CREATE OR REPLACE FUNCTION public.create_wali_test_account(
  p_phone   TEXT DEFAULT '081234567890',
  p_pin     TEXT DEFAULT '123456',
  p_name    TEXT DEFAULT 'Bapak Wali Uji',
  p_email   TEXT DEFAULT NULL,
  p_nis     TEXT DEFAULT '2024001',
  p_santri  TEXT DEFAULT 'Santri Uji'
)
RETURNS TABLE(success BOOLEAN, message TEXT, phone TEXT, pin TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email     TEXT;
  v_phone     TEXT;
  v_user_id   TEXT;
  v_role_id   TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
  v_kelas_id  TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  v_phone := public.normalize_phone(p_phone);
  IF v_phone IS NULL OR length(v_phone) < 9 THEN
    RETURN QUERY SELECT FALSE, 'Nomor WhatsApp tidak valid.', p_phone, p_pin;
    RETURN;
  END IF;

  v_email := COALESCE(NULLIF(lower(trim(p_email)), ''),
                      'wali' || right(v_phone, 4) || '@madrasah.test');

  -- Role WALI harus ada
  SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = 'WALI';
  IF v_role_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      'Role WALI tidak ada. Jalankan migration 03 lebih dulu.', v_phone, p_pin;
    RETURN;
  END IF;

  -- User (buat kalau belum ada)
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE lower(u.email) = v_email OR u.phone = v_phone
  ORDER BY (lower(u.email) = v_email) DESC NULLS LAST LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, phone, "isActive",
                        "createdAt", "updatedAt")
    VALUES (v_user_id, v_email, split_part(v_email, '@', 1), p_name, v_phone,
            TRUE, now(), now());
  END IF;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
  ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;

  -- Wali
  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    INSERT INTO "Wali" (id, "userId", name, phone, email, "activationStatus",
                        "pinHash", "authPassword", "createdAt", "updatedAt")
    VALUES (v_wali_id, v_user_id, p_name, v_phone, v_email, 'ACTIVE',
            crypt(p_pin, gen_salt('bf', 10)),
            substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                     '[^a-zA-Z0-9]', '', 'g'), 1, 16),
            now(), now());
  ELSE
    UPDATE "Wali"
    SET phone = v_phone, email = v_email, "activationStatus" = 'ACTIVE',
        "pinHash" = crypt(p_pin, gen_salt('bf', 10)),
        "authPassword" = COALESCE(NULLIF("authPassword", ''),
          substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                   '[^a-zA-Z0-9]', '', 'g'), 1, 16)),
        "failedLoginAttempts" = 0, "lockedUntil" = NULL, "updatedAt" = now()
    WHERE id = v_wali_id;
  END IF;

  -- Santri (buat kalau belum ada)
  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = p_nis AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    SELECT k.id INTO v_kelas_id FROM "Kelas" k
    WHERE k."deletedAt" IS NULL ORDER BY k."createdAt" LIMIT 1;

    v_santri_id := gen_random_uuid()::TEXT;
    INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                          "entryDate", "createdAt", "updatedAt")
    -- gender memakai kode 'L' / 'P' (lihat SantriGender di Dart), BUKAN
    -- 'LAKI_LAKI'. status memakai 'AKTIF' (SantriStatus.aktif).
    VALUES (v_santri_id, p_nis, p_santri, 'L', 'AKTIF', v_kelas_id,
            CURRENT_DATE, now(), now());
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                            relationship, "isPrimary", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id, TRUE,
          'AYAH', TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Akun wali uji siap. Nomor %s / PIN %s. Santri NIS %s (%s anak).',
           v_phone, p_pin, p_nis,
           (SELECT count(*) FROM "SantriWali" sw WHERE sw."waliId" = v_wali_id)),
    v_phone, p_pin;
END;
$$;

-- ----------------------------------------------------------------------------
-- Hak eksekusi: service_role saja
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.provision_wali_profile(TEXT, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.create_wali_test_account(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- CARA PAKAI
-- ============================================================================
--   -- Akun wali uji default (nomor 081234567890 / PIN 123456):
--   SELECT * FROM public.create_wali_test_account();
--
--   -- Kustom:
--   SELECT * FROM public.create_wali_test_account(
--     p_phone => '081298765432',
--     p_pin   => '654321',
--     p_name  => 'Bapak Ahmad',
--     p_nis   => '2024002',
--     p_santri=> 'Ahmad Fauzi'
--   );
--
--   -- Perbaiki akun wali yang sudah ada agar bisa login:
--   SELECT * FROM public.provision_wali_profile(
--     'wali@gmail.com', '2024001', 'AYAH', '081234567890', '123456');
--
--   -- Verifikasi rantai login wali:
--   SELECT * FROM public.check_wali_link((SELECT id FROM "Wali" LIMIT 1));
-- ============================================================================
