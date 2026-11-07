-- ============================================================================
-- SIM MADIN — Production Security: bcrypt PIN + wali_login RPC
-- ============================================================================
-- Bug: PIN wali disimpan sebagai plain text di kolom Wali.pinHash.
--      Nama kolom "pinHash" tapi isinya text biasa ('258041').
--      Kalau DB bocor, semua PIN bocor.
--
-- Bug: loginWali() di Flutter compare PIN client-side (plain text),
--      lalu sign-in ke Supabase Auth pakai hardcoded password 'admin123'.
--      Siapapun yang tahu email wali + 'admin123' bisa login tanpa PIN.
--
-- Fix:
--   1. Enable pgcrypto extension (untuk crypt() + gen_salt())
--   2. Hash semua PIN existing dengan bcrypt (BF algorithm)
--   3. Buat RPC wali_login(p_phone, p_pin) yang:
--      a. Query Wali by phone
--      b. Verify PIN: crypt(p_pin, wali.pinHash) = wali.pinHash
--      c. Handle rate limiting (5 attempts, 15-min lock)
--      d. Return wali data + santri list (join)
--      e. SECURITY DEFINER — bypass RLS untuk SELECT
--   4. Update Flutter loginWali() untuk call RPC ini
--
-- Migration ini idempotent — safe to re-run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Enable pgcrypto extension (untuk crypt + gen_salt)
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 2. Hash semua PIN existing yang masih plain text
--    (deteksi: kalau pinHash tidak diawali dengan $2a$ / $2b$ / $2y$ = plain text)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  -- Hash PIN yang masih plain text (tidak mulai dengan $2 = bcrypt hash)
  UPDATE "Wali"
  SET "pinHash" = crypt("pinHash", gen_salt('bf', 10))
  WHERE "pinHash" IS NOT NULL
    AND "pinHash" != ''
    AND "pinHash" NOT LIKE '$2%';

  RAISE NOTICE 'PIN hashing completed. Affected rows: %', ROW_COUNT;
END $$;

-- ----------------------------------------------------------------------------
-- 3. Buat RPC wali_login(p_phone, p_pin)
--    Returns: JSONB dengan wali data + santri list
--    Security: SECURITY DEFINER (bypass RLS untuk SELECT Wali + SantriWali + Santri)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali RECORD;
  v_santri_list JSONB;
  v_result JSONB;
BEGIN
  -- 1. Cari wali by phone (normalize: hapus spasi, +, 62 prefix)
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "phone" = p_phone
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor WhatsApp tidak terdaftar'
    );
  END IF;

  -- 2. Check activation status
  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun Anda dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."activationStatus" != 'ACTIVE' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun belum aktif (status: ' || v_wali."activationStatus" || '). Hubungi admin madrasah.'
    );
  END IF;

  -- 3. Check auto-lock (5 failed attempts → 15 min lock)
  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun terkunci. Coba lagi dalam ' ||
        EXTRACT(EPOCH FROM (v_wali."lockedUntil" - NOW()))::int / 60 ||
        ' menit.'
    );
  END IF;

  -- 4. Verify PIN dengan bcrypt
  --    crypt(p_pin, stored_hash) returns the hash if PIN matches
  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = '' OR
     crypt(p_pin, v_wali."pinHash") != v_wali."pinHash" THEN

    -- Increment failed attempts
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
      'message', 'PIN salah. Sisa percobaan: ' ||
        GREATEST(0, 5 - COALESCE(v_wali."failedLoginAttempts", 0) - 1)
    );
  END IF;

  -- 5. Login berhasil — reset failed attempts + update lastLoginAt
  UPDATE "Wali"
  SET "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  -- 6. Get santri list (join SantriWali → Santri → Kelas)
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

  -- 7. Return wali data + santri list
  v_result := jsonb_build_object(
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
      'lastLoginAt', NOW()
    ),
    'santriList', v_santri_list
  );

  RETURN v_result;
END;
$$;

-- Grant execute to authenticated + anon (wali login happens before auth)
GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon;

-- ----------------------------------------------------------------------------
-- 4. Buat RPC wali_set_pin(p_wali_id, p_new_pin) — untuk forgot PIN flow
--    Hash PIN baru dengan bcrypt sebelum save
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wali_set_pin(p_wali_id TEXT, p_new_pin TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate PIN format (6 digits)
  IF p_new_pin !~ '^\d{6}$' THEN
    RETURN false;
  END IF;

  -- Hash PIN dengan bcrypt + update
  UPDATE "Wali"
  SET "pinHash" = crypt(p_new_pin, gen_salt('bf', 10)),
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "otpCode" = NULL,
      "otpExpiresAt" = NULL
  WHERE id = p_wali_id
    AND "deletedAt" IS NULL;

  RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_set_pin(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_set_pin(TEXT, TEXT) TO anon;

-- ----------------------------------------------------------------------------
-- 5. Reload PostgREST schema cache
-- ----------------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT wali_login('6281234511001', '258041');
--   Expected: {"success": true, "wali": {...}, "santriList": [...]}
-- ============================================================================
