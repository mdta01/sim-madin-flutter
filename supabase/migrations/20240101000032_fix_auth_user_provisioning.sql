-- ============================================================================
-- SIM MADIN — Diagnostik pembuatan akun + perbaikan insert auth.users
-- ============================================================================
-- GEJALA
-- ----------------------------------------------------------------------------
-- Setelah menjalankan seed_all_demo(), login dengan mdta@madrasah.com dan
-- akun demo lain gagal: "Invalid login credentials" / akun tidak terdaftar.
--
-- PENYEBAB YANG PALING UMUM
-- ----------------------------------------------------------------------------
--   A. auth.users tidak terisi  -> penyebab utama, lihat penjelasan di bawah
--   B. auth.users terisi tetapi auth.identities tidak -> GoTrue tidak bisa
--      menemukan user saat login email/password
--   C. encrypted_password bukan bcrypt -> selalu "invalid credentials"
--   D. email belum confirmed -> login ditolak bila "Confirm email" aktif
--   E. seed_all_demo() tidak pernah dijalankan / gagal di tengah jalan
--
-- MENGAPA INSERT KE auth.users GAMPANG GAGAL
-- ----------------------------------------------------------------------------
-- Tabel auth.users punya kolom NOT NULL yang berbeda antar versi GoTrue.
-- Versi lama: confirmation_token, recovery_token, email_change_token_new,
-- email_change WAJIB (tanpa default). Versi baru menambah
-- email_change_token_current, phone_change, phone_change_token,
-- reauth_token. Kalau satu saja NOT NULL dan tidak diisi, SELURUH INSERT
-- gagal -> tidak ada user yang terbentuk, dan pesan errornya mudah terlewat
-- karena dijalankan dari dalam fungsi.
--
-- STRATEGI: isi SEMUA kolom token yang mungkin ada, secara dinamis.
-- Kolom yang tidak eksis tidak di-insert (dideteksi dari information_schema),
-- sehingga fungsi ini aman di berbagai versi GoTrue.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Prasyarat: pgcrypto untuk bcrypt
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 1. Diagnostik: kenapa akun ini tidak bisa login?
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.diagnose_login(p_email TEXT)
RETURNS TABLE(langkah TEXT, ok BOOLEAN, keterangan TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email  TEXT := lower(trim(p_email));
  v_uid    UUID;
  v_user   RECORD;
  v_pass   TEXT;
  v_ident  INT;
  v_conf   TIMESTAMPTZ;
  v_banned TIMESTAMPTZ;
  v_roles  TEXT;
BEGIN
  -- 1. Ada di auth.users?
  SELECT au.id, au.encrypted_password, au.email_confirmed_at,
         au.banned_until
    INTO v_uid, v_pass, v_conf, v_banned
  FROM auth.users au
  WHERE lower(au.email) = v_email;

  langkah := '1_auth_users';
  ok := v_uid IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ada, uid=' || v_uid::TEXT
                     ELSE 'TIDAK ADA di auth.users — GoTrue akan menolak login. '
                          'Jalankan provision_login_account().' END;
  RETURN NEXT;
  IF NOT ok THEN RETURN; END IF;

  -- 2. Password hash bcrypt?
  langkah := '2_password_bcrypt';
  ok := v_pass IS NOT NULL AND v_pass LIKE '$2%';
  keterangan := CASE
    WHEN v_pass IS NULL OR v_pass = '' THEN 'password KOSONG'
    WHEN v_pass NOT LIKE '$2%' THEN 'bukan bcrypt (prefix: '
         || left(v_pass, 4) || ')'
    ELSE 'bcrypt ok' END;
  RETURN NEXT;

  -- 3. Email confirmed?
  langkah := '3_email_confirmed';
  ok := v_conf IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ya'
                     ELSE 'BELUM — login bisa ditolak bila Confirm email aktif' END;
  RETURN NEXT;

  -- 4. Tidak diblokir?
  langkah := '4_tidak_diblokir';
  ok := v_banned IS NULL OR v_banned < now();
  keterangan := CASE WHEN ok THEN 'ok'
                     ELSE 'banned_until = ' || v_banned::TEXT END;
  RETURN NEXT;

  -- 5. auth.identities ada?
  SELECT count(*) INTO v_ident FROM auth.identities WHERE user_id = v_uid;
  langkah := '5_auth_identities';
  ok := v_ident > 0;
  keterangan := CASE WHEN ok THEN v_ident || ' baris'
                     ELSE 'TIDAK ADA — GoTrue tidak bisa menemukan user '
                          'untuk login email/password' END;
  RETURN NEXT;

  -- 6. Baris User aplikasi + peran
  SELECT u.* INTO v_user FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

  langkah := '6_user_row';
  ok := v_user.id IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ada, id=' || v_user.id
                     ELSE 'tidak ada baris "User" (aplikasi tetap bisa login, '
                          'tetapi semua data akan kosong)' END;
  RETURN NEXT;
  IF v_user.id IS NULL THEN RETURN; END IF;

  SELECT string_agg(r.code, ', ' ORDER BY r.code) INTO v_roles
  FROM "UserRole" ur JOIN "Role" r ON r.id = ur."roleId"
  WHERE ur."userId" = v_user.id AND ur."isActive";

  langkah := '7_peran';
  ok := v_roles IS NOT NULL;
  keterangan := COALESCE(v_roles, 'TANPA PERAN — semua layar akan kosong');
  RETURN NEXT;

  RETURN;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Provision akun login yang tahan versi GoTrue
-- ----------------------------------------------------------------------------
-- Membuat/memperbaiki auth.users + auth.identities untuk satu email.
-- Idempotent: aman dipanggil berulang.
CREATE OR REPLACE FUNCTION public.provision_login_account(
  p_email    TEXT,
  p_password TEXT,
  p_name     TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, auth_uid UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email TEXT := lower(trim(p_email));
  v_name  TEXT := COALESCE(NULLIF(trim(p_name), ''), split_part(lower(trim(p_email)), '@', 1));
  v_uid   UUID;
  v_hash  TEXT;

  -- daftar kolom token yang dikenal GoTrue, isi hanya yang benar-benar ada
  v_cols  TEXT[] := ARRAY[]::TEXT[];
  v_vals  TEXT[] := ARRAY[]::TEXT[];
  v_sql   TEXT;
  c       TEXT;
BEGIN
  IF v_email IS NULL OR position('@' IN v_email) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Email tidak valid.', NULL::UUID;
    RETURN;
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN QUERY SELECT FALSE, 'Password minimal 6 karakter.', NULL::UUID;
    RETURN;
  END IF;

  v_hash := crypt(p_password, gen_salt('bf', 10));

  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;

  IF v_uid IS NOT NULL THEN
    -- Sudah ada: paksa password & konfirmasi supaya pasti bisa login.
    UPDATE auth.users
    SET encrypted_password = v_hash,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now(),
        banned_until = NULL
    WHERE id = v_uid;
  ELSE
    v_uid := gen_random_uuid();

    -- Susun INSERT secara dinamis: kolom dasar selalu ada, kolom token
    -- hanya disertakan bila kolomnya memang ada di instalasi ini.
    v_cols := ARRAY['id','instance_id','aud','role','email',
                    'encrypted_password','email_confirmed_at',
                    'created_at','updated_at',
                    'raw_app_meta_data','raw_user_meta_data'];
    v_vals := ARRAY[
      quote_literal(v_uid::TEXT),
      quote_literal('00000000-0000-0000-0000-000000000000'),
      quote_literal('authenticated'),
      quote_literal('authenticated'),
      quote_literal(v_email),
      quote_literal(v_hash),
      'now()', 'now()', 'now()',
      quote_literal(jsonb_build_object(
        'provider','email','providers',jsonb_build_array('email'))::TEXT),
      quote_literal(jsonb_build_object('name', v_name)::TEXT)
    ];

    FOREACH c IN ARRAY ARRAY[
      'confirmation_token','recovery_token','email_change_token_new',
      'email_change','email_change_token_current','phone_change',
      'phone_change_token','reauth_token'
    ] LOOP
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth' AND table_name = 'users'
          AND column_name = c
      ) THEN
        v_cols := v_cols || c;
        v_vals := v_vals || quote_literal('');
      END IF;
    END LOOP;

    v_sql := format(
      'INSERT INTO auth.users (%s) VALUES (%s)',
      array_to_string(array(SELECT quote_ident(x) FROM unnest(v_cols) x), ', '),
      array_to_string(v_vals, ', ')
    );
    EXECUTE v_sql;
  END IF;

  -- auth.identities — wajib untuk login email/password
  IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_uid) THEN
    INSERT INTO auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
      jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                         'email_verified', TRUE, 'phone_verified', FALSE),
      now(), now(), now()
    );
  ELSE
    UPDATE auth.identities
    SET identity_data = jsonb_build_object(
          'sub', v_uid::TEXT, 'email', v_email,
          'email_verified', TRUE, 'phone_verified', FALSE),
        updated_at = now()
    WHERE user_id = v_uid AND provider = 'email';
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun login %s siap (uid=%s).', v_email, v_uid), v_uid;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. admin_create_staff_account — versi tahan versi (memakai provision_login_account)
-- ----------------------------------------------------------------------------
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
  v_msg      TEXT;
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

  -- Akun login: pakai provisioner yang tahan beda versi GoTrue.
  SELECT pl.auth_uid, pl.message INTO v_uid, v_msg
  FROM public.provision_login_account(v_email, p_password, p_name) pl;

  IF v_uid IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Gagal membuat akun login untuk %s: %s', v_email, v_msg),
      NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  -- Baris User aplikasi
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

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

  -- Peran
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

  -- Profil Guru otomatis
  IF 'GURU' = ANY (COALESCE(p_roles, ARRAY[]::TEXT[])) THEN
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
-- 4. Perbaiki semua akun demo yang sudah ada (tanpa membuat ulang data)
-- ----------------------------------------------------------------------------
-- Gunakan ini bila seed sudah dijalankan dan baris User/UserRole sudah ada,
-- tetapi akun login-nya tidak terbentuk.
CREATE OR REPLACE FUNCTION public.repair_demo_logins()
RETURNS TABLE(email TEXT, success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  r RECORD;
  v_uid UUID;
  v_msg TEXT;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('mdta@madrasah.com',      'admin@mdta01'),
      ('kepala@madrasah.com',    'kepala123'),
      ('bendahara@madrasah.com', 'bendahara123'),
      ('guru@madrasah.com',      'guru123'),
      ('guru2@madrasah.com',     'guru123')
    ) AS t(mail, pass)
  LOOP
    SELECT pl.auth_uid, pl.message INTO v_uid, v_msg
    FROM public.provision_login_account(r.mail, r.pass, NULL) pl;

    email := r.mail;
    success := v_uid IS NOT NULL;
    message := v_msg;
    RETURN NEXT;

    -- Pastikan baris User tertaut ke auth uid (agar peran & data terbaca)
    IF v_uid IS NOT NULL THEN
      UPDATE "User"
      SET "firebaseUid" = v_uid::TEXT, "isActive" = TRUE,
          "deletedAt" = NULL, "updatedAt" = now()
      WHERE lower(email) = r.mail;
    END IF;
  END LOOP;

  RETURN;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Diagnostik menyeluruh akun demo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.demo_account_status()
