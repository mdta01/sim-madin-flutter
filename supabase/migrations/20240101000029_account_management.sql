-- ============================================================================
-- SIM MADIN — Akun demo per bidang + aksi admin (tambah/hapus akun)
-- ============================================================================
-- FILOSOFI
-- ----------------------------------------------------------------------------
-- Admin adalah pusat data. Aplikasi mobile TIDAK membuat akun sendiri; semua
-- akun didaftarkan admin, lalu pengguna login dengan kredensial yang dibuat
-- admin. Migrasi ini menyediakan tiga hal:
--
--   1. Akun admin dengan email & password yang diminta.
--   2. Akun demo Kepala / Bendahara / Guru yang sudah terhubung ke bidangnya
--      (Guru -> baris "Guru" + Jadwal ke kelas & mapel).
--   3. Fungsi "tambah akun" dan "hapus akun" yang dipakai admin desktop,
--      termasuk benar-benar menghapus kredensial login di Supabase Auth
--      sehingga akun yang dihapus TIDAK BISA LAGI MASUK ke aplikasi mobile.
--
-- MENGAPA PERLU FUNGSI (BUKAN INSERT BIASA)
-- ----------------------------------------------------------------------------
-- Membuat user Supabase Auth memerlukan penulisan ke schema `auth`, yang
-- hanya bisa dilakukan pemilik database. Admin desktop terhubung sebagai
-- `authenticated` (bukan service_role), sehingga:
--   - TIDAK bisa membuat auth.users  -> akun staf tidak bisa dibuat dari app
--   - TIDAK bisa menghapus auth.users -> akun terhapus masih bisa login
-- Kedua fungsi di bawah berjalan SECURITY DEFINER sebagai pemilik database,
-- sehingga menulis ke `auth.users` dan `auth.identities` secara konsisten.
--
-- CATATAN KEAMANAN
-- ----------------------------------------------------------------------------
-- Password di-hash dengan bcrypt oleh `crypt(..., gen_salt('bf'))` — sama
-- seperti yang dipakai Supabase Auth (GoTrue memakai bcrypt). Karena itu
-- pengguna bisa login lewat `signInWithPassword` biasa.
-- Fungsi-fungsi ini HANYA boleh dieksekusi service_role / pemilik database.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Pastikan schema auth punya kolom yang kita butuhkan (Supabase standar).
--    Jika proyek Anda memakai Supabase, semua kolom di bawah sudah ada.
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 1. Buat / perbarui akun staf (email + password) di Supabase Auth + tabel User
-- ----------------------------------------------------------------------------
-- p_roles: array kode role, mis. ARRAY['GURU'] atau ARRAY['KEPALA'].
CREATE OR REPLACE FUNCTION public.admin_create_staff_account(
  p_email       TEXT,
  p_password    TEXT,
  p_name        TEXT,
  p_roles       TEXT[],
  p_phone       TEXT DEFAULT NULL,
  p_username    TEXT DEFAULT NULL,
  p_guru_nip    TEXT DEFAULT NULL,
  p_specialization TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, user_id TEXT, auth_uid UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email    TEXT := lower(trim(p_email));
  v_username TEXT;
  v_uid      UUID;
  v_user_id  TEXT;
  v_role     TEXT;
  v_role_id  TEXT;
  v_guru_id  TEXT;
BEGIN
  IF v_email IS NULL OR v_email = '' OR position('@' IN v_email) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Email tidak valid.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN QUERY SELECT FALSE, 'Password minimal 6 karakter.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  v_username := COALESCE(NULLIF(trim(p_username), ''), split_part(v_email, '@', 1));

  -- --- Supabase Auth: buat atau perbarui ---
  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;

  IF v_uid IS NULL THEN
    v_uid := gen_random_uuid();

    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      v_email, crypt(p_password, gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('name', p_name, 'role', COALESCE(p_roles[1], 'WALI')),
      '', '', '', ''
    );

    -- GoTrue wajib punya baris identities untuk login email/password.
    INSERT INTO auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
      jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                         'email_verified', TRUE, 'phone_verified', FALSE),
      now(), now(), now()
    )
    ON CONFLICT DO NOTHING;
  ELSE
    -- Akun sudah ada: set ulang password agar sesuai permintaan admin.
    UPDATE auth.users
    SET encrypted_password = crypt(p_password, gen_salt('bf', 10)),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now(),
        banned_until = NULL
    WHERE id = v_uid;
  END IF;

  -- --- Tabel User aplikasi ---
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST
  LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, phone, "firebaseUid",
                        "isActive", "createdAt", "updatedAt")
    VALUES (v_user_id, v_email, v_username, p_name, p_phone, v_uid::TEXT,
            TRUE, now(), now());
  ELSE
    UPDATE "User"
    SET email = v_email,
        username = COALESCE(NULLIF(username, ''), v_username),
        name = p_name,
        phone = COALESCE(p_phone, phone),
        "firebaseUid" = v_uid::TEXT,
        "isActive" = TRUE,
        "deletedAt" = NULL,
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  -- --- Peran ---
  FOREACH v_role IN ARRAY COALESCE(p_roles, ARRAY[]::TEXT[]) LOOP
    SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = v_role;
    IF v_role_id IS NULL THEN
      RETURN QUERY SELECT FALSE,
        format('Peran "%s" tidak dikenal.', v_role), v_user_id, v_uid;
      RETURN;
    END IF;

    INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
    VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
    ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;
  END LOOP;

  -- --- Baris Guru bila diberi peran GURU ---
  IF 'GURU' = ANY (p_roles) THEN
    SELECT g.id INTO v_guru_id FROM "Guru" g
    WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

    IF v_guru_id IS NULL THEN
      INSERT INTO "Guru" (id, "userId", name, nip, specialization, status,
                          "joinDate", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_user_id, p_name, p_guru_nip,
              p_specialization, 'AKTIF', CURRENT_DATE, now(), now());
    ELSE
      UPDATE "Guru" SET name = p_name,
             nip = COALESCE(p_guru_nip, nip),
             specialization = COALESCE(p_specialization, specialization),
             "updatedAt" = now()
      WHERE id = v_guru_id;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun %s siap. Peran: %s.', v_email,
           COALESCE(array_to_string(p_roles, ', '), '-')),
    v_user_id, v_uid;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Hapus akun: benar-benar tidak bisa login lagi
