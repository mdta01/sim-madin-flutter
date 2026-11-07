-- ============================================================================
-- SIM MADIN — Provisioning akun Supabase Auth untuk wali + diagnostik RLS
-- ============================================================================
-- MASALAH
-- ----------------------------------------------------------------------------
-- Login wali (WA + PIN) berhasil di RPC `wali_login`, lalu aplikasi menandatangani
-- sesi Supabase Auth memakai email + `Wali.authPassword` yang dikembalikan RPC
-- tersebut. Sesi itu yang membuat RLS bekerja, karena SEMUA policy wali
-- bergantung pada rantai:
--
--   auth.uid()  ->  User.firebaseUid  ->  User.id
--                     -> UserRole(isActive, role WALI)
--                     -> Wali.userId  ->  SantriWali  ->  Santri
--
-- Migration 3 hanya meng-link user berdasarkan email TEST yang di-hardcode
-- (admin@madrasah.test, dll) dan, lebih berbahaya, MEMBUAT baris `User` baru
-- untuk SETIAP akun Supabase Auth yang belum punya baris — termasuk akun wali,
-- tanpa role apa pun. Kalau salah satu mata rantai di atas putus, wali tetap
-- bisa login tetapi:
--
--   * `has_role('WALI')` = false  -> semua policy SELECT wali gagal
--   * `current_wali_id()` = null  -> `is_wali_of_santri()` = false
--
-- Gejalanya: dashboard wali tampil KOSONG (anak, nilai, absensi, tagihan,
-- pengumuman, chat) tanpa pesan error apa pun — karena RLS memang menyaring
-- semua baris, bukan melempar exception.
--
-- SOLUSI
-- ----------------------------------------------------------------------------
-- 1. `provision_wali_auth()` — link akun Supabase Auth wali ke tabel User,
--    beri role WALI, dan pastikan `Wali.userId` menunjuk ke User tersebut.
--    Idempotent, aman dijalankan berulang. Dipanggil dari dashboard admin
--    (menu Wali) atau manual lewat SQL Editor/service_role.
-- 2. `check_wali_link(wali_id)` — diagnostik per wali: menampilkan mata rantai
--    mana yang putus, supaya admin bisa memperbaiki tanpa menebak-nebak.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Provisioning akun auth untuk wali
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_wali_auth(
  p_wali_id TEXT,
  p_auth_uid UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali     RECORD;
  v_user_id  TEXT;
  v_role_id  TEXT;
  v_uid      UUID;
BEGIN
  SELECT * INTO v_wali FROM "Wali" WHERE id = p_wali_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Wali tidak ditemukan');
  END IF;

  IF v_wali."deletedAt" IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Wali sudah dihapus');
  END IF;

  -- Tentukan auth uid: parameter eksplisit, atau cari via email di auth.users.
  v_uid := p_auth_uid;
  IF v_uid IS NULL AND v_wali.email IS NOT NULL AND v_wali.email <> '' THEN
    SELECT id INTO v_uid FROM auth.users WHERE email = v_wali.email LIMIT 1;
  END IF;

  -- Cari / buat baris User.
  SELECT id INTO v_user_id
  FROM "User"
  WHERE "firebaseUid" = v_uid::text
     OR (v_wali.email IS NOT NULL AND email = v_wali.email)
  LIMIT 1;

  IF v_user_id IS NULL THEN
    IF v_uid IS NULL THEN
      RETURN jsonb_build_object(
        'success', false,
        'message',
        'Akun Supabase Auth untuk wali ini belum ada. Buat user auth dulu '
        '(email wali) atau kirim p_auth_uid.'
      );
    END IF;

    INSERT INTO "User" (
      id, email, username, "passwordHash", name, phone,
      "firebaseUid", "isActive", "createdAt", "updatedAt"
    ) VALUES (
      replace(gen_random_uuid()::text, '-', ''),
      COALESCE(v_wali.email, 'wali+' || v_wali.id || '@madrasah.local'),
      'wali_' || left(v_wali.id, 12),
      '',
      v_wali.name,
      v_wali."phone",
      v_uid::text,
      true,
      now(),
      now()
    )
    RETURNING id INTO v_user_id;
  ELSE
    -- Pastikan link auth uid terpasang.
    UPDATE "User"
    SET "firebaseUid" = COALESCE("firebaseUid", v_uid::text),
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  -- Pastikan Wali.userId menunjuk ke User tersebut.
  UPDATE "Wali"
  SET "userId" = v_user_id, "updatedAt" = now()
  WHERE id = p_wali_id
    AND ("userId" IS DISTINCT FROM v_user_id);

  -- Pastikan role WALI aktif.
  SELECT id INTO v_role_id FROM "Role" WHERE code = 'WALI' LIMIT 1;
  IF v_role_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Role WALI belum ada. Jalankan migration 3 (bootstrap roles).'
    );
  END IF;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (
    replace(gen_random_uuid()::text, '-', ''), v_user_id, v_role_id, true, now()
  )
  ON CONFLICT ("userId", "roleId") DO UPDATE
  SET "isActive" = true;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Akun wali berhasil di-provision',
    'userId', v_user_id,
    'authUid', v_uid::text
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Diagnostik: mata rantai mana yang putus?
-- ----------------------------------------------------------------------------
-- Gunakan dari admin: SELECT check_wali_link((SELECT id FROM "Wali" LIMIT 1));
-- Kolom `ok` = false menandakan penyebab layar kosong pada akun wali tsb.
CREATE OR REPLACE FUNCTION public.check_wali_link(p_wali_id TEXT)
RETURNS TABLE (
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali      RECORD;
  v_user      RECORD;
  v_role_id   TEXT;
  v_ur_active BOOLEAN;
  v_santri    INT;
  v_auth_uid  UUID;
BEGIN
  SELECT * INTO v_wali FROM "Wali" WHERE id = p_wali_id;

  check_name := 'wali_exists';
  ok := FOUND AND v_wali."deletedAt" IS NULL;
  detail := CASE WHEN FOUND THEN COALESCE(v_wali.name, '-') ELSE 'Wali tidak ada' END;
  RETURN NEXT;
  IF NOT ok THEN RETURN; END IF;

  check_name := 'activation_status';
  ok := v_wali."activationStatus" = 'ACTIVE';
  detail := COALESCE(v_wali."activationStatus", 'NULL');
  RETURN NEXT;

  check_name := 'pin_hash_set';
  ok := v_wali."pinHash" IS NOT NULL AND v_wali."pinHash" LIKE '$2%';
  detail := CASE
    WHEN v_wali."pinHash" IS NULL THEN 'PIN belum diset'
    WHEN v_wali."pinHash" NOT LIKE '$2%' THEN 'PIN masih plain-text (jalankan migration 15)'
    ELSE 'bcrypt ok' END;
  RETURN NEXT;

  check_name := 'auth_password_set';
  ok := v_wali."authPassword" IS NOT NULL AND v_wali."authPassword" <> '';
  detail := CASE WHEN ok THEN 'ada' ELSE 'kosong (jalankan migration 16)' END;
  RETURN NEXT;

  check_name := 'wali_user_linked';
  ok := v_wali."userId" IS NOT NULL;
  detail := COALESCE(v_wali."userId", 'Wali.userId NULL');
  RETURN NEXT;

  IF NOT ok THEN RETURN; END IF;

  SELECT * INTO v_user FROM "User" WHERE id = v_wali."userId";

  check_name := 'user_firebase_uid';
  ok := v_user."firebaseUid" IS NOT NULL;
  detail := COALESCE(v_user."firebaseUid", 'User.firebaseUid NULL');
  RETURN NEXT;

  IF ok THEN
    -- Cast aman: firebaseUid bisa berisi nilai non-UUID dari data lama.
    BEGIN
      SELECT au.id INTO v_auth_uid
      FROM auth.users au
      WHERE au.id = v_user."firebaseUid"::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      v_auth_uid := NULL;
    END;

    check_name := 'auth_user_exists';
    ok := v_auth_uid IS NOT NULL;
    detail := CASE WHEN ok THEN v_auth_uid::text
                   ELSE 'Tidak ada di auth.users (provision dulu)' END;
    RETURN NEXT;
  END IF;

  SELECT id INTO v_role_id FROM "Role" WHERE code = 'WALI' LIMIT 1;
  check_name := 'role_wali_exists';
  ok := v_role_id IS NOT NULL;
  detail := COALESCE(v_role_id, 'Role WALI tidak ada');
  RETURN NEXT;

  IF ok THEN
    SELECT ur."isActive" INTO v_ur_active
    FROM "UserRole" ur
    WHERE ur."userId" = v_wali."userId" AND ur."roleId" = v_role_id;
    check_name := 'has_active_role_wali';
    ok := COALESCE(v_ur_active, false);
    detail := CASE WHEN ok THEN 'aktif' ELSE 'UserRole WALI tidak aktif/tidak ada' END;
    RETURN NEXT;
  END IF;

  SELECT count(*) INTO v_santri
  FROM "SantriWali" sw
  WHERE sw."waliId" = p_wali_id AND sw."canAccess" = true;
  check_name := 'linked_santri';
  ok := v_santri > 0;
  detail := v_santri || ' santri';
  RETURN NEXT;
END;
$$;

-- Provisioning & diagnostik hanya untuk staff (dipanggil dari admin desktop).
REVOKE ALL ON FUNCTION public.provision_wali_auth(TEXT, UUID) FROM anon;
REVOKE ALL ON FUNCTION public.check_wali_link(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.provision_wali_auth(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.check_wali_link(TEXT) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT * FROM public.check_wali_link((SELECT id FROM "Wali" LIMIT 1));
--   SELECT public.provision_wali_auth((SELECT id FROM "Wali" LIMIT 1));
-- ============================================================================
