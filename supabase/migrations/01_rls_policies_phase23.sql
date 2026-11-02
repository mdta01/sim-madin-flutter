-- ============================================================================
-- SIM MADIN — RLS Policies (Phase 2 + 3 — mobile_kepala + mobile_bendahara)
-- ============================================================================
-- Enable RLS untuk semua tabel yang dipakai di app Flutter.
-- Policies menggunakan helper functions di file 00_rls_helper_functions.sql.
--
-- Role matrix:
--   SUPER_ADMIN, ADMIN     → full access (CRUD all)
--   KEPALA                  → read-only (CRUD denied)
--   BENDAHARA               → read-mostly + write keuangan (Payment, Tagihan,
--                            TransaksiKas, HonorGuru)
--   GURU                    → read-only + write akademik (Absensi, Nilai,
--                            Pertemuan, Materi, Tugas, Ujian) untuk kelas diajar
--   WALI                    → read-only data anaknya sendiri
--
-- Format policy:
--   {table}_read   → SELECT  TO authenticated USING (...)
--   {table}_insert → INSERT  TO authenticated WITH CHECK (...)
--   {table}_update → UPDATE  TO authenticated USING (...) WITH CHECK (...)
--   {table}_delete → DELETE  TO authenticated USING (...)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- User, Role, UserRole, RolePermission, Permission
-- ---------------------------------------------------------------------------
-- Hanya admin yang bisa CRUD User/Role/Permission. User lain bisa lihat
-- info dirinya sendiri (User) untuk display profile.
-- ---------------------------------------------------------------------------

ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_self_read" ON "User"
  FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "user_admin_read" ON "User"
  FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "user_admin_write" ON "User"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Role" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "role_read" ON "Role"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "role_admin_write" ON "Role"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "UserRole" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_role_self_read" ON "UserRole"
  FOR SELECT TO authenticated USING ("userId" = auth.uid());
CREATE POLICY "user_role_admin_read" ON "UserRole"
  FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "user_role_admin_write" ON "UserRole"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Permission" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permission_read" ON "Permission"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "permission_admin_write" ON "Permission"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "RolePermission" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "role_permission_read" ON "RolePermission"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "role_permission_admin_write" ON "RolePermission"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- Tahun Ajaran, Semester, Kelas, MataPelajaran, JenisTagihan (reference data)
-- ---------------------------------------------------------------------------
-- Staff + wali bisa SELECT. Hanya admin yang bisa CRUD.
-- ---------------------------------------------------------------------------

ALTER TABLE "TahunAjaran" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tahun_ajaran_read" ON "TahunAjaran"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "tahun_ajaran_admin_write" ON "TahunAjaran"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Semester" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "semester_read" ON "Semester"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "semester_admin_write" ON "Semester"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Kelas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kelas_read" ON "Kelas"
  FOR SELECT TO authenticated USING ("deletedAt" IS NULL);
CREATE POLICY "kelas_admin_write" ON "Kelas"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "MataPelajaran" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mapel_read" ON "MataPelajaran"
  FOR SELECT TO authenticated USING ("deletedAt" IS NULL);
CREATE POLICY "mapel_admin_write" ON "MataPelajaran"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Jadwal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "jadwal_read" ON "Jadwal"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "jadwal_admin_write" ON "Jadwal"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "JenisTagihan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "jenis_tagihan_read" ON "JenisTagihan"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "jenis_tagihan_admin_write" ON "JenisTagihan"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- Santri — soft delete, multi-tenant madrasah
-- ---------------------------------------------------------------------------
-- Staff (admin/kepala/guru/bendahara) bisa SELECT semua santri aktif.
-- Wali hanya bisa lihat santri yang terkait dengannya (via SantriWali).
-- Admin/bendahara bisa CRUD. Guru bisa read-only.
-- ---------------------------------------------------------------------------

ALTER TABLE "Santri" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "santri_staff_read" ON "Santri"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL AND public.is_staff()
  );
CREATE POLICY "santri_wali_read" ON "Santri"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND public.is_wali_of_santri(id)
  );
CREATE POLICY "santri_admin_write" ON "Santri"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Wali, SantriWali, WaliActivation, PhoneChangeLog
-- ---------------------------------------------------------------------------
-- Wali bisa lihat data dirinya sendiri. Admin bisa CRUD semua.
-- SantriWali: wali bisa lihat link-nya sendiri, admin bisa CRUD.
-- ---------------------------------------------------------------------------

ALTER TABLE "Wali" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wali_self_read" ON "Wali"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND id = public.current_wali_id());
CREATE POLICY "wali_admin_read" ON "Wali"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_admin_level());
CREATE POLICY "wali_admin_write" ON "Wali"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "SantriWali" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "santri_wali_self_read" ON "SantriWali"
  FOR SELECT TO authenticated
  USING ("waliId" = public.current_wali_id());
