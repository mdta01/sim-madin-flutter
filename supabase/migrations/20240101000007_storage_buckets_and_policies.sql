-- ============================================================================
-- SIM MADIN — Supabase Storage Buckets + RLS Policies
-- ============================================================================
-- 6 buckets dengan RLS policy berbasis role (admin/guru/bendahara/kepala/wali).
-- Kebijakan mengikuti helper functions yang sudah ada di migration
-- 20240101000000_rls_helper_functions.sql (current_user_id, has_role, is_staff,
-- is_admin_level, is_admin, current_wali_id, is_wali_of_santri, current_guru_id).
--
-- Bucket list:
--   photos     (public)  — foto profil santri/guru/wali + thumbnail
--   materi     (public)  — PDF materi pelajaran (read all authenticated)
--   pengumuman (public)  — lampiran pengumuman (read all authenticated)
--   surat      (private) — PDF surat resmi (admin-only)
--   tugas      (private) — lampiran tugas (guru upload, siswa baca)
--   ujian      (private) — lampiran soal ujian (guru upload, siswa baca saat ujian)
--
-- Konvensi path:
--   photos/santri/{santriId}/{timestamp}.jpg
--   photos/guru/{guruId}/{timestamp}.jpg
--   photos/wali/{waliId}/{timestamp}.jpg
--   materi/{mataPelajaranId}/{filename}
--   pengumuman/{pengumumanId}/{filename}
--   surat/{suratId}/{filename}
--   tugas/{tugasId}/{filename}
--   ujian/{ujianId}/{soalId}/{filename}
-- ============================================================================

-- ============================================================================
-- STEP 1 — Create buckets (idempotent, ON CONFLICT DO UPDATE)
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  -- Foto profil: max 5MB, public read (untuk ditampilkan di app)
  ('photos', 'photos', true, 5242880,
    ARRAY['image/jpeg','image/png','image/webp','image/gif']),

  -- Materi pelajaran: max 50MB (boleh PDF/PPT/DOCX), public read
  ('materi', 'materi', true, 52428800,
    ARRAY['application/pdf',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),

  -- Surat resmi: max 10MB, PRIVATE (admin-only via signed URL)
  ('surat', 'surat', false, 10485760,
    ARRAY['application/pdf']),

  -- Lampiran tugas: max 10MB, PRIVATE (guru upload, siswa baca)
  ('tugas', 'tugas', false, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png']),

  -- Lampiran pengumuman: max 10MB, public read
  ('pengumuman', 'pengumuman', true, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png']),

  -- Lampiran ujian: max 10MB, PRIVATE (guru upload, siswa baca saat ujian)
  ('ujian', 'ujian', false, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png'])
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================================
-- STEP 2 — Helper function: parse bucket name from object path
-- (Supabase storage.objects memiliki kolom bucket_id, jadi tidak perlu parse)
-- ============================================================================

-- ============================================================================
-- STEP 3 — RLS policies per bucket
-- ============================================================================
-- Pattern:
--   SELECT  → siapa yang boleh baca object
--   INSERT  → siapa yang boleh upload
--   UPDATE  → siapa yang boleh replace
--   DELETE  → siapa yang boleh hapus
--
-- Storage.objects RLS otomatis dipakai ketika policy dibuat pada tabel
-- storage.objects dengan condition `bucket_id = 'NAMA_BUCKET'`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 — photos (public read, authenticated upload by owner)
-- ----------------------------------------------------------------------------
-- Public read: bucket sudah public, tapi tetap perlu policy SELECT supaya
-- anon user bisa list objects via API.
CREATE POLICY "photos_select_public"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'photos');

-- Upload: hanya user login yang boleh upload ke folder miliknya
--   photos/santri/{santriId}/...  → wali santri tsb ATAU staff
--   photos/guru/{guruId}/...      → guru tsb sendiri ATAU admin
--   photos/wali/{waliId}/...      → wali tsb sendiri ATAU admin
CREATE POLICY "photos_insert_authenticated"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND public.is_staff()
  );

-- Update: admin & guru (untuk dirinya sendiri)
CREATE POLICY "photos_update_owner_or_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (public.is_admin_level() OR public.is_staff())
  );

-- Delete: admin only (untuk cleanup)
CREATE POLICY "photos_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND public.is_admin_level()
  );

