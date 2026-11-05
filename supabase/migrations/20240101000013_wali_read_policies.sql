-- ============================================================================
-- SIM MADIN — Add RLS policies for wali to read published Ujian + Tugas + Pertemuan
-- ============================================================================
-- Bug: Ujian, UjianSoal, UjianPeserta, BankSoal, Tugas, Pertemuan hanya bisa
-- diakses oleh staff (admin/guru/bendahara/kepala). Wali (peran WALI) tidak
-- bisa lihat ujian published + soal + peserta → fitur Ujian Take gagal load.
--
-- Fix: tambah policy SELECT khusus untuk wali pada:
--   - Ujian: where isPublished = true (wali hanya lihat ujian yang sudah published)
--   - UjianPeserta: where santriId IN (santri milik wali yang login)
--   - UjianSoal: where ujianId IN (ujian yang sudah di-publish)
--   - BankSoal: where id IN (soal yang dipakai di ujian published untuk peserta wali)
--   - Tugas: where isPublished = true AND kelasId IN (kelas anak wali)
--   - Pertemuan: where kelasId IN (kelas anak wali)
--
-- Idempotent — DROP IF EXISTS dulu sebelum CREATE.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Ujian — wali bisa SELECT ujian yang isPublished=true
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "uj_wali_read_published" ON "Ujian";
CREATE POLICY "uj_wali_read_published"
  ON "Ujian" FOR SELECT
  TO authenticated
  USING (
    "isPublished" = true
    AND has_role('WALI')
    AND "deletedAt" IS NULL
  );

-- ----------------------------------------------------------------------------
-- 2. UjianPeserta — wali bisa SELECT peserta where santriId = anak wali
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "up_wali_read_own" ON "UjianPeserta";
CREATE POLICY "up_wali_read_own"
  ON "UjianPeserta" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND is_wali_of_santri("santriId")
  );

-- ----------------------------------------------------------------------------
-- 3. UjianSoal — wali bisa SELECT soal where ujianId = ujian published
--   (yang pesertanya adalah anak wali)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "us_wali_read_published" ON "UjianSoal";
CREATE POLICY "us_wali_read_published"
  ON "UjianSoal" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "ujianId" IN (
      SELECT u.id FROM "Ujian" u
      WHERE u."isPublished" = true
        AND u."deletedAt" IS NULL
        AND EXISTS (
          SELECT 1 FROM "UjianPeserta" up
          WHERE up."ujianId" = u.id
            AND is_wali_of_santri(up."santriId")
        )
    )
  );

-- ----------------------------------------------------------------------------
-- 4. BankSoal — wali bisa SELECT soal yang dipakai di ujian published
--    (where bankSoalId IN soal yang ada di UjianSoal untuk ujian peserta wali)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "bs_wali_read_published" ON "BankSoal";
CREATE POLICY "bs_wali_read_published"
  ON "BankSoal" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND id IN (
      SELECT us."bankSoalId" FROM "UjianSoal" us
      WHERE us."ujianId" IN (
        SELECT u.id FROM "Ujian" u
        WHERE u."isPublished" = true
          AND u."deletedAt" IS NULL
      )
    )
  );

-- ----------------------------------------------------------------------------
-- 5. Tugas — wali bisa SELECT tugas published untuk kelas anak wali
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "tug_wali_read_published" ON "Tugas";
CREATE POLICY "tug_wali_read_published"
  ON "Tugas" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "isPublished" = true
    AND "deletedAt" IS NULL
    AND "kelasId" IN (
      SELECT s."kelasId" FROM "SantriWali" sw
      JOIN "Santri" s ON s.id = sw."santriId"
      WHERE sw."waliId" = current_wali_id()
        AND sw."canAccess" = true
        AND s."deletedAt" IS NULL
    )
  );

-- ----------------------------------------------------------------------------
-- 6. Pertemuan — wali bisa SELECT pertemuan untuk kelas anak wali
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "per_wali_read_own" ON "Pertemuan";
CREATE POLICY "per_wali_read_own"
  ON "Pertemuan" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "kelasId" IN (
      SELECT s."kelasId" FROM "SantriWali" sw
      JOIN "Santri" s ON s.id = sw."santriId"
      WHERE sw."waliId" = current_wali_id()
        AND sw."canAccess" = true
        AND s."deletedAt" IS NULL
    )
  );

-- ----------------------------------------------------------------------------
-- 7. Reload PostgREST schema cache
-- ----------------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification (run after migration):
--   SELECT tablename, policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND policyname LIKE '%wali%'
--   ORDER BY tablename;
-- ============================================================================
