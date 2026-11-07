-- ============================================================================
-- SIM MADIN — Seed Data untuk Testing (Ujian, BankSoal, Tugas, Surat, Alumni)
-- ============================================================================
-- Setelah audit, ditemukan tabel-tabel berikut KOSONG:
--   - Ujian (0 rows)        — wali tidak bisa test fitur Ujian Take
--   - BankSoal (0 rows)     — guru tidak bisa create soal
--   - UjianSoal (0 rows)    — ujian tidak punya soal
--   - UjianPeserta (0 rows) — ujian tidak punya peserta
--   - UjianSesi (0 rows)    — belum ada sesi dimulai
--   - UjianJawaban (0 rows) — belum ada jawaban
--   - UjianNilai (0 rows)   — belum ada nilai
--   - Tugas (0 rows)        — guru belum create tugas
--   - Pertemuan (0 rows)    — guru belum create pertemuan
--   - Surat (0 rows)        — admin belum create surat
--   - Alumni (0 rows)       — belum ada alumni
--
-- Migration ini seed data sample untuk testing end-to-end.
-- Pakai data existing (guru, santri, kelas, mapel, jadwal) — ambil ID pertama.
-- ============================================================================

DO $$
DECLARE
  v_guru_id TEXT;
  v_santri_id TEXT;
  v_santri2_id TEXT;
  v_santri3_id TEXT;
  v_kelas_id TEXT;
  v_mapel_id TEXT;
  v_mapel2_id TEXT;
  v_ta_id TEXT;
  v_sem_id TEXT;
  v_ujian_id TEXT;
  v_ujian_id2 TEXT;
  v_soal_id TEXT;
  v_soal_id2 TEXT;
  v_soal_id3 TEXT;
  v_soal_id4 TEXT;
  v_bank_soal_id TEXT;
  v_bank_soal_id2 TEXT;
  v_tugas_id TEXT;
  v_pertemuan_id TEXT;
  v_surat_id TEXT;
  v_alumni_id TEXT;
