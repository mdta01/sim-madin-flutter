-- ============================================================================
-- SIM MADIN — RLS Helper Functions
-- ============================================================================
-- Fungsi-fungsi Postgres yang dipakai di RLS policies untuk cek role user
-- yang sedang login (auth.uid()).
--
-- Catatan: function ini pakai SECURITY DEFINER supaya bisa query tabel
-- UserRole + Role dengan context user yang login, walau user itu sendiri
-- belum tentu punya SELECT permission ke tabel tersebut.
--
-- Usage di policy:
--   USING (public.has_role('BENDAHARA'))
--   USING (public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'BENDAHARA']))
-- ============================================================================

-- Cek apakah user yang login punya role tertentu (active).
-- Returns true jika user punya UserRole dengan role code yang cocok AND isActive=true.
CREATE OR REPLACE FUNCTION public.has_role(role_code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM "UserRole" ur
    JOIN "Role" r ON ur."roleId" = r.id
    WHERE ur."userId" = auth.uid()
      AND ur."isActive" = true
      AND r.code = role_code
  );
$$;

-- Cek apakah user punya salah satu dari role list.
-- Returns true kalau user punya minimal satu role dari list.
CREATE OR REPLACE FUNCTION public.has_any_role(role_codes TEXT[])
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM "UserRole" ur
    JOIN "Role" r ON ur."roleId" = r.id
    WHERE ur."userId" = auth.uid()
      AND ur."isActive" = true
      AND r.code = ANY(role_codes)
  );
$$;

-- Cek apakah user adalah staff madrasah (admin/kepala/guru/bendahara,
-- TIDAK termasuk wali). Dipakai untuk policy read-mostly yang tidak boleh
-- diakses wali (mis. lihat semua santri tanpa filter).
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'GURU', 'BENDAHARA']);
$$;

-- Cek apakah user adalah admin-level (super_admin/admin/bendahara/kepala).
-- Dipakai untuk policy yang butuh akses semua data (CRUD santri, manage
-- kelas, dll). Guru tidak termasuk karena aksesnya dibatasi per kelas yang
-- diajar (lihat policy terpisah).
CREATE OR REPLACE FUNCTION public.is_admin_level()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'BENDAHARA']);
$$;

-- Cek apakah user adalah admin (super_admin/admin saja). Untuk operasi
-- kritis seperti CRUD User, Role, SystemSetting.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN']);
$$;

-- Ambil user_id dari wali yang sedang login (kalau user login sbg wali via
-- Supabase Auth, lalu Wali.userId = auth.uid()).
-- Returns null kalau bukan wali.
CREATE OR REPLACE FUNCTION public.current_wali_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "Wali" WHERE "userId" = auth.uid() AND "deletedAt" IS NULL LIMIT 1;
$$;

-- Cek apakah santri tertentu adalah anak dari wali yang sedang login.
-- Dipakai di policy Santri/Absensi/Nilai/Tagihan/Payment untuk restrict
-- wali hanya bisa lihat data anaknya sendiri.
CREATE OR REPLACE FUNCTION public.is_wali_of_santri(santri_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM "SantriWali" sw
    WHERE sw."waliId" = public.current_wali_id()
      AND sw."santriId" = santri_id
      AND sw."canAccess" = true
  );
$$;

-- Ambil user_id dari guru yang sedang login.
-- Returns null kalau bukan guru.
CREATE OR REPLACE FUNCTION public.current_guru_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "Guru" WHERE "userId" = auth.uid() AND "deletedAt" IS NULL LIMIT 1;
$$;

-- Cek apakah guru yang login mengajar kelas tertentu (ada di tabel Jadwal).
-- Dipakai di policy Absensi/Nilai/Pertemuan untuk restrict guru hanya bisa
-- input data kelas yang diajarnya.
CREATE OR REPLACE FUNCTION public.is_guru_of_kelas(kelas_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM "Jadwal" j
    WHERE j."guruId" = public.current_guru_id()
      AND j."kelasId" = kelas_id
  );
$$;

-- Cek apakah guru yang login adalah wali kelas dari kelas tertentu.
-- Dipakai untuk policy khusus wali kelas (mis. input CatatanWaliKelas).
CREATE OR REPLACE FUNCTION public.is_wali_kelas_of(kelas_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM "Kelas" k
    WHERE k.id = kelas_id
      AND k."waliKelasId" = public.current_guru_id()
  );
$$;
