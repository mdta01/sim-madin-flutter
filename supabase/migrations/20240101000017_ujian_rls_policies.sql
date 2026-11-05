-- ============================================================================
-- SIM MADIN — RLS policies for UjianSesi, UjianJawaban, PengumpulanTugas,
--             UjianSoal, UjianPeserta, UjianNilai, CatatanWaliKelas
-- ============================================================================
-- Audit found 7 tables with missing RLS policies:
--   - UjianSesi: NO policies at all (blocks startUjianSesi + submitUjian)
--   - UjianJawaban: NO policies at all (blocks submitUjianJawaban)
--   - PengumpulanTugas: SELECT only (blocks tugas submission)
--   - UjianSoal: SELECT only (blocks guru adding soal)
--   - UjianPeserta: SELECT only (blocks guru adding peserta)
--   - UjianNilai: SELECT only (blocks auto-nilai from submitUjian)
--   - CatatanWaliKelas: NO policies at all
--
-- Policy design:
--   - Wali: can access own santri's data (via is_wali_of_santri)
--   - Guru: can access ujian/tugas they own (via current_guru_id vs Ujian.guruId)
--   - Staff (admin/kepala/bendahara): full access
-- ============================================================================

-- ============================================================================
-- 1. UjianSesi — wali start/resume + submit ujian
-- ============================================================================

-- SELECT: wali can see own santri's sesi; staff can see all
DROP POLICY IF EXISTS "usesi_wali_select_own" ON "UjianSesi";
CREATE POLICY "usesi_wali_select_own"
  ON "UjianSesi" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

-- INSERT: wali can create sesi for own santri; staff can create
DROP POLICY IF EXISTS "usesi_wali_insert_own" ON "UjianSesi";
CREATE POLICY "usesi_wali_insert_own"
  ON "UjianSesi" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

-- UPDATE: wali can update own santri's sesi (set FINISHED, score, endTime);
-- staff can update all
DROP POLICY IF EXISTS "usesi_wali_update_own" ON "UjianSesi";
CREATE POLICY "usesi_wali_update_own"
  ON "UjianSesi" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

-- ============================================================================
-- 2. UjianJawaban — wali submit jawaban + guru grade
-- ============================================================================

-- SELECT: wali can see own santri's jawaban; guru can see jawaban in
-- ujian they own; staff can see all
DROP POLICY IF EXISTS "ujaw_wali_select_own" ON "UjianJawaban";
CREATE POLICY "ujaw_wali_select_own"
  ON "UjianJawaban" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "UjianSoal" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."ujianSoalId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- INSERT: wali can submit jawaban for own santri; staff can insert
DROP POLICY IF EXISTS "ujaw_wali_insert_own" ON "UjianJawaban";
CREATE POLICY "ujaw_wali_insert_own"
  ON "UjianJawaban" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

-- UPDATE: wali can update own santri's jawaban (auto-correct);
-- guru can update jawaban in ujian they own; staff can update all
DROP POLICY IF EXISTS "ujaw_update_participant" ON "UjianJawaban";
CREATE POLICY "ujaw_update_participant"
  ON "UjianJawaban" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "UjianSoal" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."ujianSoalId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "UjianSoal" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."ujianSoalId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- ============================================================================
-- 3. PengumpulanTugas — wali submit tugas + guru grade
-- ============================================================================

-- SELECT: wali can see own santri's submissions; guru can see submissions
-- for tugas they own; staff can see all
DROP POLICY IF EXISTS "pt_select_participant" ON "PengumpulanTugas";
DROP POLICY IF EXISTS "pt_select_participant" ON "PengumpulanTugas";
CREATE POLICY "pt_select_participant"
  ON "PengumpulanTugas" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- INSERT: wali can submit tugas for own santri; staff can insert
DROP POLICY IF EXISTS "pt_wali_insert_own" ON "PengumpulanTugas";
CREATE POLICY "pt_wali_insert_own"
  ON "PengumpulanTugas" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

-- UPDATE: wali can update own santri's submissions (before deadline);
-- guru can update (grade: score, feedback); staff can update all
DROP POLICY IF EXISTS "pt_update_participant" ON "PengumpulanTugas";
CREATE POLICY "pt_update_participant"
  ON "PengumpulanTugas" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = current_guru_id()
    ))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- ============================================================================
-- 4. UjianSoal — guru manage soal (add/edit/delete)
-- ============================================================================

-- INSERT: guru can add soal to ujian they own; admin can insert
DROP POLICY IF EXISTS "us_guru_insert_own" ON "UjianSoal";
CREATE POLICY "us_guru_insert_own"
  ON "UjianSoal" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- UPDATE: guru can edit soal in ujian they own; admin can update
