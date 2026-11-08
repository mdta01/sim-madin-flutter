-- ============================================================================
-- SIM MADIN — Sinkronisasi data demo lengkap (satu perintah)
-- ============================================================================
-- MENGAPA ADA FUNGSI INI
-- ----------------------------------------------------------------------------
-- Setup data demo sebelumnya harus dijalankan manual satu per satu dan mudah
-- terlewat. Fungsi ini menjalankan seluruh rantai dalam urutan yang benar:
--
--   akun staf -> profil guru -> data akademik -> wali + santri -> tautan
--
-- sehingga aplikasi mobile langsung berisi data nyata.
--
-- AKUN YANG DIHASILKAN
-- ----------------------------------------------------------------------------
--   mdta@madrasah.com        / admin@mdta01    SUPER_ADMIN + ADMIN
--   kepala@madrasah.com      / kepala123       KEPALA
--   bendahara@madrasah.com   / bendahara123    BENDAHARA
--   guru@madrasah.com        / guru123         GURU  (Ustadz Ahmad Fauzi)
--   guru2@madrasah.com       / guru123         GURU  (Ustadzah Siti Aminah)
--
--   WALI (login nomor WhatsApp + PIN):
--     Bapak Abdullah     081234567801  PIN 123456  -> Muhammad Fauzan  (2025001)
--     Bapak Hasan        081234567802  PIN 123456  -> Aisyah Nur Fadhilah (2025002)
--
-- ⚠ GANTI SEMUA PASSWORD/PIN SEBELUM PRODUKSI.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.seed_all_demo()
RETURNS TABLE(step TEXT, ok BOOLEAN, detail TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_negara RECORD;
  v_ta_id   TEXT;
  v_sem_id  TEXT;
  v_kelas_a TEXT;
  v_kelas_b TEXT;
  v_mapel   TEXT;
  v_guru_id TEXT;
  v_santri  TEXT;
  v_wali_id TEXT;
BEGIN
  -- ══════════════════════════════════════════════════════════════════════════
  -- 1. Akun staf sesuai bidang
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_negara IN
    SELECT * FROM (VALUES
      ('mdta@madrasah.com',      'admin@mdta01', 'Administrator Madrasah',
       ARRAY['SUPER_ADMIN','ADMIN']::TEXT[], '081200000000'::TEXT, NULL::TEXT),
      ('kepala@madrasah.com',    'kepala123',    'H. Abdul Ghofur',
       ARRAY['KEPALA']::TEXT[],    '081200000001', NULL),
      ('bendahara@madrasah.com', 'bendahara123', 'Hj. Sri Wahyuni',
       ARRAY['BENDAHARA']::TEXT[], '081200000002', NULL),
      ('guru@madrasah.com',      'guru123',      'Ustadz Ahmad Fauzi',
       ARRAY['GURU']::TEXT[],      '081200000003', 'Al-Qur''an'),
      ('guru2@madrasah.com',     'guru123',      'Ustadzah Siti Aminah',
       ARRAY['GURU']::TEXT[],      '081200000004', 'Fiqih')
    ) AS t(email, pass, nama, roles, phone, spesialisasi)
  LOOP
    PERFORM public.admin_create_staff_account(
      v_negara.email, v_negara.pass, v_negara.nama, v_negara.roles,
      v_negara.phone, NULL, NULL, v_negara.spesialisasi);
  END LOOP;

  step := 'akun_staf';
  ok := (SELECT count(*) FROM "UserRole" ur
         JOIN "Role" r ON r.id = ur."roleId"
         WHERE r.code IN ('SUPER_ADMIN','KEPALA','BENDAHARA','GURU')
           AND ur."isActive") >= 5;
  detail := 'Admin, kepala, bendahara, 2 guru';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 2. Data akademik dasar (tahun ajaran, kelas, mapel)
  -- ══════════════════════════════════════════════════════════════════════════
  PERFORM public.seed_demo_data();

  SELECT id INTO v_ta_id FROM "TahunAjaran" WHERE "isActive" LIMIT 1;
  SELECT id INTO v_sem_id FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND "isActive" LIMIT 1;
  SELECT id INTO v_kelas_a FROM "Kelas" WHERE code = 'KLS-1A';
  SELECT id INTO v_kelas_b FROM "Kelas" WHERE code = 'KLS-1B';
  SELECT id INTO v_mapel FROM "MataPelajaran" WHERE code = 'MP-QURAN';

  step := 'data_akademik';
  ok := v_ta_id IS NOT NULL AND v_kelas_a IS NOT NULL AND v_mapel IS NOT NULL;
  detail := 'Tahun ajaran, 6 kelas, 6 mapel';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 3. Tautkan setiap guru ke kelas & mapel (jadwal)
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_negara IN
    SELECT g.id, g.name, u.email
    FROM "Guru" g JOIN "User" u ON u.id = g."userId"
    WHERE g."deletedAt" IS NULL AND u."deletedAt" IS NULL
  LOOP
    v_guru_id := v_negara.id;

    -- Senin: kelas 1A, mapel Al-Qur'an
    IF v_kelas_a IS NOT NULL AND v_mapel IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM "Jadwal"
                     WHERE "guruId" = v_guru_id AND "kelasId" = v_kelas_a
                       AND "dayOfWeek" = 1) THEN
        INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                              "mapelId", "guruId", "dayOfWeek", "startTime",
                              "endTime", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_kelas_a,
                v_mapel, v_guru_id, 1, '07:00', '08:30', now(), now());
      END IF;
    END IF;

    -- Selasa: kelas 1B, mapel Fiqih
    IF v_kelas_b IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM "Jadwal"
                     WHERE "guruId" = v_guru_id AND "kelasId" = v_kelas_b
                       AND "dayOfWeek" = 2) THEN
        INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                              "mapelId", "guruId", "dayOfWeek", "startTime",
                              "endTime", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_kelas_b,
                (SELECT id FROM "MataPelajaran" WHERE code = 'MP-FIQIH'),
                v_guru_id, 2, '08:30', '10:00', now(), now());
      END IF;
    END IF;
  END LOOP;

  step := 'jadwal_guru';
  ok := (SELECT count(*) FROM "Jadwal") > 0;
  detail := (SELECT count(*) FROM "Jadwal") || ' jadwal';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 4. Wali + Santri (2 pasang, sesuai permintaan)
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_negara IN
    SELECT * FROM (VALUES
      ('Bapak Abdullah', '081234567801', '2025001', 'Muhammad Fauzan',      'L'::TEXT, 'KLS-1A'),
      ('Bapak Hasan',    '081234567802', '2025002', 'Aisyah Nur Fadhilah',  'P',       'KLS-1A')
    ) AS t(nama_wali, phone, nis, nama_santri, gender, kelas)
  LOOP
    -- User untuk wali (bukan untuk login email, tapi agar RLS & relasi rapi)
    DECLARE
      v_email TEXT := 'wali' || right(v_negara.phone, 3) || '@madrasah.com';
      v_uid   UUID;
      v_user  TEXT;
      v_role  TEXT;
    BEGIN
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
          v_email, crypt(encode(gen_random_bytes(12), 'hex'), gen_salt('bf', 10)),
          now(), now(), now(),
          jsonb_build_object('provider','email','providers',jsonb_build_array('email')),
          jsonb_build_object('name', v_negara.nama_wali, 'role','WALI'),
          '', '', '', ''
        );
        INSERT INTO auth.identities (
          id, user_id, provider_id, provider, identity_data,
          last_sign_in_at, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
          jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                             'email_verified', TRUE, 'phone_verified', FALSE),
          now(), now(), now()
        ) ON CONFLICT DO NOTHING;
      END IF;

      SELECT u.id INTO v_user FROM "User" u
      WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email LIMIT 1;

      IF v_user IS NULL THEN
        v_user := gen_random_uuid()::TEXT;
        INSERT INTO "User" (id, email, username, name, phone, "firebaseUid",
                            "isActive", "createdAt", "updatedAt")
        VALUES (v_user, v_email, 'wali' || right(v_negara.phone, 3),
                v_negara.nama_wali, v_negara.phone, v_uid::TEXT, TRUE, now(), now());
      END IF;

      SELECT r.id INTO v_role FROM "Role" r WHERE r.code = 'WALI';
      INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
      VALUES (gen_random_uuid()::TEXT, v_user, v_role, TRUE, now())
      ON CONFLICT ("userId","roleId") DO UPDATE SET "isActive" = TRUE;

      -- Baris Wali siap login (ACTIVE + PIN bcrypt + authPassword)
      SELECT w.id INTO v_wali_id FROM "Wali" w
      WHERE w."userId" = v_user AND w."deletedAt" IS NULL LIMIT 1;

      IF v_wali_id IS NULL THEN
        v_wali_id := gen_random_uuid()::TEXT;
        INSERT INTO "Wali" (id, "userId", name, phone, email, "activationStatus",
                            "pinHash", "authPassword", "createdAt", "updatedAt")
        VALUES (v_wali_id, v_user, v_negara.nama_wali, v_negara.phone, v_email,
                'ACTIVE', crypt('123456', gen_salt('bf', 10)),
                substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                         '[^a-zA-Z0-9]', '', 'g'), 1, 16),
                now(), now());
      ELSE
        UPDATE "Wali"
        SET phone = v_negara.phone, "activationStatus" = 'ACTIVE',
            "pinHash" = crypt('123456', gen_salt('bf', 10)),
            "failedLoginAttempts" = 0, "lockedUntil" = NULL, "updatedAt" = now()
        WHERE id = v_wali_id;
      END IF;

      -- Santri
      SELECT s.id INTO v_santri FROM "Santri" s
      WHERE s.nis = v_negara.nis AND s."deletedAt" IS NULL LIMIT 1;

      IF v_santri IS NULL THEN
        v_santri := gen_random_uuid()::TEXT;
        INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                              "tahunAjaranId", "waliId", "entryDate",
                              "birthPlace", "createdAt", "updatedAt")
        VALUES (v_santri, v_negara.nis, v_negara.nama_santri, v_negara.gender,
                'AKTIF', (SELECT id FROM "Kelas" WHERE code = v_negara.kelas),
                v_ta_id, v_wali_id, CURRENT_DATE, 'Malang', now(), now());
      ELSE
        UPDATE "Santri" SET "waliId" = v_wali_id,
               "kelasId" = COALESCE("kelasId", (SELECT id FROM "Kelas" WHERE code = v_negara.kelas)),
               "updatedAt" = now()
        WHERE id = v_santri;
      END IF;

      INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                                relationship, "isPrimary", "createdAt")
      VALUES (gen_random_uuid()::TEXT, v_santri, v_wali_id, TRUE,
              'AYAH', TRUE, now())
      ON CONFLICT DO NOTHING;
    END;
  END LOOP;

  step := 'wali_dan_santri';
  ok := (SELECT count(*) FROM "Wali" WHERE "activationStatus" = 'ACTIVE') >= 2;
  detail := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL)
            || ' santri, '
            || (SELECT count(*) FROM "SantriWali") || ' tautan wali';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 5. Pastikan wali punya data akademik & keuangan yang bisa dilihat
  -- ══════════════════════════════════════════════════════════════════════════
  -- Dilakukan SEBELUM seed_demo_data kedua kali tidak perlu: data akademik
  -- sudah dibuat di langkah 2 (tanpa santri). Di sini kita lengkapi absensi,
  -- nilai, dan tagihan untuk santri yang baru dibuat.
  FOR v_negara IN
    SELECT s.id, s."kelasId", s.name
    FROM "Santri" s WHERE s."deletedAt" IS NULL
  LOOP
    -- Absensi 14 hari terakhir (kecuali Jumat)
    DECLARE
      d INT;
      v_status TEXT;
    BEGIN
      FOR d IN 0..13 LOOP
        CONTINUE WHEN EXTRACT(DOW FROM (CURRENT_DATE - d))::INT = 5;
        IF NOT EXISTS (SELECT 1 FROM "Absensi"
                       WHERE "santriId" = v_negara.id
                         AND date::date = (CURRENT_DATE - d)::date) THEN
          v_status := CASE WHEN (d % 7) = 3 THEN 'SAKIT'
                           WHEN (d % 11) = 5 THEN 'IZIN'
                           ELSE 'HADIR' END;
          INSERT INTO "Absensi" (id, "tahunAjaranId", "santriId", "kelasId",
                                 date, status, "recordedByGuruId",
                                 "createdAt", "updatedAt")
          VALUES (gen_random_uuid()::TEXT, v_ta_id, v_negara.id,
                  v_negara."kelasId", (CURRENT_DATE - d), v_status,
                  (SELECT "guruId" FROM "Jadwal"
                   WHERE "kelasId" = v_negara."kelasId" LIMIT 1),
                  now(), now());
        END IF;
      END LOOP;
    END;

    -- Nilai per mapel
    DECLARE
      mp RECORD;
      n INT := 0;
    BEGIN
      FOR mp IN SELECT id FROM "MataPelajaran" WHERE "deletedAt" IS NULL LOOP
        n := n + 1;
        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = v_negara.id AND "mapelId" = mp.id
                         AND type = 'UH') THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_negara.id,
                  v_negara."kelasId", mp.id,
                  (SELECT "guruId" FROM "Jadwal"
                   WHERE "kelasId" = v_negara."kelasId" LIMIT 1),
                  'UH', 78 + (n % 15), CURRENT_DATE - 7, now(), now());
        END IF;
      END LOOP;
    END;

    -- Tagihan SPP
    DECLARE
      jt TEXT;
    BEGIN
      SELECT id INTO jt FROM "JenisTagihan" WHERE code = 'SPP' LIMIT 1;
      IF jt IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Tagihan" WHERE "santriId" = v_negara.id
          AND "jenisTagihanId" = jt AND "tahunAjaranId" = v_ta_id
      ) THEN
        INSERT INTO "Tagihan" (id, "tahunAjaranId", "santriId", "kelasId",
                               "jenisTagihanId", amount, "paidAmount",
                               description, "dueDate", status,
                               "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_negara.id,
                v_negara."kelasId", jt, 150000, 0, 'SPP bulan ini',
                CURRENT_DATE + 10, 'BELUM_BAYAR', now(), now());
      END IF;
    END;
  END LOOP;

  step := 'data_wali';
  ok := (SELECT count(*) FROM "Absensi") > 0 AND (SELECT count(*) FROM "Nilai") > 0;
  detail := (SELECT count(*) FROM "Absensi") || ' absensi, '
            || (SELECT count(*) FROM "Nilai") || ' nilai, '
            || (SELECT count(*) FROM "Tagihan") || ' tagihan';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 6. Ringkasan
  -- ══════════════════════════════════════════════════════════════════════════
  step := 'selesai';
  ok := TRUE;
  detail := 'Admin mdta@madrasah.com siap. Wali: 081234567801 / 081234567802 (PIN 123456).';
  RETURN NEXT;

  RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.seed_all_demo() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- CARA PAKAI
-- ============================================================================
--   SELECT * FROM public.seed_all_demo();
--
-- Lalu cek hasilnya:
--   SELECT * FROM public.access_audit();
--
-- Login aplikasi:
--   Admin desktop : mdta@madrasah.com / admin@mdta01
--   Kepala        : kepala@madrasah.com / kepala123
--   Bendahara     : bendahara@madrasah.com / bendahara123
--   Guru          : guru@madrasah.com / guru123
--   Wali (mobile) : 081234567801 / PIN 123456
--                   081234567802 / PIN 123456
-- ============================================================================
