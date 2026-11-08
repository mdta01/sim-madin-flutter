-- ============================================================================
-- SIM MADIN — Seed data demo terpusat (admin sebagai sumber data)
-- ============================================================================
-- TUJUAN
-- ----------------------------------------------------------------------------
-- Mengisi database dengan satu set data yang SALING TERKAIT sehingga setiap
-- layar di keempat aplikasi mobile menampilkan data nyata, bukan layar kosong.
--
-- Semua data di sini meniru alur produksi: admin mendaftarkan tahun ajaran,
-- kelas, mapel, guru, santri, dan wali. Aplikasi mobile hanya MEMBACA data
-- yang sudah didaftarkan admin.
--
-- ISI
-- ----------------------------------------------------------------------------
--   1. TahunAjaran + 2 Semester (Ganjil/Genap)   -> dibutuhkan Jadwal
--   2. 6 Kelas                                    -> dibutuhkan Santri/Jadwal
--   3. 6 MataPelajaran
--   4. 4 Guru  (Ustadz Ahmad, Siti, Ridwan, Nur)  -> mapel & jadwal
--   5. 2 Santri + 2 Wali  (sesuai permintaan: 2 saja)
--   6. Jadwal mingguan (Senin–Kamis) untuk tiap guru
--   7. Absensi 14 hari terakhir (untuk rekap kehadiran)
--   8. Nilai (UH, UTS) per santri per mapel
--   9. Materi + Tugas + Pertemuan (layar materi guru/wali)
--  10. JenisTagihan + Tagihan + Payment (layar keuangan)
--  11. Kas + TransaksiKas + HonorGuru (layar bendahara)
--  12. Announcement + Notifikasi (layar pengumuman & notifikasi wali)
--
-- SIFAT
-- ----------------------------------------------------------------------------
-- Idempotent: aman dijalankan berulang. Setiap langkah mencari data yang
-- sudah ada (berdasarkan code/nis/email) sebelum membuat baru, sehingga
-- tidak terjadi duplikasi.
--
-- CATATAN: fungsi ini hanya menyentuh data akademik & keuangan. Akun login
-- (User/UserRole/Guru/Wali) dibuat oleh fungsi terpisah di migrasi 29 agar
-- tanggung jawab tiap fungsi jelas.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.seed_demo_data()
RETURNS TABLE(step TEXT, ok BOOLEAN, detail TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_ta_id      TEXT;
  v_sem_ganjil TEXT;
  v_sem_genap  TEXT;

  v_kls        RECORD;
  v_kelas_ids  TEXT[];
  v_kelas_1a   TEXT;

  v_mapel_ids  TEXT[];
  v_mp         RECORD;

  v_guru       RECORD;
  v_guru_ids   TEXT[] := ARRAY[]::TEXT[];

  v_santri     RECORD;
  v_santri_ids TEXT[];
  v_santri_a   TEXT;
  v_santri_b   TEXT;

  v_kas_id     TEXT;
  v_jt_id      TEXT;
  v_tagihan_id TEXT;

  v_abs_count  INT;
  v_nilai_count INT;
  v_total      DOUBLE PRECISION;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 1. Tahun ajaran & semester
  -- ══════════════════════════════════════════════════════════════════════════
  SELECT id INTO v_ta_id FROM "TahunAjaran" WHERE code = '2025/2026' LIMIT 1;
  IF v_ta_id IS NULL THEN
    v_ta_id := gen_random_uuid()::TEXT;
    INSERT INTO "TahunAjaran" (id, code, name, "startDate", "endDate", "isActive",
                               "createdAt", "updatedAt")
    VALUES (v_ta_id, '2025/2026', 'Tahun Ajaran 2025/2026',
            '2025-07-01', '2026-06-30', TRUE, now(), now());
  END IF;

  SELECT id INTO v_sem_ganjil FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND code = 'GANJIL' LIMIT 1;
  IF v_sem_ganjil IS NULL THEN
    v_sem_ganjil := gen_random_uuid()::TEXT;
    INSERT INTO "Semester" (id, "tahunAjaranId", code, name, type,
                            "startDate", "endDate", "isActive",
                            "createdAt", "updatedAt")
    VALUES (v_sem_ganjil, v_ta_id, 'GANJIL', 'Semester Ganjil', 'GANJIL',
            '2025-07-01', '2025-12-31', TRUE, now(), now());
  END IF;

  SELECT id INTO v_sem_genap FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND code = 'GENAP' LIMIT 1;
  IF v_sem_genap IS NULL THEN
    v_sem_genap := gen_random_uuid()::TEXT;
    INSERT INTO "Semester" (id, "tahunAjaranId", code, name, type,
                            "startDate", "endDate", "isActive",
                            "createdAt", "updatedAt")
    VALUES (v_sem_genap, v_ta_id, 'GENAP', 'Semester Genap', 'GENAP',
            '2026-01-01', '2026-06-30', FALSE, now(), now());
  END IF;

  step := 'tahun_ajaran_semester';
  ok := TRUE;
  detail := 'Tahun ajaran 2025/2026 + semester Ganjil & Genap siap';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 2. Kelas
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_kls IN
    SELECT * FROM (VALUES
      ('KLS-1A', 'Kelas 1A', '1'::TEXT, 1),
      ('KLS-1B', 'Kelas 1B', '1', 2),
      ('KLS-2A', 'Kelas 2A', '2', 3),
      ('KLS-2B', 'Kelas 2B', '2', 4),
      ('KLS-3A', 'Kelas 3A', '3', 5),
      ('KLS-4A', 'Kelas 4A', '4', 6)
    ) AS t(code, name, level, sort_order)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM "Kelas" WHERE code = v_kls.code) THEN
      INSERT INTO "Kelas" (id, code, name, level, capacity, "sortOrder",
                           "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_kls.code, v_kls.name, v_kls.level,
              30, v_kls.sort_order, TRUE, now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY "sortOrder") INTO v_kelas_ids
  FROM "Kelas" WHERE "deletedAt" IS NULL;

  SELECT id INTO v_kelas_1a FROM "Kelas" WHERE code = 'KLS-1A' LIMIT 1;

  step := 'kelas';
  ok := TRUE;
  detail := COALESCE(array_length(v_kelas_ids, 1), 0) || ' kelas tersedia';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 3. Mata pelajaran
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_mp IN
    SELECT * FROM (VALUES
      ('MP-QURAN',   'Al-Qur''an',        'QURAN'::TEXT,   75.0, 1),
      ('MP-FIQIH',   'Fiqih',             'DINIYAH',       70.0, 2),
      ('MP-AKHLAK',  'Akhlak',            'DINIYAH',       70.0, 3),
      ('MP-BACA',    'Baca Tulis',        'UMUM',          65.0, 4),
      ('MP-HAFALAN', 'Hafalan Kitab',     'DINIYAH',       75.0, 5),
      ('MP-BAHASA',  'Bahasa Arab',       'UMUM',          70.0, 6)
    ) AS t(code, name, category, kkm, sort_order)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM "MataPelajaran" WHERE code = v_mp.code) THEN
      INSERT INTO "MataPelajaran" (id, code, name, category, kkm, "durationMnt",
                                   "sortOrder", "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_mp.code, v_mp.name, v_mp.category,
              v_mp.kkm, 90, v_mp.sort_order, TRUE, now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY "sortOrder") INTO v_mapel_ids
  FROM "MataPelajaran" WHERE "deletedAt" IS NULL;

  step := 'mata_pelajaran';
  ok := TRUE;
  detail := COALESCE(array_length(v_mapel_ids, 1), 0) || ' mapel tersedia';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 4. Jadwal per guru (dipakai is_guru_of_kelas)
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_guru IN
    SELECT g.id, g.name,
           row_number() OVER (ORDER BY g.name) AS rn
    FROM "Guru" g WHERE g."deletedAt" IS NULL
  LOOP
    v_guru_ids := v_guru_ids || v_guru.id;

    -- Tiap guru mengajar 2 kelas: kemungkinan besar kelas 1A selalu tercakup
    -- agar akun uji mana pun bisa mengisi absensi di kelas yang sama.
    DECLARE
      i INT := 0;
    BEGIN
      WHILE i < 2 LOOP
        IF NOT EXISTS (
          SELECT 1 FROM "Jadwal"
          WHERE "guruId" = v_guru.id
            AND "kelasId" = v_kelas_ids[((v_guru.rn::INT + i - 1) %
                          COALESCE(array_length(v_kelas_ids, 1), 1)) + 1]
            AND "dayOfWeek" = (1 + i)
        ) THEN
          INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                                "mapelId", "guruId", "dayOfWeek", "startTime",
                                "endTime", "createdAt", "updatedAt")
          VALUES (
            gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil,
            v_kelas_ids[((v_guru.rn::INT + i - 1) %
              COALESCE(array_length(v_kelas_ids, 1), 1)) + 1],
            v_mapel_ids[((v_guru.rn::INT + i - 1) %
              COALESCE(array_length(v_mapel_ids, 1), 1)) + 1],
            v_guru.id, 1 + i, '07:00', '08:30', now(), now()
          );
        END IF;
        i := i + 1;
      END LOOP;
    END;
  END LOOP;

  step := 'jadwal';
  ok := EXISTS (SELECT 1 FROM "Jadwal");
  detail := (SELECT count(*) FROM "Jadwal") || ' baris jadwal';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 5. Santri (2) + tautan wali
  -- ══════════════════════════════════════════════════════════════════════════
  FOR v_santri IN
    SELECT * FROM (VALUES
      ('2025001', 'Muhammad Fauzan',   'L'::TEXT, 'KLS-1A'),
      ('2025002', 'Aisyah Nur Fadhilah', 'P',    'KLS-1A')
    ) AS t(nis, name, gender, kelas_code)
  LOOP
    SELECT s.id INTO v_santri_a FROM "Santri" s
    WHERE s.nis = v_santri.nis AND s."deletedAt" IS NULL LIMIT 1;

    IF v_santri_a IS NULL THEN
      SELECT k.id INTO v_santri_b FROM "Kelas" k
      WHERE k.code = v_santri.kelas_code LIMIT 1;

      v_santri_a := gen_random_uuid()::TEXT;
      INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                            "tahunAjaranId", "entryDate", "birthPlace",
                            "createdAt", "updatedAt")
      VALUES (v_santri_a, v_santri.nis, v_santri.name, v_santri.gender,
              'AKTIF', COALESCE(v_santri_b, v_kelas_1a), v_ta_id,
              CURRENT_DATE, 'Malang', now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY nis) INTO v_santri_ids
  FROM "Santri" WHERE "deletedAt" IS NULL;
  SELECT id INTO v_santri_a FROM "Santri" WHERE nis = '2025001';
  SELECT id INTO v_santri_b FROM "Santri" WHERE nis = '2025002';

  -- Hubungkan 2 wali terdaftar ke 2 santri (1 wali = 1 anak, sesuai produksi)
  DECLARE
    w RECORD;
    idx INT := 0;
  BEGIN
    FOR w IN SELECT id FROM "Wali" WHERE "deletedAt" IS NULL ORDER BY "createdAt"
    LOOP
      EXIT WHEN idx >= 2;
      IF NOT EXISTS (SELECT 1 FROM "SantriWali"
                     WHERE "waliId" = w.id AND "santriId" = v_santri_ids[idx + 1]) THEN
        INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                                  relationship, "isPrimary", "createdAt")
        VALUES (gen_random_uuid()::TEXT, v_santri_ids[idx + 1], w.id, TRUE,
                'AYAH', TRUE, now());
      END IF;
      -- Santri.waliId juga diisi (beberapa query memakai kolom ini)
      UPDATE "Santri" SET "waliId" = w.id
      WHERE id = v_santri_ids[idx + 1] AND "waliId" IS DISTINCT FROM w.id;
      idx := idx + 1;
    END LOOP;
  END;

  step := 'santri_dan_wali';
  ok := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL) >= 2;
  detail := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL)
            || ' santri, '
            || (SELECT count(*) FROM "SantriWali") || ' tautan wali';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 6. Absensi 14 hari terakhir
  -- ══════════════════════════════════════════════════════════════════════════
  DECLARE
    d INT;
    s TEXT;
    v_status TEXT;
  BEGIN
    FOR d IN 0..13 LOOP
      FOREACH s IN ARRAY v_santri_ids LOOP
        -- Hari Jumat libur madrasah -> tidak ada absensi.
        IF EXTRACT(DOW FROM (CURRENT_DATE - d))::INT = 5 THEN
          CONTINUE;
        END IF;

        -- Variasi status agar rekap kehadiran tidak 100% HADIR semua.
        v_status := CASE WHEN (d % 7) = 3 THEN 'SAKIT'
                         WHEN (d % 11) = 5 THEN 'IZIN'
                         WHEN (d % 13) = 6 THEN 'ALPA'
                         ELSE 'HADIR' END;

        IF NOT EXISTS (
          SELECT 1 FROM "Absensi"
          WHERE "santriId" = s AND date::date = (CURRENT_DATE - d)::date
        ) THEN
          INSERT INTO "Absensi" (id, "tahunAjaranId", "santriId", "kelasId",
                                 date, status, "recordedByGuruId",
                                 "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, s, st."kelasId",
                 (CURRENT_DATE - d), v_status,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" LIMIT 1),
                 now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;
      END LOOP;
    END LOOP;
  END;

  SELECT count(*) INTO v_abs_count FROM "Absensi";
  step := 'absensi';
  ok := v_abs_count > 0;
  detail := v_abs_count || ' catatan absensi (14 hari terakhir)';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 7. Nilai per santri per mapel
  -- ══════════════════════════════════════════════════════════════════════════
  DECLARE
    s TEXT;
    m TEXT;
    base DOUBLE PRECISION;
    n INT := 0;
  BEGIN
    FOREACH s IN ARRAY v_santri_ids LOOP
      n := n + 1;
      FOREACH m IN ARRAY v_mapel_ids LOOP
        base := 78 + (n * 3) + (length(m) % 5);

        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = s AND "mapelId" = m
                         AND "tahunAjaranId" = v_ta_id) THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, s,
                 st."kelasId", m,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" AND j."mapelId" = m LIMIT 1),
                 'UH', LEAST(100, base), CURRENT_DATE - 7, now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = s AND "mapelId" = m
                         AND "tahunAjaranId" = v_ta_id AND type = 'UTS') THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, s,
                 st."kelasId", m,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" AND j."mapelId" = m LIMIT 1),
                 'UTS', LEAST(100, base + 2), CURRENT_DATE - 3, now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;
      END LOOP;
    END LOOP;
  END;

  SELECT count(*) INTO v_nilai_count FROM "Nilai";
  step := 'nilai';
  ok := v_nilai_count > 0;
  detail := v_nilai_count || ' nilai (UH + UTS)';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 8. Materi, Tugas, Pertemuan
  -- ══════════════════════════════════════════════════════════════════════════
  DECLARE
    g RECORD;
    m_id TEXT;
  BEGIN
    FOR g IN
      SELECT DISTINCT j."guruId", j."kelasId", j."mapelId"
      FROM "Jadwal" j
    LOOP
      IF NOT EXISTS (SELECT 1 FROM "Materi"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        m_id := gen_random_uuid()::TEXT;
        INSERT INTO "Materi" (id, "tahunAjaranId", "semesterId", "mapelId",
                              "kelasId", "guruId", title, description, type,
                              pertemuan, "sortOrder", "isPublished",
                              "publishedAt", "createdAt", "updatedAt")
        VALUES (m_id, v_ta_id, v_sem_ganjil, g."mapelId", g."kelasId",
                g."guruId", 'Materi Pengantar', 'Ringkasan materi pertemuan 1',
                'TEKS', 1, 1, TRUE, now(), now(), now());
      END IF;

      IF NOT EXISTS (SELECT 1 FROM "Tugas"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        INSERT INTO "Tugas" (id, "tahunAjaranId", "semesterId", "mapelId",
                             "kelasId", "guruId", title, description, type,
                             "maxScore", "dueDate", "isPublished",
                             "publishedAt", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g."mapelId",
                g."kelasId", g."guruId", 'Latihan Pertemuan 1',
                'Kerjakan latihan pada buku halaman 10', 'TUGAS',
                100, CURRENT_DATE + 7, TRUE, now(), now(), now());
      END IF;

      IF NOT EXISTS (SELECT 1 FROM "Pertemuan"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        INSERT INTO "Pertemuan" (id, "tahunAjaranId", "semesterId", "kelasId",
                                 "mapelId", "guruId", "pertemuanKe", date,
                                 topic, description, "isCompleted",
                                 "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g."kelasId",
                g."mapelId", g."guruId", 1, CURRENT_DATE, 'Pengenalan materi',
                'Pertemuan perdana', TRUE, now(), now());
      END IF;
    END LOOP;
  END;

  step := 'materi_tugas_pertemuan';
  ok := (SELECT count(*) FROM "Materi") > 0;
  detail := (SELECT count(*) FROM "Materi") || ' materi, '
            || (SELECT count(*) FROM "Tugas") || ' tugas, '
            || (SELECT count(*) FROM "Pertemuan") || ' pertemuan';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 9. JenisTagihan + Tagihan + Payment
  -- ══════════════════════════════════════════════════════════════════════════
  SELECT id INTO v_jt_id FROM "JenisTagihan" WHERE code = 'SPP' LIMIT 1;
  IF v_jt_id IS NULL THEN
    v_jt_id := gen_random_uuid()::TEXT;
    INSERT INTO "JenisTagihan" (id, code, name, description, "defaultAmount",
                                category, "isActive", "createdAt", "updatedAt")
    VALUES (v_jt_id, 'SPP', 'SPP Bulanan', 'Syahriah bulanan santri',
            150000, 'BULANAN', TRUE, now(), now());

    INSERT INTO "JenisTagihan" (id, code, name, description, "defaultAmount",
                                category, "isActive", "createdAt", "updatedAt")
    VALUES (gen_random_uuid()::TEXT, 'UANG-PANGKAL', 'Uang Pangkal',
            'Biaya masuk awal tahun', 500000, 'SEKALI', TRUE, now(), now());
  END IF;

  DECLARE
    s TEXT;
    sisa DOUBLE PRECISION;
  BEGIN
    FOREACH s IN ARRAY v_santri_ids LOOP
      IF NOT EXISTS (SELECT 1 FROM "Tagihan"
                     WHERE "santriId" = s AND "jenisTagihanId" = v_jt_id
                       AND "tahunAjaranId" = v_ta_id) THEN
        v_tagihan_id := gen_random_uuid()::TEXT;
        INSERT INTO "Tagihan" (id, "tahunAjaranId", "santriId", "kelasId",
                               "jenisTagihanId", amount, "paidAmount",
                               description, "dueDate", status,
                               "createdAt", "updatedAt")
        SELECT v_tagihan_id, v_ta_id, s, st."kelasId", v_jt_id, 150000, 0,
               'SPP bulan ini', CURRENT_DATE + 10, 'BELUM_BAYAR', now(), now()
        FROM "Santri" st WHERE st.id = s;

        -- Santri pertama: lunas. Santri kedua: sebagian, agar ada 2 status.
        IF s = v_santri_a THEN
          sisa := 150000;
          UPDATE "Tagihan" SET "paidAmount" = 150000, status = 'LUNAS',
                 "updatedAt" = now() WHERE id = v_tagihan_id;

          INSERT INTO "Payment" (id, "invoiceNo", "tahunAjaranId", "tagihanId",
                                 "santriId", amount, "paymentMethod",
                                 "paymentDate", status, note, "createdAt",
                                 "updatedAt")
          VALUES (gen_random_uuid()::TEXT, 'INV-DEMO-001', v_ta_id,
                  v_tagihan_id, s, 150000, 'TUNAI', now() - INTERVAL '2 days',
                  'VERIFIED', 'Pembayaran lunas (demo)', now(), now());
        ELSE
          sisa := 100000;
          UPDATE "Tagihan" SET "paidAmount" = 50000, status = 'SEBAGIAN',
                 "updatedAt" = now() WHERE id = v_tagihan_id;

          INSERT INTO "Payment" (id, "invoiceNo", "tahunAjaranId", "tagihanId",
                                 "santriId", amount, "paymentMethod",
                                 "paymentDate", status, note, "createdAt",
                                 "updatedAt")
          VALUES (gen_random_uuid()::TEXT, 'INV-DEMO-002', v_ta_id,
                  v_tagihan_id, s, 50000, 'TRANSFER', now() - INTERVAL '1 day',
                  'VERIFIED', 'Cicilan pertama (demo)', now(), now());
        END IF;
      END IF;
    END LOOP;
  END;

  step := 'tagihan_dan_pembayaran';
  ok := (SELECT count(*) FROM "Tagihan") > 0;
  detail := (SELECT count(*) FROM "Tagihan") || ' tagihan, '
            || (SELECT count(*) FROM "Payment") || ' pembayaran';
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 10. Kas + TransaksiKas + HonorGuru
  -- ══════════════════════════════════════════════════════════════════════════
  SELECT id INTO v_kas_id FROM "Kas" WHERE code = 'KAS-UTAMA' LIMIT 1;
  IF v_kas_id IS NULL THEN
    v_kas_id := gen_random_uuid()::TEXT;
    INSERT INTO "Kas" (id, code, name, "accountNumber", "bankName", type,
                       balance, "isActive", "createdAt", "updatedAt")
    VALUES (v_kas_id, 'KAS-UTAMA', 'Kas Utama Madrasah', '1234567890',
            'BSI', 'TUNAI', 0, TRUE, now(), now());
  END IF;

  -- Saldo = total pembayaran terverifikasi - total honor terbayar
  SELECT COALESCE(sum(amount), 0) INTO v_total
  FROM "Payment" WHERE status = 'VERIFIED';

  UPDATE "Kas" SET balance = v_total, "updatedAt" = now() WHERE id = v_kas_id;

  IF NOT EXISTS (SELECT 1 FROM "TransaksiKas" WHERE "kasId" = v_kas_id) THEN
    INSERT INTO "TransaksiKas" (id, "kasId", "tahunAjaranId", type, category,
                                amount, description, "transaksiDate",
                                "createdAt", "updatedAt")
    VALUES (gen_random_uuid()::TEXT, v_kas_id, v_ta_id, 'MASUK', 'SPP',
            v_total, 'Penerimaan SPP (demo)', CURRENT_DATE, now(), now());
  END IF;

  DECLARE
    g2 RECORD;
  BEGIN
    FOR g2 IN SELECT id, name FROM "Guru" WHERE "deletedAt" IS NULL LOOP
      IF NOT EXISTS (SELECT 1 FROM "HonorGuru"
                     WHERE "guruId" = g2.id AND periode = to_char(CURRENT_DATE, 'YYYY-MM')) THEN
        INSERT INTO "HonorGuru" (id, "tahunAjaranId", "semesterId", "guruId",
                                 periode, "periodeLabel", "honorMengajar",
                                 insentif, tunjangan, potongan, "totalHonor",
                                 status, "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g2.id,
                to_char(CURRENT_DATE, 'YYYY-MM'),
                'Bulan ' || to_char(CURRENT_DATE, 'MM/YYYY'),
                750000, 100000, 50000, 0, 900000, 'BELUM_DIBAYAR', now(), now());
      END IF;
    END LOOP;
  END;

  step := 'kas_dan_honor';
  ok := (SELECT count(*) FROM "Kas") > 0;
  detail := (SELECT count(*) FROM "TransaksiKas") || ' transaksi kas, '
            || (SELECT count(*) FROM "HonorGuru") || ' honor guru, saldo '
            || to_char(v_total, 'FM999G999G999');
  RETURN NEXT;

  -- ══════════════════════════════════════════════════════════════════════════
  -- 11. Pengumuman + Notifikasi wali
  -- ══════════════════════════════════════════════════════════════════════════
  IF NOT EXISTS (SELECT 1 FROM "Announcement" WHERE title = 'Selamat Datang di SIM MADIN') THEN
    INSERT INTO "Announcement" (id, title, content, audience, priority,
                                "isPublished", "publishedAt", "createdAt",
                                "updatedAt")
    VALUES (gen_random_uuid()::TEXT, 'Selamat Datang di SIM MADIN',
            'Aplikasi SIM Madrasah Diniyah Miftahul Ulum kini aktif. '
            'Silakan gunakan untuk memantau absensi, nilai, dan tagihan putra-putri Anda.',
            'ALL', 'NORMAL', TRUE, now(), now(), now());
  END IF;

  DECLARE
    w RECORD;
  BEGIN
    FOR w IN SELECT id FROM "Wali" WHERE "deletedAt" IS NULL LOOP
      IF NOT EXISTS (SELECT 1 FROM "Notifikasi" WHERE "waliId" = w.id) THEN
        INSERT INTO "Notifikasi" (id, "waliId", type, title, message, priority,
                                  "isRead", "isEmailSent", "isPushSent", "createdAt")
        VALUES (gen_random_uuid()::TEXT, w.id, 'ANNOUNCEMENT',
                'Selamat Datang di SIM MADIN',
                'Anda dapat memantau absensi, nilai, dan tagihan ananda di aplikasi ini.',
                'NORMAL', FALSE, FALSE, FALSE, now());
      END IF;
    END LOOP;
  END;

  step := 'pengumuman_dan_notifikasi';
  ok := TRUE;
  detail := (SELECT count(*) FROM "Announcement") || ' pengumuman, '
            || (SELECT count(*) FROM "Notifikasi") || ' notifikasi';
  RETURN NEXT;

  RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.seed_demo_data() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- CARA PAKAI
-- ============================================================================
--   SELECT * FROM public.seed_demo_data();
-- ============================================================================
