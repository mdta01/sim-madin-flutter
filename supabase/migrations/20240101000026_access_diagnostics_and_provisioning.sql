-- ============================================================================
-- SIM MADIN — Diagnostik akses akun & provisioning peran
-- ============================================================================
-- MASALAH YANG DISELESAIKAN
-- ----------------------------------------------------------------------------
-- Migration 03 (`bootstrap_roles_and_links`) hanya memberi peran ke LIMA email
-- uji yang di-hardcode:
--
--     admin@madrasah.test      -> SUPER_ADMIN
--     kepala@madrasah.test     -> KEPALA
--     bendahara@madrasah.test  -> BENDAHARA
--     guru@madrasah.test       -> GURU
--     wali@madrasah.test       -> WALI
--
-- Tidak ada fallback. Akun mana pun selain lima email itu berakhir TANPA peran
-- di tabel `UserRole`. Karena hampir semua policy RLS bergantung pada
-- `has_role()` / `is_staff()`, akun tanpa peran melihat SEMUA tabel sebagai
-- kosong — tanpa pesan error apa pun, karena RLS hanya menyaring baris.
--
-- Tambahan lagi: tidak ada satu pun migrasi yang membuat baris `Guru`.
-- `current_guru_id()` mengembalikan NULL untuk setiap pengguna, sehingga
-- policy guru (absensi, jadwal, materi, tugas, nilai) tidak pernah cocok.
--
-- Gabungan keduanya menghasilkan gejala: aplikasi bisa login, navigasi jalan,
-- tetapi setiap layar berisi data kosong.
--
-- ISI MIGRASI INI
-- ----------------------------------------------------------------------------
--   1. `diagnose_account_access()` — periksa rantai akses satu akun dan
--      kembalikan daftar langkah mana yang putus.
--   2. `provision_account_role()` — beri peran ke sebuah email (idempotent).
--   3. `provision_guru_profile()` — buat baris `Guru` untuk akun pengguna.
--   4. `provision_wali_profile()` — buat baris `Wali` + tautkan ke Santri.
--   5. `assign_guru_to_kelas()` — tautkan guru ke kelas (lewat Jadwal).
--   6. `access_audit()` — ringkasan SEMUA akun: punya peran? punya profil?
--
-- Semua fungsi SECURITY DEFINER dan hanya boleh dieksekusi service_role /
-- postgres. Tidak diberikan ke anon maupun authenticated.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Diagnostik satu akun
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.diagnose_account_access(p_email TEXT)
RETURNS TABLE(
  step TEXT,
  ok BOOLEAN,
  detail TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id   UUID;
  v_user_id   TEXT;
  v_active    BOOLEAN;
  v_roles     TEXT;
  v_guru_id   TEXT;
  v_wali_id   TEXT;
  v_santri_ct INT;
  v_kelas_ct  INT;
BEGIN
  -- Langkah 1: akun Supabase Auth
  SELECT au.id INTO v_auth_id
  FROM auth.users au
  WHERE lower(au.email) = lower(trim(p_email));

  step := 'auth_user_exists';
  ok := v_auth_id IS NOT NULL;
  detail := CASE WHEN ok THEN v_auth_id::TEXT
                 ELSE 'Tidak ada akun login dengan email ini. Buat dulu di Supabase Auth.' END;
  RETURN NEXT;

  IF NOT ok THEN
    RETURN;
  END IF;

  -- Langkah 2: baris User
  SELECT u.id, u."isActive" INTO v_user_id, v_active
  FROM "User" u
  WHERE u."firebaseUid" = v_auth_id::TEXT
     OR lower(u.email) = lower(trim(p_email))
  ORDER BY (u."firebaseUid" = v_auth_id::TEXT) DESC NULLS LAST
  LIMIT 1;

  step := 'user_row_linked';
  ok := v_user_id IS NOT NULL;
  detail := CASE WHEN ok
                 THEN 'User.id = ' || v_user_id
                 ELSE 'Tidak ada baris "User" yang terhubung ke auth.uid. Jalankan provision_account_role().' END;
  RETURN NEXT;

  IF NOT ok THEN
    RETURN;
  END IF;

  -- Langkah 3: akun aktif
  step := 'user_active';
  ok := COALESCE(v_active, false);
  detail := CASE WHEN ok THEN 'Aktif' ELSE 'User.isActive = false — akun dinonaktifkan.' END;
  RETURN NEXT;

  -- Langkah 4: peran
  SELECT string_agg(r.code, ', ' ORDER BY r.code) INTO v_roles
  FROM "UserRole" ur
  JOIN "Role" r ON r.id = ur."roleId"
  WHERE ur."userId" = v_user_id
    AND ur."isActive" = true;

  step := 'has_role';
  ok := v_roles IS NOT NULL;
  detail := CASE WHEN ok
                 THEN 'Peran: ' || v_roles
                 ELSE 'TIDAK PUNYA PERAN — semua data akan tampak kosong. Jalankan provision_account_role().' END;
  RETURN NEXT;

  IF v_roles IS NULL THEN
    RETURN;
  END IF;

  -- Langkah 5: profil Guru (hanya relevan bila punya peran GURU)
  IF v_roles LIKE '%GURU%' THEN
    SELECT g.id INTO v_guru_id FROM "Guru" g
    WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

    step := 'guru_row_exists';
    ok := v_guru_id IS NOT NULL;
    detail := CASE WHEN ok
                   THEN 'Guru.id = ' || v_guru_id
                   ELSE 'Belum ada baris "Guru". current_guru_id() = NULL sehingga data kelas/absensi kosong. Jalankan provision_guru_profile().' END;
    RETURN NEXT;

    IF v_guru_id IS NOT NULL THEN
      SELECT count(DISTINCT j."kelasId") INTO v_kelas_ct
      FROM "Jadwal" j WHERE j."guruId" = v_guru_id;

      step := 'guru_has_kelas';
      ok := COALESCE(v_kelas_ct, 0) > 0;
      detail := CASE WHEN ok
                     THEN v_kelas_ct || ' kelas terdaftar'
                     ELSE 'Guru belum dijadwalkan ke kelas mana pun. is_guru_of_kelas() selalu false sehingga absensi/nilai tidak bisa diisi.' END;
      RETURN NEXT;
    END IF;
  END IF;

  -- Langkah 6: profil Wali (hanya relevan bila punya peran WALI)
  IF v_roles LIKE '%WALI%' THEN
    SELECT w.id INTO v_wali_id FROM "Wali" w
    WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

    step := 'wali_row_exists';
    ok := v_wali_id IS NOT NULL;
    detail := CASE WHEN ok
                   THEN 'Wali.id = ' || v_wali_id
                   ELSE 'Belum ada baris "Wali". Jalankan provision_wali_profile().' END;
    RETURN NEXT;

    IF v_wali_id IS NOT NULL THEN
      SELECT count(*) INTO v_santri_ct
      FROM "SantriWali" sw WHERE sw."waliId" = v_wali_id;

      step := 'wali_has_santri';
      ok := COALESCE(v_santri_ct, 0) > 0;
      detail := CASE WHEN ok
                     THEN v_santri_ct || ' santri tertaut'
                     ELSE 'Wali belum tertaut ke santri mana pun — dashboard akan kosong.' END;
      RETURN NEXT;
    END IF;
  END IF;

  RETURN;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Beri peran ke sebuah email
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_account_role(
  p_email     TEXT,
  p_role_code TEXT,
  p_full_name TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id UUID;
  v_user_id TEXT;
  v_role_id TEXT;
  v_name    TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "Role" WHERE code = p_role_code) THEN
    RETURN QUERY SELECT FALSE,
      format('Peran "%s" tidak dikenal. Pilihan: SUPER_ADMIN, ADMIN, KEPALA, '
             'BENDAHARA, GURU, WALI.', p_role_code);
    RETURN;
  END IF;

  SELECT au.id, COALESCE(p_full_name, au.raw_user_meta_data->>'name',
                         split_part(au.email, '@', 1))
    INTO v_auth_id, v_name
  FROM auth.users au
  WHERE lower(au.email) = lower(trim(p_email));

  IF v_auth_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Email %s belum terdaftar di Supabase Auth. Buat akunnya dulu.',
             p_email);
    RETURN;
  END IF;

  -- Pastikan baris User ada dan tertaut ke auth UID
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_auth_id::TEXT OR lower(u.email) = lower(trim(p_email))
  ORDER BY (u."firebaseUid" = v_auth_id::TEXT) DESC NULLS LAST
  LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, "firebaseUid", "isActive",
                        "createdAt", "updatedAt")
    VALUES (v_user_id, lower(trim(p_email)),
            split_part(lower(trim(p_email)), '@', 1),
            v_name, v_auth_id::TEXT, TRUE, now(), now());
  ELSE
    -- Pastikan firebaseUid & isActive benar
    UPDATE "User"
    SET "firebaseUid" = v_auth_id::TEXT,
        "isActive" = TRUE,
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = p_role_code;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
  ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;

  RETURN QUERY SELECT TRUE,
    format('Berhasil: %s sekarang punya peran %s (User.id = %s).',
           p_email, p_role_code, v_user_id);
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Buat profil Guru untuk sebuah email
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_guru_profile(
  p_email         TEXT,
  p_nip           TEXT DEFAULT NULL,
  p_specialization TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id TEXT;
  v_name    TEXT;
  v_guru_id TEXT;
BEGIN
  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email) INTO v_user_id, v_name
  FROM "User" u
  WHERE lower(u.email) = lower(trim(p_email));

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  SELECT g.id INTO v_guru_id FROM "Guru" g
  WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

  IF v_guru_id IS NOT NULL THEN
    RETURN QUERY SELECT TRUE,
      format('Guru sudah ada untuk %s (Guru.id = %s).', p_email, v_guru_id);
    RETURN;
  END IF;

  v_guru_id := gen_random_uuid()::TEXT;

  -- Catatan: tabel "Guru" TIDAK punya kolom gelar maupun isActive.
  -- Kolom yang tersedia: nip, nuptk, specialization, status, joinDate, dst.
  INSERT INTO "Guru" (id, "userId", name, nip, specialization, status,
                      "joinDate", "createdAt", "updatedAt")
  VALUES (v_guru_id, v_user_id, v_name, p_nip, p_specialization, 'AKTIF',
          CURRENT_DATE, now(), now());

  RETURN QUERY SELECT TRUE,
    format('Profil Guru dibuat untuk %s (Guru.id = %s).', p_email, v_guru_id);
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Buat profil Wali + tautkan ke santri
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_wali_profile(
  p_email       TEXT,
  p_nis_santri  TEXT DEFAULT NULL,
  p_relationship TEXT DEFAULT 'AYAH'
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id   TEXT;
  v_name      TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
BEGIN
  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email) INTO v_user_id, v_name
  FROM "User" u WHERE lower(u.email) = lower(trim(p_email));

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    -- Catatan: tabel "Wali" tidak punya kolom isActive. Statusnya memakai
    -- activationStatus (lihat enum WaliActivationStatus di Dart).
    INSERT INTO "Wali" (id, "userId", name, phone, "activationStatus",
                        "createdAt", "updatedAt")
    SELECT v_wali_id, v_user_id, v_name, u.phone, 'PENDING', now(), now()
    FROM "User" u WHERE u.id = v_user_id;
  END IF;

  IF p_nis_santri IS NULL THEN
    RETURN QUERY SELECT TRUE,
      format('Profil Wali siap (Wali.id = %s). Tautkan santri dengan NIS.', v_wali_id);
    RETURN;
  END IF;

  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = p_nis_santri AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Santri dengan NIS %s tidak ditemukan.', p_nis_santri);
    RETURN;
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", relationship, "isPrimary",
                            "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id,
          p_relationship, TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Wali %s tertaut ke santri NIS %s.', p_email, p_nis_santri);
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. Tautkan guru ke kelas melalui Jadwal
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_guru_to_kelas(
  p_email_guru TEXT,
  p_nama_kelas TEXT,
  p_nama_mapel TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guru_id  TEXT;
  v_kelas_id TEXT;
  v_mapel_id TEXT;
  v_ta_id    TEXT;
  v_sem_id   TEXT;
  v_ct       INT;
BEGIN
  SELECT g.id INTO v_guru_id
  FROM "Guru" g JOIN "User" u ON u.id = g."userId"
  WHERE lower(u.email) = lower(trim(p_email_guru)) AND g."deletedAt" IS NULL
  LIMIT 1;

  IF v_guru_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Guru untuk %s belum ada. Jalankan provision_guru_profile() dulu.', p_email_guru);
    RETURN;
  END IF;

  SELECT k.id INTO v_kelas_id FROM "Kelas" k
  WHERE lower(k.name) = lower(trim(p_nama_kelas)) AND k."deletedAt" IS NULL LIMIT 1;

  IF v_kelas_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Kelas "%s" tidak ditemukan.', p_nama_kelas);
    RETURN;
  END IF;

  IF p_nama_mapel IS NOT NULL THEN
    SELECT m.id INTO v_mapel_id FROM "MataPelajaran" m
    WHERE lower(m.name) = lower(trim(p_nama_mapel)) AND m."deletedAt" IS NULL LIMIT 1;
  END IF;

  SELECT count(*) INTO v_ct FROM "Jadwal" j
  WHERE j."guruId" = v_guru_id AND j."kelasId" = v_kelas_id
    AND (v_mapel_id IS NULL OR j."mapelId" = v_mapel_id);

  IF v_ct > 0 THEN
    RETURN QUERY SELECT TRUE, format('Guru sudah terjadwal di kelas "%s".', p_nama_kelas);
    RETURN;
  END IF;

  -- Ambil tahun ajaran & semester aktif (keduanya NOT NULL di "Jadwal").
  SELECT ta.id INTO v_ta_id FROM "TahunAjaran" ta
  WHERE ta."isActive" = TRUE AND ta."deletedAt" IS NULL LIMIT 1;
  IF v_ta_id IS NULL THEN
    SELECT ta.id INTO v_ta_id FROM "TahunAjaran" ta
    ORDER BY ta."createdAt" DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sem_id FROM "Semester" s
  WHERE s."tahunAjaranId" = v_ta_id AND s."isActive" = TRUE
  ORDER BY s."createdAt" DESC LIMIT 1;
  IF v_sem_id IS NULL THEN
    SELECT s.id INTO v_sem_id FROM "Semester" s
    WHERE s."tahunAjaranId" = v_ta_id ORDER BY s."createdAt" DESC LIMIT 1;
  END IF;

  IF v_ta_id IS NULL OR v_sem_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      'Belum ada TahunAjaran/Semester. Buat lewat aplikasi admin dulu '
      '(menu Tahun Ajaran) sebelum menjadwalkan guru.';
    RETURN;
  END IF;

  -- dayOfWeek bertipe INTEGER (1=Senin .. 7=Minggu), bukan nama hari.
  INSERT INTO "Jadwal" (id, "guruId", "kelasId", "mapelId", "tahunAjaranId",
                        "semesterId", "dayOfWeek", "startTime", "endTime",
                        "createdAt", "updatedAt")
  VALUES (gen_random_uuid()::TEXT, v_guru_id, v_kelas_id, v_mapel_id,
          v_ta_id, v_sem_id, 1, '07:00', '08:30', now(), now());

  RETURN QUERY SELECT TRUE,
    format('Guru %s ditautkan ke kelas "%s" (Jadwal dibuat).', p_email_guru, p_nama_kelas);
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. Audit seluruh akun
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.access_audit()
RETURNS TABLE(
  email        TEXT,
  user_id      TEXT,
  active       BOOLEAN,
  roles        TEXT,
  has_guru_row BOOLEAN,
  has_wali_row BOOLEAN,
  santri_count BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.email,
    u.id,
    COALESCE(u."isActive", FALSE),
    COALESCE((SELECT string_agg(r.code, ', ' ORDER BY r.code)
              FROM "UserRole" ur JOIN "Role" r ON r.id = ur."roleId"
              WHERE ur."userId" = u.id AND ur."isActive"), '— TANPA PERAN —'),
    EXISTS (SELECT 1 FROM "Guru" g WHERE g."userId" = u.id AND g."deletedAt" IS NULL),
    EXISTS (SELECT 1 FROM "Wali" w WHERE w."userId" = u.id AND w."deletedAt" IS NULL),
    (SELECT count(*) FROM "SantriWali" sw
     JOIN "Wali" w2 ON w2.id = sw."waliId"
     WHERE w2."userId" = u.id)
  FROM "User" u
  ORDER BY (u.email);
$$;

-- ----------------------------------------------------------------------------
-- Hak eksekusi: hanya service_role / postgres.
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.diagnose_account_access(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_account_role(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_guru_profile(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_wali_profile(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.assign_guru_to_kelas(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.access_audit() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- CARA PAKAI (jalankan di Supabase SQL Editor)
-- ============================================================================
--   -- 1) Lihat kondisi semua akun:
--   SELECT * FROM public.access_audit();
--
--   -- 2) Periksa satu akun secara detail:
--   SELECT * FROM public.diagnose_account_access('guru.anda@gmail.com');
--
--   -- 3) Beri peran:
--   SELECT * FROM public.provision_account_role('guru.anda@gmail.com', 'GURU');
--
--   -- 4) Buat profil guru (wajib agar data akademik muncul):
--   SELECT * FROM public.provision_guru_profile('guru.anda@gmail.com', '198701012010', 'Matematika');
--
--   -- 5) Tautkan ke kelas (wajib agar absensi/nilai bisa diisi):
--   SELECT * FROM public.assign_guru_to_kelas('guru.anda@gmail.com', 'Kelas 1');
--
--   -- Untuk wali:
--   SELECT * FROM public.provision_account_role('wali.anda@gmail.com', 'WALI');
--   SELECT * FROM public.provision_wali_profile('wali.anda@gmail.com', '2024001', 'AYAH');
-- ============================================================================