DROP POLICY IF EXISTS "us_guru_update_own" ON "UjianSoal";
CREATE POLICY "us_guru_update_own"
  ON "UjianSoal" FOR UPDATE
  TO authenticated
  USING (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  )
  WITH CHECK (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- DELETE: guru can delete soal from ujian they own; admin can delete
DROP POLICY IF EXISTS "us_guru_delete_own" ON "UjianSoal";
CREATE POLICY "us_guru_delete_own"
  ON "UjianSoal" FOR DELETE
  TO authenticated
  USING (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- ============================================================================
-- 5. UjianPeserta — guru/admin manage peserta
-- ============================================================================

-- INSERT: guru can add peserta to ujian they own; admin can insert
DROP POLICY IF EXISTS "up_guru_insert_own" ON "UjianPeserta";
CREATE POLICY "up_guru_insert_own"
  ON "UjianPeserta" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- UPDATE: guru can update peserta in ujian they own; admin can update
DROP POLICY IF EXISTS "up_guru_update_own" ON "UjianPeserta";
CREATE POLICY "up_guru_update_own"
  ON "UjianPeserta" FOR UPDATE
  TO authenticated
  USING (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  )
  WITH CHECK (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- DELETE: guru can delete peserta from ujian they own; admin can delete
DROP POLICY IF EXISTS "up_guru_delete_own" ON "UjianPeserta";
CREATE POLICY "up_guru_delete_own"
  ON "UjianPeserta" FOR DELETE
  TO authenticated
  USING (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- ============================================================================
-- 6. UjianNilai — auto-create from submitUjian + guru grade
-- ============================================================================

-- SELECT: wali can see own santri's nilai; guru can see nilai for ujian
-- they own; staff can see all
DROP POLICY IF EXISTS "un_wali_select_own" ON "UjianNilai";
CREATE POLICY "un_wali_select_own"
  ON "UjianNilai" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- INSERT: wali (via submitUjian) can create nilai for own santri;
-- guru can insert for ujian they own; admin can insert
DROP POLICY IF EXISTS "un_insert_participant" ON "UjianNilai";
CREATE POLICY "un_insert_participant"
  ON "UjianNilai" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_admin_level()
  );

-- UPDATE: guru can grade (update score, notes) for ujian they own;
-- admin can update all
DROP POLICY IF EXISTS "un_guru_update_own" ON "UjianNilai";
CREATE POLICY "un_guru_update_own"
  ON "UjianNilai" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

-- ============================================================================
-- 7. CatatanWaliKelas — guru write notes for santri
-- ============================================================================

-- SELECT: guru (wali kelas) can see notes for santri in their kelas;
-- staff can see all; wali can see own santri's notes
DROP POLICY IF EXISTS "cwk_select_staff" ON "CatatanWaliKelas";
CREATE POLICY "cwk_select_staff"
  ON "CatatanWaliKelas" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR (has_role('GURU') AND is_wali_kelas_of(
      (SELECT "kelasId" FROM "Santri" WHERE id = "CatatanWaliKelas"."santriId")
    ))
    OR is_staff()
  );

-- INSERT: guru can create notes for santri in their kelas; admin can insert
DROP POLICY IF EXISTS "cwk_guru_insert" ON "CatatanWaliKelas";
CREATE POLICY "cwk_guru_insert"
  ON "CatatanWaliKelas" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('GURU') AND is_wali_kelas_of(
      (SELECT "kelasId" FROM "Santri" WHERE id = "CatatanWaliKelas"."santriId")
    ))
    OR is_admin_level()
  );

-- UPDATE: guru can update own notes; admin can update all
DROP POLICY IF EXISTS "cwk_guru_update" ON "CatatanWaliKelas";
CREATE POLICY "cwk_guru_update"
  ON "CatatanWaliKelas" FOR UPDATE
  TO authenticated
  USING (
    (has_role('GURU') AND is_wali_kelas_of(
      (SELECT "kelasId" FROM "Santri" WHERE id = "CatatanWaliKelas"."santriId")
    ))
    OR is_admin_level()
  )
  WITH CHECK (
    (has_role('GURU') AND is_wali_kelas_of(
      (SELECT "kelasId" FROM "Santri" WHERE id = "CatatanWaliKelas"."santriId")
    ))
    OR is_admin_level()
  );

-- ============================================================================
-- 8. Reload schema cache
-- ============================================================================
NOTIFY pgrst, 'reload schema';
