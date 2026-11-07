-- ============================================================================
-- SIM MADIN — SystemSetting: kolom description & isPublic
-- ============================================================================
-- Bug: halaman Settings di admin_desktop menampilkan kolom Description dan
-- Public, serta mutation `upsertSystemSetting()` mengirim `description` dan
-- `isPublic` pada INSERT/UPDATE. Tapi tabel `SystemSetting` (dari Prisma)
-- hanya punya: id, key, value, type, updatedAt, updatedBy.
--
-- Akibatnya:
--   - `upsertSystemSetting()` gagal (PostgREST error: column does not exist)
--   - `SystemSettingModel.fromJson()` selalu null untuk description/isPublic
--   - Tidak ada cara menandai setting yang boleh dibaca publik (dipakai
--     aplikasi mobile untuk branding/nama madrasah)
--
-- Fix: tambahkan 2 kolom (idempotent). Nilai default aman untuk data lama.
-- ============================================================================

ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "description" TEXT;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "isPublic" BOOLEAN NOT NULL DEFAULT false;

-- Index untuk query setting publik (dipakai app mobile saat branding).
CREATE INDEX IF NOT EXISTS "SystemSetting_isPublic_idx" ON "SystemSetting" ("isPublic");

-- Isi description untuk setting standar madrasah kalau kosong.
UPDATE "SystemSetting"
SET "description" = CASE "key"
  WHEN 'MADRASAH_NAME'    THEN 'Nama resmi madrasah (tampil di app & rapor)'
  WHEN 'MADRASAH_ADDRESS' THEN 'Alamat madrasah'
  WHEN 'MADRASAH_PHONE'   THEN 'Nomor telepon madrasah'
  WHEN 'MADRASAH_HEAD'    THEN 'Nama kepala madrasah (tanda tangan rapor)'
  WHEN 'ACTIVE_TA_ID'     THEN 'ID tahun ajaran aktif'
  WHEN 'ACTIVE_SEMESTER_ID' THEN 'ID semester aktif'
  ELSE "description"
END
WHERE "description" IS NULL;

-- Setting identitas madrasah aman dibaca publik (dipakai app mobile).
UPDATE "SystemSetting"
SET "isPublic" = true
WHERE "key" IN (
  'MADRASAH_NAME', 'MADRASAH_ADDRESS', 'MADRASAH_PHONE',
  'MADRASAH_LOGO', 'MADRASAH_HEAD', 'APP_MIN_VERSION'
);

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT key, value, "isPublic", description FROM "SystemSetting" ORDER BY key;
-- ============================================================================
