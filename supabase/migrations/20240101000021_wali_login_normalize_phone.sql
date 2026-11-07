-- ============================================================================
-- SIM MADIN — wali_login: cocokkan nomor WhatsApp secara ternormalisasi
-- ============================================================================
-- Bug: `wali_login()` memakai `WHERE "phone" = p_phone` (perbandingan persis).
-- Wali yang tersimpan sebagai '081234511001' tidak bisa login kalau mengetik
-- '+62 812-3451-1001' atau '6281234511001', walaupun itu nomor yang sama.
-- Karena nomor adalah SATU-SATUNYA identitas login wali, variasi format ini
-- membuat sebagian wali tidak bisa masuk sama sekali.
--
-- Fix: pakai public.normalize_phone() (dibuat di migration 20) di kedua sisi
-- perbandingan. Logika PIN/limit/lock tidak berubah — hanya pencocokan nomor.
--
-- Catatan: fungsi ini sengaja tetap SECURITY DEFINER dan tetap mengembalikan
-- authPassword setelah PIN terverifikasi (dipakai untuk sign-in Supabase Auth
-- per-wali yang membuat RLS `current_wali_id()` bekerja).
-- ============================================================================

DO $$
BEGIN
  -- Pastikan helper tersedia (migration 20 harus sudah jalan).
  IF to_regproc('public.normalize_phone') IS NULL THEN
    RAISE EXCEPTION
      'public.normalize_phone() belum ada — jalankan migration 20 dulu';
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali        RECORD;
  v_santri_list JSONB;
BEGIN
  -- 1. Cari wali berdasarkan nomor ternormalisasi.
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor WhatsApp tidak terdaftar'
    );
  END IF;

  -- 2. Status aktivasi.
  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun Anda dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."activationStatus" <> 'ACTIVE' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message',
      'Akun belum aktif (status: ' || v_wali."activationStatus" ||
      '). Hubungi admin madrasah.'
    );
  END IF;

  -- 3. Auto-lock.
  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object(
      'success', false,
      'message',
      'Akun terkunci. Coba lagi dalam ' ||
      (EXTRACT(EPOCH FROM (v_wali."lockedUntil" - NOW()))::int / 60) ||
      ' menit.'
    );
  END IF;

  -- 4. Verifikasi PIN (bcrypt).
  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = ''
     OR crypt(p_pin, v_wali."pinHash") <> v_wali."pinHash" THEN
    UPDATE "Wali"
    SET "failedLoginAttempts" = COALESCE("failedLoginAttempts", 0) + 1,
        "lockedUntil" = CASE
          WHEN COALESCE("failedLoginAttempts", 0) + 1 >= 5
          THEN NOW() + INTERVAL '15 minutes'
          ELSE "lockedUntil"
        END
    WHERE id = v_wali.id;

    RETURN jsonb_build_object(
      'success', false,
      'message',
      'PIN salah. Sisa percobaan: ' ||
      GREATEST(0, 5 - COALESCE(v_wali."failedLoginAttempts", 0) - 1)
    );
  END IF;

  -- 5. Login berhasil.
  UPDATE "Wali"
  SET "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  -- 6. Daftar anak (SantriWali -> Santri -> Kelas).
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'nis', s.nis,
    'nisn', s.nisn,
    'gender', s.gender,
    'kelasId', s."kelasId",
    'kelasName', k.name,
    'kelasCode', k.code,
    'status', s.status,
    'photoUrl', s."photoUrl",
    'birthDate', s."birthDate",
    'birthPlace', s."birthPlace",
    'address', s.address,
    'entryDate', s."entryDate"
  )), '[]'::jsonb) INTO v_santri_list
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id
    AND sw."canAccess" = true;

  -- 7. Response.
  RETURN jsonb_build_object(
    'success', true,
    'wali', jsonb_build_object(
      'id', v_wali.id,
      'name', v_wali.name,
      'phone', v_wali."phone",
      'email', v_wali."email",
      'nik', v_wali."nik",
      'occupation', v_wali."occupation",
      'address', v_wali."address",
      'photoUrl', v_wali."photoUrl",
      'relationship', v_wali."relationship",
      'activationStatus', v_wali."activationStatus",
      'userId', v_wali."userId",
      'lastLoginAt', NOW(),
      'authPassword', v_wali."authPassword"
    ),
    'santriList', v_santri_list
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   -- ketiga format harus menemukan wali yang sama:
--   SELECT public.wali_login('081234511001', '<pin>');
--   SELECT public.wali_login('6281234511001', '<pin>');
--   SELECT public.wali_login('+62 812-3451-1001', '<pin>');
-- ============================================================================
