-- ============================================================================
-- SIM MADIN — CEK & PERBAIKI SKEMA   (untuk error "column ... does not exist")
-- ============================================================================
-- Tempel di Supabase SQL Editor. Bagian 1 hanya membaca, bagian 2 memperbaiki.
-- ============================================================================


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 1. CEK — kolom apa yang HILANG pada tabel yang sudah ada              │
-- └──────────────────────────────────────────────────────────────────────────┘
-- Hasilnya: daftar tabel + nama kolom yang belum ada di database, tetapi
-- dibutuhkan oleh kode aplikasi.
--
-- Cara kerja: membandingkan kolom nyata di database terhadap daftar kolom
-- yang dipakai di migrasi. Yang tidak cocok akan muncul di sini.

WITH dibutuhkan(tabel, kolom) AS (
  VALUES
    -- Tambahkan pasangan tabel/kolom lain di sini bila perlu.
    ('Ujian',        'isPublished'),
    ('Tugas',        'isPublished'),
    ('Materi',       'isPublished'),
    ('Announcement', 'isPublished')
)
SELECT d.tabel,
       d.kolom,
       (c.column_name IS NOT NULL) AS sudah_ada
FROM dibutuhkan d
LEFT JOIN information_schema.columns c
       ON c.table_schema = 'public'
      AND c.table_name   = d.tabel
      AND c.column_name  = d.kolom
ORDER BY sudah_ada, d.tabel, d.kolom;


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 1b. CEK CEPAT — daftar SEMUA kolom pada tabel yang bermasalah         │
-- └──────────────────────────────────────────────────────────────────────────┘
-- SELECT table_name, string_agg(column_name, ', ' ORDER BY ordinal_position)
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name IN ('Ujian','Tugas','Materi','Announcement')
-- GROUP BY table_name;


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 2. PERBAIKI — tambahkan kolom yang hilang                             │
-- └──────────────────────────────────────────────────────────────────────────┘
-- Hapus tanda komentar, lalu Run. Aman dijalankan berulang.
-- Bagian lengkap (semua 633 kolom) ada di:
--     supabase/migrations/20240101000033_schema_reconcile.sql

-- ALTER TABLE "Ujian"        ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT false;
-- ALTER TABLE "Tugas"        ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;
-- ALTER TABLE "Materi"       ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;
-- ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;

-- NOTIFY pgrst, 'reload schema';


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 3. LANJUTKAN SEED                                                     │
-- └──────────────────────────────────────────────────────────────────────────┘
-- SELECT * FROM public.seed_all_demo();
-- SELECT * FROM public.repair_demo_logins();
-- SELECT * FROM public.demo_account_status();


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CATATAN PENTING                                                       │
-- └──────────────────────────────────────────────────────────────────────────┘
-- Baseline memakai CREATE TABLE IF NOT EXISTS. Kalau tabel SUDAH ADA (misal
-- database dibuat dari skema versi lama), perintah itu tidak melakukan apa
-- pun — jadi kolom baru tidak pernah ditambahkan. Itulah sebabnya error
-- 42703 muncul meski baseline sudah dijalankan.
--
-- Solusinya bukan membuat ulang tabel (data bisa hilang), melainkan
-- menambahkan kolom yang hilang dengan ALTER TABLE ... ADD COLUMN.