BEGIN
  -- Get IDs from existing data
  SELECT id INTO v_guru_id FROM "Guru" WHERE "deletedAt" IS NULL LIMIT 1;
  SELECT id INTO v_santri_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" LIMIT 1;
  SELECT id INTO v_santri2_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" OFFSET 1 LIMIT 1;
  SELECT id INTO v_santri3_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" OFFSET 2 LIMIT 1;
  SELECT id INTO v_kelas_id FROM "Kelas" LIMIT 1;
  SELECT id INTO v_mapel_id FROM "MataPelajaran" LIMIT 1;
  SELECT id INTO v_mapel2_id FROM "MataPelajaran" OFFSET 1 LIMIT 1;
  SELECT id INTO v_ta_id FROM "TahunAjaran" LIMIT 1;
  SELECT id INTO v_sem_id FROM "Semester" LIMIT 1;

  RAISE NOTICE 'Guru ID: %', v_guru_id;
  RAISE NOTICE 'Santri ID: %', v_santri_id;
  RAISE NOTICE 'Kelas ID: %', v_kelas_id;
  RAISE NOTICE 'Mapel ID: %', v_mapel_id;

  -- ============================================================================
  -- 1. Seed BankSoal (5 soal: 3 PG + 2 essay)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "BankSoal" LIMIT 1) THEN
    INSERT INTO "BankSoal" ("mapelId", "tahunAjaranId", "guruId", "code", "type", "question", "options", "correctAnswer", "answerKey", "bobot", "difficulty")
    VALUES
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-001', 'PG', 'Hukum bacaan nun mati/tanwin ketemu huruf ba disebut?',
        '["Ikhfa","Idgham","Iqlab","Ikhfa Syafawi"]'::jsonb, 'Iqlab', NULL, 1.0, 'EASY'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-002', 'PG', 'Hukum bacaan nun mati/tanwin ketemu huruf ta disebut?',
        '["Ikhfa","Idgham","Iqlab","Ikhfa Syafawi"]'::jsonb, 'Ikhfa', NULL, 1.0, 'EASY'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-003', 'ESSAY', 'Jelaskan pengertian tajwid dan tujuannya!',
        NULL, NULL, 'Tajwid adalah ilmu yang mempelajari kaidah membaca Al-Quran dengan baik dan benar. Tujuannya untuk menjaga kesempurnaan bacaan dan menjaga dari kesalahan.', 2.0, 'MEDIUM'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-004', 'PG', 'Berapa jumlah huruf hijaiyah?',
        '["26","28","29","30"]'::jsonb, '28', NULL, 1.0, 'EASY'),
      (v_mapel2_id, v_ta_id, v_guru_id, 'BS-005', 'ESSAY', 'Sebutkan rukun iman yang enam!',
        NULL, NULL, 'Iman kepada Allah, Malaikat, Kitab, Rasul, Hari Kiamat, Qada dan Qadar', 2.0, 'MEDIUM');
    RAISE NOTICE 'Created 5 BankSoal records';
  END IF;
  SELECT id INTO v_bank_soal_id FROM "BankSoal" ORDER BY "createdAt" LIMIT 1;
  SELECT id INTO v_bank_soal_id2 FROM "BankSoal" ORDER BY "createdAt" OFFSET 1 LIMIT 1;

  -- ============================================================================
  -- 2. Seed Ujian (2 ujian: 1 published untuk wali take, 1 draft)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "Ujian" LIMIT 1) THEN
    INSERT INTO "Ujian" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "type", "description", "startTime", "endTime", "durationMnt", "ruang", "pengawas", "isPublished", "maxScore", "passingScore")
    VALUES
      (v_ta_id, v_sem_id, v_mapel_id, v_kelas_id, v_guru_id,
       'Ujian Tengah Semester Tajwid',
       'UTS',
       'Ujian tengah semester untuk mapel Tajwid. Materi: Hukum Nun Mati & Tanwin.',
       NOW() - INTERVAL '1 day',
       NOW() + INTERVAL '7 days',
       60, -- 60 menit
       'Ruang Kelas 1', 'Ustadz Ahmad Fauzi',
       true, -- published — wali bisa take
       100, 70)
    RETURNING id INTO v_ujian_id;
    RAISE NOTICE 'Created Ujian (published): %', v_ujian_id;

    INSERT INTO "Ujian" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "type", "description", "startTime", "endTime", "durationMnt", "ruang", "pengawas", "isPublished", "maxScore", "passingScore")
    VALUES
      (v_ta_id, v_sem_id, v_mapel2_id, v_kelas_id, v_guru_id,
       'Ujian Akhir Semester Akidah Akhlak',
       'UAS',
       'Ujian akhir semester untuk mapel Akidah Akhlak.',
       NOW() + INTERVAL '3 days',
       NOW() + INTERVAL '10 days',
       90,
       'Ruang Kelas 1', 'Ustadz Ahmad Fauzi',
       false, -- draft — belum published
       100, 70)
    RETURNING id INTO v_ujian_id2;
    RAISE NOTICE 'Created Ujian (draft): %', v_ujian_id2;
  ELSE
    SELECT id INTO v_ujian_id FROM "Ujian" WHERE "isPublished" = true LIMIT 1;
    SELECT id INTO v_ujian_id2 FROM "Ujian" WHERE "isPublished" = false LIMIT 1;
  END IF;

  -- ============================================================================
  -- 3. Seed UjianSoal (4 soal di ujian pertama, urutan 1-4)
  -- ============================================================================
  IF v_ujian_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "UjianSoal" WHERE "ujianId" = v_ujian_id) THEN
    INSERT INTO "UjianSoal" ("ujianId", "bankSoalId", "urutan", "bobot")
    SELECT v_ujian_id, id, ROW_NUMBER() OVER (), "bobot"
    FROM "BankSoal"
    WHERE "mapelId" = v_mapel_id
    ORDER BY "createdAt"
    LIMIT 4;
    RAISE NOTICE 'Created UjianSoal for ujian: %', v_ujian_id;
  END IF;

  -- ============================================================================
  -- 4. Seed UjianPeserta (3 santri pertama jadi peserta ujian published)
  -- ============================================================================
  IF v_ujian_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "UjianPeserta" WHERE "ujianId" = v_ujian_id) THEN
    INSERT INTO "UjianPeserta" ("ujianId", "santriId", "ruang", "pengawas", "isHadir")
    VALUES
      (v_ujian_id, v_santri_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true),
      (v_ujian_id, v_santri2_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true),
      (v_ujian_id, v_santri3_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true);
    RAISE NOTICE 'Created UjianPeserta for ujian: %', v_ujian_id;
  END IF;

  -- ============================================================================
  -- 5. Seed Tugas (1 tugas published untuk guru + wali test)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "Tugas" WHERE "deletedAt" IS NULL) THEN
    INSERT INTO "Tugas" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "description", "type", "fileUrl", "maxScore", "dueDate", "isPublished", "publishedAt")
    VALUES
      (v_ta_id, v_sem_id, v_mapel_id, v_kelas_id, v_guru_id,
       'Tugas Tajwid: Hafalan Surat An-Nas',
       'Hafalkan Surat An-Nas dengan tajwid yang benar. Rekam suara dan kirim via app.',
       'INDIVIDU',
       NULL, 100,
       NOW() + INTERVAL '7 days',
       true,
       NOW())
    RETURNING id INTO v_tugas_id;
    RAISE NOTICE 'Created Tugas (published): %', v_tugas_id;
  END IF;

  -- ============================================================================
  -- 6. Seed Pertemuan (2 pertemuan untuk jadwal guru)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "Pertemuan") THEN
    -- Kolom nyata "Pertemuan": tahunAjaranId, semesterId, kelasId, mapelId,
    -- guruId, pertemuanKe, date, topic, description, isCompleted.
    -- Versi sebelumnya memakai jadwalId/tanggal/materi/catatan/isDone yang
    -- TIDAK ADA, sehingga seluruh seed gagal dan aplikasi terisi data kosong.
    INSERT INTO "Pertemuan" (
      id, "tahunAjaranId", "semesterId", "kelasId", "mapelId", "guruId",
      "pertemuanKe", date, topic, description, "isCompleted", "createdAt", "updatedAt"
    )
    SELECT gen_random_uuid()::text, j."tahunAjaranId", j."semesterId", j."kelasId",
           j."mapelId", j."guruId", 1, CURRENT_DATE, 'Pertemuan hari ini',
           NULL, false, now(), now()
    FROM "Jadwal" j LIMIT 1
    RETURNING id INTO v_pertemuan_id;

    INSERT INTO "Pertemuan" (
      id, "tahunAjaranId", "semesterId", "kelasId", "mapelId", "guruId",
      "pertemuanKe", date, topic, description, "isCompleted", "createdAt", "updatedAt"
    )
    SELECT gen_random_uuid()::text, j."tahunAjaranId", j."semesterId", j."kelasId",
           j."mapelId", j."guruId", 2, CURRENT_DATE - INTERVAL '1 day',
           'Pertemuan kemarin', 'Berjalan lancar', true, now(), now()
    FROM "Jadwal" j LIMIT 1;
    RAISE NOTICE 'Created Pertemuan: %', v_pertemuan_id;
  END IF;

  -- ============================================================================
  -- 7. Seed Surat (2 surat: 1 draft + 1 published)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "Surat") THEN
    INSERT INTO "Surat" ("santriId", "nomorSurat", "type", "title", "content", "status", "tanggalSurat")
    VALUES
      (v_santri_id, 'SURAT-001/2026', 'KETERANGAN_AKTIF', 'Surat Keterangan Aktif Belajar', 'Yang bertanda tangan di bawah ini, Kepala Madrasah Miftahul Ulum 01, menerangkan bahwa:', 'PUBLISHED', NOW()),
      (v_santri_id, 'SURAT-002/2026', 'PINDAH', 'Surat Keterangan Pindah', 'Yang bertanda tangan di bawah ini...', 'DRAFT', NOW())
    RETURNING id INTO v_surat_id;
    RAISE NOTICE 'Created Surat: %', v_surat_id;
  END IF;

  -- ============================================================================
  -- 8. Seed Alumni (3 alumni sample)
  -- ============================================================================
  IF NOT EXISTS (SELECT 1 FROM "Alumni") THEN
    INSERT INTO "Alumni" ("santriId", "tahunLulus", "statusKelulusan", "pekerjaan", "domisiliKota")
    VALUES
      (v_santri_id, 2023, 'LULUS', 'Santri di Pondok Modern', 'Jakarta'),
      (v_santri2_id, 2024, 'LULUS', 'Pelajar SMA', 'Bandung'),
      (v_santri3_id, 2024, 'LULUS', 'Santri Lanjutan', 'Surabaya');
    RAISE NOTICE 'Created 3 Alumni records';
  END IF;

  RAISE NOTICE '\n=== SEED DATA COMPLETED ===';
  RAISE NOTICE 'Ujian Take dapat di-test dengan santri pertama (id: %)', v_santri_id;
END $$;

-- ============================================================================
-- Verification (run after migration):
--   SELECT
--     (SELECT COUNT(*) FROM "BankSoal") AS bank_soal,
--     (SELECT COUNT(*) FROM "Ujian") AS ujian,
--     (SELECT COUNT(*) FROM "UjianSoal") AS ujian_soal,
--     (SELECT COUNT(*) FROM "UjianPeserta") AS ujian_peserta,
--     (SELECT COUNT(*) FROM "Tugas" WHERE "deletedAt" IS NULL) AS tugas,
--     (SELECT COUNT(*) FROM "Pertemuan") AS pertemuan,
--     (SELECT COUNT(*) FROM "Surat") AS surat,
--     (SELECT COUNT(*) FROM "Alumni") AS alumni;
-- ============================================================================
