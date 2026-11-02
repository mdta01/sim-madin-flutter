-- ============================================================================
-- SIM MADIN — RLS Helper Functions (v2 — fix UUID vs cuid type mismatch)
-- ============================================================================
-- Catatan: Prisma User.id pakai String (cuid), tapi auth.uid() Supabase
-- return UUID. Link via User.firebaseUid = auth.uid()::text.
-- ============================================================================

-- Ambil cuid User yang sedang login (berdasarkan firebaseUid = auth.uid()).
-- Returns null kalau user tidak ditemukan.
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "User" WHERE "firebaseUid" = auth.uid()::text LIMIT 1;
$$;

-- Cek apakah user yang login punya role tertentu (active).
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
    WHERE ur."userId" = public.current_user_id()
      AND ur."isActive" = true
      AND r.code = role_code
  );
$$;

-- Cek apakah user punya salah satu dari role list.
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
    WHERE ur."userId" = public.current_user_id()
      AND ur."isActive" = true
      AND r.code = ANY(role_codes)
  );
$$;

-- Cek apakah user adalah staff madrasah (admin/kepala/guru/bendahara, bukan wali).
CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'GURU', 'BENDAHARA']);
$$;

-- Cek apakah user adalah admin-level (super_admin/admin/kepala/bendahara).
CREATE OR REPLACE FUNCTION public.is_admin_level()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'BENDAHARA']);
$$;

-- Cek apakah user adalah admin (super_admin/admin saja).
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN']);
$$;

-- Ambil Wali.id dari user yang sedang login.
CREATE OR REPLACE FUNCTION public.current_wali_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "Wali"
  WHERE "userId" = public.current_user_id()
    AND "deletedAt" IS NULL
  LIMIT 1;
$$;

-- Cek apakah santri tertentu adalah anak dari wali yang sedang login.
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

-- Ambil Guru.id dari user yang sedang login.
CREATE OR REPLACE FUNCTION public.current_guru_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "Guru"
  WHERE "userId" = public.current_user_id()
    AND "deletedAt" IS NULL
  LIMIT 1;
$$;

-- Cek apakah guru yang login mengajar kelas tertentu.
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
