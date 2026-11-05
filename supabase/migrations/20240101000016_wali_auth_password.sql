-- ============================================================================
-- SIM MADIN — Replace hardcoded admin123 with per-wali random auth password
-- ============================================================================
-- Bug: loginWali() signs in to Supabase Auth with email + 'admin123'
-- (hardcoded universal password). Anyone who knows email + 'admin123'
-- can bypass PIN entirely.
--
-- Fix:
--   1. Add Wali.authPassword column (TEXT, stores random per-wali password)
--   2. Update wali_login RPC to return authPassword (for Flutter sign-in)
--   3. Generate random password for all existing walis
--   4. Update Supabase Auth users with these passwords
--
-- Security: authPassword is returned only after PIN verify succeeds
-- (inside wali_login RPC which is SECURITY DEFINER). Only the correct
-- wali (verified by PIN) gets their own authPassword.
-- ============================================================================

-- 1. Add authPassword column to Wali
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Wali' AND column_name = 'authPassword'
  ) THEN
    ALTER TABLE "Wali" ADD COLUMN "authPassword" TEXT;
    RAISE NOTICE 'Added authPassword column to Wali';
  END IF;
END $$;

-- 2. Generate random password for all walis that don't have one
--    Format: 16 random alphanumeric chars
DO $$
DECLARE
  v_wali RECORD;
  v_password TEXT;
BEGIN
  FOR v_wali IN
    SELECT id, email FROM "Wali"
    WHERE "deletedAt" IS NULL
      AND email IS NOT NULL AND email != ''
      AND ("authPassword" IS NULL OR "authPassword" = '')
  LOOP
    -- Generate 16-char random password (alphanumeric)
    v_password := substring(
      regexp_replace(
        encode(gen_random_bytes(32), 'hex'),
        '[^a-zA-Z0-9]', '', 'g'
      ),
      1, 16
    );

    UPDATE "Wali" SET "authPassword" = v_password WHERE id = v_wali.id;
    RAISE NOTICE 'Generated authPassword for wali: %', v_wali.email;
  END LOOP;
END $$;

-- 3. Update wali_login RPC to return authPassword in response
--    (only after PIN verify succeeds — security by design)
CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali RECORD;
  v_santri_list JSONB;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "phone" = p_phone
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nomor WhatsApp tidak terdaftar');
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun dinonaktifkan.');
  END IF;

  IF v_wali."activationStatus" != 'ACTIVE' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun belum aktif.');
  END IF;

  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun terkunci.');
  END IF;

  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = '' OR
     crypt(p_pin, v_wali."pinHash") != v_wali."pinHash" THEN
    UPDATE "Wali"
    SET "failedLoginAttempts" = COALESCE("failedLoginAttempts", 0) + 1,
        "lockedUntil" = CASE
          WHEN COALESCE("failedLoginAttempts", 0) + 1 >= 5 THEN NOW() + INTERVAL '15 minutes'
          ELSE "lockedUntil"
        END
    WHERE id = v_wali.id;
    RETURN jsonb_build_object('success', false, 'message', 'PIN salah.');
  END IF;

  -- Login berhasil
  UPDATE "Wali"
  SET "failedLoginAttempts" = 0, "lockedUntil" = NULL, "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id, 'name', s.name, 'nis', s.nis, 'nisn', s.nisn,
    'gender', s.gender, 'kelasId', s."kelasId", 'kelasName', k.name,
    'kelasCode', k.code, 'status', s.status, 'photoUrl', s."photoUrl",
    'birthDate', s."birthDate", 'birthPlace', s."birthPlace",
    'address', s.address, 'entryDate', s."entryDate"
  )), '[]'::jsonb) INTO v_santri_list
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id AND sw."canAccess" = true;

  RETURN jsonb_build_object(
    'success', true,
    'wali', jsonb_build_object(
      'id', v_wali.id, 'name', v_wali.name, 'phone', v_wali."phone",
      'email', v_wali."email", 'nik', v_wali."nik",
      'occupation', v_wali."occupation", 'address', v_wali."address",
      'photoUrl', v_wali."photoUrl", 'relationship', v_wali."relationship",
      'activationStatus', v_wali."activationStatus",
      'userId', v_wali."userId", 'lastLoginAt', NOW(),
      'authPassword', v_wali."authPassword"
    ),
    'santriList', v_santri_list
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon;

-- 4. Sync authPassword to Supabase Auth users (update their password)
--    This must be done via Supabase Admin API — cannot do via SQL.
--    Script below generates the update commands for reference.
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Post-migration: sync authPassword to Supabase Auth
-- Run this Python script after migration (uses Supabase Admin API):
--
--   python3 scripts/sync_wali_auth_passwords.py
--
-- Or manually via Dashboard > Authentication > Users > Edit each user.
-- ============================================================================