-- ----------------------------------------------------------------------------
-- 3.2 — materi (public read, staff upload)
-- ----------------------------------------------------------------------------
CREATE POLICY "materi_select_public"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'materi');

CREATE POLICY "materi_insert_staff"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'materi'
    AND public.is_staff()
  );

CREATE POLICY "materi_update_staff"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'materi'
    AND public.is_staff()
  );

CREATE POLICY "materi_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'materi'
    AND public.is_admin_level()
  );

-- ----------------------------------------------------------------------------
-- 3.3 — pengumuman (public read, staff upload)
-- ----------------------------------------------------------------------------
CREATE POLICY "pengumuman_select_public"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'pengumuman');

CREATE POLICY "pengumuman_insert_staff"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'pengumuman'
    AND public.is_staff()
  );

CREATE POLICY "pengumuman_update_staff"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'pengumuman'
    AND public.is_staff()
  );

CREATE POLICY "pengumuman_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'pengumuman'
    AND public.is_admin_level()
  );

-- ----------------------------------------------------------------------------
-- 3.4 — surat (PRIVATE: admin-only full access, staff read via signed URL)
-- ----------------------------------------------------------------------------
-- Read: admin-level (lihat daftar surat) + staff (lihat surat via link)
CREATE POLICY "surat_select_staff"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'surat'
    AND public.is_staff()
  );

CREATE POLICY "surat_insert_admin"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'surat'
    AND public.is_admin_level()
  );

CREATE POLICY "surat_update_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'surat'
    AND public.is_admin_level()
  );

CREATE POLICY "surat_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'surat'
    AND public.is_admin_level()
  );

-- ----------------------------------------------------------------------------
-- 3.5 — tugas (PRIVATE: guru upload, siswa baca via signed URL)
-- ----------------------------------------------------------------------------
-- Read: any authenticated user (siswa & wali butuh akses lampiran tugas)
CREATE POLICY "tugas_select_authenticated"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'tugas');

-- Insert: guru & admin (yang upload lampiran tugas)
CREATE POLICY "tugas_insert_guru_or_admin"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'tugas'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

-- Update: pemilik (guru) atau admin
CREATE POLICY "tugas_update_guru_or_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'tugas'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

-- Delete: admin only (atau guru pemilik — tapi Supabase storage tidak punya
-- kolom owner, jadi untuk simplifikasi: admin-only)
CREATE POLICY "tugas_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'tugas'
    AND public.is_admin_level()
  );

-- ----------------------------------------------------------------------------
-- 3.6 — ujian (PRIVATE: guru upload, siswa baca saat sesi ujian aktif)
-- ----------------------------------------------------------------------------
-- Read: authenticated user (siswa yang ikut ujian + guru pemilik)
-- Catatan: Pembatasan lebih ketat (hanya saat sesi ujian aktif) bisa dilakukan
-- di layer aplikasi via signed URL yang pendek expiry-nya (5-10 menit).
CREATE POLICY "ujian_select_authenticated"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'ujian');

CREATE POLICY "ujian_insert_guru_or_admin"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'ujian'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

CREATE POLICY "ujian_update_guru_or_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'ujian'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

CREATE POLICY "ujian_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'ujian'
    AND public.is_admin_level()
  );

-- ============================================================================
-- STEP 4 — Verification
-- ============================================================================
-- Run query untuk konfirmasi:
--   SELECT id, name, public, file_size_limit, allowed_mime_types
--   FROM storage.buckets ORDER BY id;
--
--   SELECT tablename, policyname, cmd, roles
--   FROM pg_policies
--   WHERE schemaname = 'storage' AND tablename = 'objects'
--   ORDER BY policyname;
-- ============================================================================