RETURNS TABLE(
  email        TEXT,
  ada_auth     BOOLEAN,
  email_conf   BOOLEAN,
  bcrypt       BOOLEAN,
  ada_identity BOOLEAN,
  ada_user_row BOOLEAN,
  peran        TEXT,
  siap_login   BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    d.mail,
    (au.id IS NOT NULL),
    (au.email_confirmed_at IS NOT NULL),
    (au.encrypted_password LIKE '$2%'),
    EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = au.id),
    EXISTS (SELECT 1 FROM "User" u WHERE lower(u.email) = d.mail),
    COALESCE((
      SELECT string_agg(r.code, ', ' ORDER BY r.code)
      FROM "User" u
      JOIN "UserRole" ur ON ur."userId" = u.id AND ur."isActive"
      JOIN "Role" r ON r.id = ur."roleId"
      WHERE lower(u.email) = d.mail
    ), '—'),
    (au.id IS NOT NULL
     AND au.email_confirmed_at IS NOT NULL
     AND au.encrypted_password LIKE '$2%'
     AND EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = au.id)
     AND EXISTS (SELECT 1 FROM "User" u WHERE lower(u.email) = d.mail))
  FROM (VALUES
      ('mdta@madrasah.com'),
      ('kepala@madrasah.com'),
      ('bendahara@madrasah.com'),
      ('guru@madrasah.com'),
      ('guru2@madrasah.com')
  ) AS d(mail)
  LEFT JOIN auth.users au ON lower(au.email) = d.mail
  ORDER BY d.mail;
$$;

-- ----------------------------------------------------------------------------
-- Hak eksekusi
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.diagnose_login(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_login_account(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_create_staff_account(TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.repair_demo_logins() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.demo_account_status() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- LANGKAH PENYELESAIAN (jalankan berurutan di SQL Editor)
-- ============================================================================
-- 1. Lihat kondisi akun sekarang:
--    SELECT * FROM public.demo_account_status();
--
-- 2. Perbaiki semua akun demo:
--    SELECT * FROM public.repair_demo_logins();
--
-- 3. Verifikasi: semua kolom siap_login harus TRUE
--    SELECT * FROM public.demo_account_status();
--
-- 4. Bila masih gagal, periksa satu akun langkah demi langkah:
--    SELECT * FROM public.diagnose_login('mdta@madrasah.com');
--
-- Bila setelah semua siap_login = TRUE login masih ditolak, kemungkinan
-- besar Supabase Auth mengaktifkan "Confirm email". Matikan di
-- Authentication -> Providers -> Email, atau pastikan email_confirmed_at
-- terisi (fungsi di atas sudah mengisinya).
-- ============================================================================