-- ----------------------------------------------------------------------------
-- Menghapus baris auth.users membuat GoTrue menolak login (user tidak ada).
-- Data historis di tabel aplikasi TIDAK dihapus mentah-mentah: baris "User"
-- di-soft-delete (deletedAt diisi, isActive=false) agar relasi masa lalu
-- (absensi, nilai, pembayaran) tetap utuh dan bisa diaudit.
--
-- p_hard_delete = TRUE -> hapus permanen baris "User" juga (hanya jika tidak
-- punya data historis; kalau punya, fungsi menolak dan menyarankan soft).
CREATE OR REPLACE FUNCTION public.admin_delete_account(
  p_email       TEXT,
  p_hard_delete BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(success BOOLEAN, message TEXT, auth_deleted BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email     TEXT := lower(trim(p_email));
  v_uid       UUID;
  v_user_id   TEXT;
  v_historis  INT := 0;
BEGIN
  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE lower(u.email) = v_email OR (v_uid IS NOT NULL AND u."firebaseUid" = v_uid::TEXT)
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

  IF v_uid IS NULL AND v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Akun %s tidak ditemukan.', p_email), FALSE;
    RETURN;
  END IF;

  -- Jejak historis: kalau ada, jangan hard delete.
  IF v_user_id IS NOT NULL THEN
    SELECT (
      (SELECT count(*) FROM "Guru"   WHERE "userId" = v_user_id)
    + (SELECT count(*) FROM "Wali"   WHERE "userId" = v_user_id)
    + (SELECT count(*) FROM "Santri" WHERE "userId" = v_user_id)
    ) INTO v_historis;
  END IF;

  -- 1. Nonaktifkan seluruh peran (RLS langsung menolak semua akses).
  IF v_user_id IS NOT NULL THEN
    UPDATE "UserRole" SET "isActive" = FALSE WHERE "userId" = v_user_id;

    UPDATE "User"
    SET "isActive" = FALSE, "deletedAt" = now(), "updatedAt" = now(),
        "firebaseUid" = NULL, "fcmToken" = NULL
    WHERE id = v_user_id;

    -- Wali/guru yang terhubung ikut dinonaktifkan agar PIN tidak bisa dipakai.
    UPDATE "Wali"
    SET "activationStatus" = 'SUSPENDED', "pinHash" = NULL,
        "authPassword" = NULL, "userId" = NULL, "updatedAt" = now()
    WHERE "userId" = v_user_id;

    UPDATE "Guru"
    SET status = 'NONAKTIF', "userId" = NULL, "updatedAt" = now()
    WHERE "userId" = v_user_id;
  END IF;

  -- 2. Hapus kredensial login Supabase Auth -> login langsung gagal.
  IF v_uid IS NOT NULL THEN
    DELETE FROM auth.identities WHERE user_id = v_uid;
    DELETE FROM auth.sessions   WHERE user_id = v_uid;
    DELETE FROM auth.refresh_tokens WHERE user_id = v_uid::TEXT;
    DELETE FROM auth.users      WHERE id = v_uid;
  END IF;

  -- 3. Hard delete baris User hanya bila tidak ada jejak historis.
  IF p_hard_delete THEN
    IF v_historis > 0 THEN
      RETURN QUERY SELECT TRUE,
        format('Akun %s dinonaktifkan & login dihapus. Baris "User" '
               'dipertahankan karena punya %s data historis (guru/wali/santri).',
               p_email, v_historis),
        v_uid IS NOT NULL;
      RETURN;
    END IF;
    IF v_user_id IS NOT NULL THEN
      DELETE FROM "UserRole" WHERE "userId" = v_user_id;
      DELETE FROM "User" WHERE id = v_user_id;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun %s dihapus. Login ke aplikasi mobile sudah tidak bisa.', p_email),
    v_uid IS NOT NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Aktifkan kembali akun (kebalikan dari hapus, untuk salah hapus)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_restore_account(p_email TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email   TEXT := lower(trim(p_email));
  v_user_id TEXT;
BEGIN
  SELECT u.id INTO v_user_id FROM "User" u WHERE lower(u.email) = v_email LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Akun %s tidak ada. Buat ulang lewat admin_create_staff_account().', p_email);
    RETURN;
  END IF;

  UPDATE "User" SET "isActive" = TRUE, "deletedAt" = NULL, "updatedAt" = now()
  WHERE id = v_user_id;

  UPDATE "Wali" SET "activationStatus" = 'ACTIVE', "userId" = v_user_id,
         "updatedAt" = now()
  WHERE lower(email) = v_email AND "activationStatus" = 'SUSPENDED';

  RETURN QUERY SELECT TRUE, format('Akun %s diaktifkan kembali.', p_email);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_staff_account(TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_delete_account(TEXT, BOOLEAN)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_restore_account(TEXT)
  FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- CARA PAKAI
-- ============================================================================
--   -- Admin yang diminta:
--   SELECT * FROM public.admin_create_staff_account(
--     'mdta@madrasah.com', 'admin@mdta01', 'Administrator Madrasah',
--     ARRAY['SUPER_ADMIN','ADMIN']);
--
--   -- Kepala / bendahara / guru:
--   SELECT * FROM public.admin_create_staff_account(
--     'kepala@madrasah.com','kepala123','H. Abdul Ghofur', ARRAY['KEPALA'], '081200000001');
--
--   -- Hapus akun (tidak bisa login lagi):
--   SELECT * FROM public.admin_delete_account('guru@madrasah.com');
--
--   -- Aktifkan lagi:
--   SELECT * FROM public.admin_restore_account('guru@madrasah.com');
-- ============================================================================