CREATE POLICY "santri_wali_admin_read" ON "SantriWali"
  FOR SELECT TO authenticated USING (public.is_admin_level());
CREATE POLICY "santri_wali_admin_write" ON "SantriWali"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "WaliActivation" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "wali_activation_admin_all" ON "WaliActivation"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "PhoneChangeLog" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "phone_change_log_admin_all" ON "PhoneChangeLog"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Guru — guru bisa lihat profil sendiri + staff lain. Admin CRUD.
-- ---------------------------------------------------------------------------

ALTER TABLE "Guru" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "guru_self_read" ON "Guru"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND id = public.current_guru_id());
CREATE POLICY "guru_staff_read" ON "Guru"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "guru_admin_write" ON "Guru"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Absensi — guru input per kelas yang diajar; wali lihat anaknya
-- ---------------------------------------------------------------------------

ALTER TABLE "Absensi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "absensi_staff_read" ON "Absensi"
  FOR SELECT TO authenticated
  USING (public.is_staff());
CREATE POLICY "absensi_wali_read" ON "Absensi"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "absensi_guru_insert_update" ON "Absensi"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  );
CREATE POLICY "absensi_guru_update" ON "Absensi"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  );
CREATE POLICY "absensi_admin_delete" ON "Absensi"
  FOR DELETE TO authenticated USING (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Nilai — same pattern dengan Absensi
-- ---------------------------------------------------------------------------

ALTER TABLE "Nilai" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "nilai_staff_read" ON "Nilai"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "nilai_wali_read" ON "Nilai"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "nilai_guru_insert" ON "Nilai"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  );
CREATE POLICY "nilai_guru_update" ON "Nilai"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND public.is_guru_of_kelas("kelasId")
    )
  );
CREATE POLICY "nilai_admin_delete" ON "Nilai"
  FOR DELETE TO authenticated USING (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- Tagihan, Payment — keuangan. Read: staff + wali (untuk anaknya).
-- Write: admin + bendahara only.
-- ---------------------------------------------------------------------------

ALTER TABLE "Tagihan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tagihan_staff_read" ON "Tagihan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "tagihan_wali_read" ON "Tagihan"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "tagihan_bendahara_write" ON "Tagihan"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "Payment" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payment_staff_read" ON "Payment"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "payment_wali_read" ON "Payment"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND "santriId" IS NOT NULL
         AND public.is_wali_of_santri("santriId"));
CREATE POLICY "payment_bendahara_insert" ON "Payment"
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_level());
CREATE POLICY "payment_bendahara_update" ON "Payment"
  FOR UPDATE TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());
CREATE POLICY "payment_admin_delete" ON "Payment"
  FOR DELETE TO authenticated USING (public.is_admin());

-- ---------------------------------------------------------------------------
-- Kas, TransaksiKas — keuangan. Read: staff. Write: admin + bendahara.
-- ---------------------------------------------------------------------------

ALTER TABLE "Kas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kas_staff_read" ON "Kas"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "kas_bendahara_write" ON "Kas"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "TransaksiKas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "transaksi_kas_staff_read" ON "TransaksiKas"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "transaksi_kas_bendahara_insert" ON "TransaksiKas"
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_level());
CREATE POLICY "transaksi_kas_bendahara_update" ON "TransaksiKas"
  FOR UPDATE TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());
CREATE POLICY "transaksi_kas_admin_delete" ON "TransaksiKas"
  FOR DELETE TO authenticated USING (public.is_admin());

-- ---------------------------------------------------------------------------
-- HonorGuru — keuangan guru. Read: staff + guru sendiri.
-- Write: admin + bendahara (approve/pay).
-- ---------------------------------------------------------------------------

ALTER TABLE "HonorGuru" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "honor_guru_staff_read" ON "HonorGuru"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "honor_guru_self_read" ON "HonorGuru"
  FOR SELECT TO authenticated
  USING (public.has_role('GURU') AND "guruId" = public.current_guru_id());
CREATE POLICY "honor_guru_bendahara_write" ON "HonorGuru"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ---------------------------------------------------------------------------
-- AuditLog, SystemSetting, Announcement
-- ---------------------------------------------------------------------------
-- AuditLog: read admin only, insert by any authenticated user.
-- SystemSetting: read all staff, write admin only.
-- Announcement: read all, write admin only.
-- ---------------------------------------------------------------------------

ALTER TABLE "AuditLog" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_log_admin_read" ON "AuditLog"
  FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "audit_log_insert" ON "AuditLog"
  FOR INSERT TO authenticated WITH CHECK (true);

ALTER TABLE "SystemSetting" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "system_setting_staff_read" ON "SystemSetting"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "system_setting_admin_write" ON "SystemSetting"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Announcement" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "announcement_read" ON "Announcement"
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "announcement_admin_write" ON "Announcement"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());
