-- ============================================================================
-- SIM MADIN — Storage Columns (filePath + photoUrl additions)
-- ============================================================================
-- Migration ini menambahkan kolom `filePath` (untuk tracking path object di
-- Supabase Storage — dipakai untuk delete) dan kolom `photoUrl` di tabel yang
-- belum punya. Migration ini idempotent (DO $$ ... IF NOT EXISTS).
--
-- Logic:
--   Materi.fileUrl sudah ada → tambah filePath
--   Tugas.fileUrl sudah ada → tambah filePath
--   Surat → tambah filePath + fileUrl (sebelumnya belum ada)
--   Announcement → tambah filePath + fileUrl (untuk lampiran)
--   Ujian → tambah filePath + fileUrl (untuk soal PDF/image)
--   Wali → tambah photoUrl (sebelumnya belum ada)
--
-- Kolom `fileUrl` = public URL atau signed URL (yang disimpan ke DB).
-- Kolom `filePath` = path object di dalam bucket (cth: 'materi/mapel-id/file.pdf').
--                    Dipakai untuk delete object dari Storage saat row di-delete.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Materi → tambah filePath (untuk delete object storage)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Materi'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Materi" ADD COLUMN "filePath" TEXT;
    COMMENT ON COLUMN "Materi"."filePath" IS
      'Path object di Supabase Storage bucket materi (cth: mapelId/filename.pdf). Dipakai untuk delete.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. Tugas → tambah filePath
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Tugas'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Tugas" ADD COLUMN "filePath" TEXT;
    COMMENT ON COLUMN "Tugas"."filePath" IS
      'Path object di Supabase Storage bucket tugas.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 3. Surat → tambah filePath + fileUrl (sebelumnya belum ada)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Surat'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Surat" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Surat" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Surat"."filePath" IS
      'Path object PDF di Supabase Storage bucket surat.';
    COMMENT ON COLUMN "Surat"."fileUrl" IS
      'Public/signed URL untuk PDF surat (diisi saat generate).';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 4. Announcement → tambah filePath + fileUrl (untuk lampiran pengumuman)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Announcement'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Announcement" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Announcement" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Announcement"."filePath" IS
      'Path object lampiran di Supabase Storage bucket pengumuman.';
    COMMENT ON COLUMN "Announcement"."fileUrl" IS
      'Public URL untuk lampiran pengumuman.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 5. Ujian → tambah filePath + fileUrl (untuk soal PDF/gambar lampiran)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Ujian'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Ujian" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Ujian" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Ujian"."filePath" IS
      'Path object lampiran di Supabase Storage bucket ujian.';
    COMMENT ON COLUMN "Ujian"."fileUrl" IS
      'Public/signed URL untuk lampiran ujian.';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 6. Wali → tambah photoUrl (sebelumnya belum ada — untuk foto profil wali)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Wali'
      AND column_name = 'photoUrl'
  ) THEN
    ALTER TABLE "Wali" ADD COLUMN "photoUrl" TEXT;
    COMMENT ON COLUMN "Wali"."photoUrl" IS
      'Public URL foto profil wali (di Supabase Storage bucket photos).';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 7. Update RLS policies untuk Wali.photoUrl — biarkan user update photo diri sendiri
--    (Mirip dengan policy existing untuk User.fcmToken)
-- ----------------------------------------------------------------------------
-- Sudah ada policy wali_update_self yang mengizinkan update semua kolom
-- milik Wali sendiri (cek migration 20240101000002_rls_policies_phase45.sql).
-- Tidak perlu policy tambahan untuk photoUrl.

-- ----------------------------------------------------------------------------
-- 8. Trigger: auto-delete Storage object saat row di-delete (soft delete via
--    deletedAt, jadi tidak bisa pakai trigger ROW LEVEL — harus dilakukan
--    di layer aplikasi via StorageService.delete()).
-- ----------------------------------------------------------------------------
-- Catatan: Hard delete pada Materi/Tugas/Surat/Ujian/Announcement sudah
-- di-handle di mutation_providers via StorageService.delete() sebelum
-- DB delete. Soft delete (set deletedAt) tidak menghapus object storage.

-- ============================================================================
-- Verification (run query berikut di Supabase SQL Editor untuk konfirmasi):
--
--   SELECT table_name, column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema = 'public'
--     AND table_name IN ('Materi','Tugas','Surat','Announcement','Ujian','Wali')
--     AND (column_name IN ('filePath','fileUrl','photoUrl'))
--   ORDER BY table_name, column_name;
-- ============================================================================
