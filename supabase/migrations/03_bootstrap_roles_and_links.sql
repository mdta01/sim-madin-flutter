-- ============================================================================
-- SIM MADIN — Bootstrap Roles + UserRole links
-- ============================================================================
-- Jalankan SQL ini SETELAH file 00/01/02 RLS migrations, di Supabase Dashboard
-- SQL Editor (yang punya akses penuh/service_role context).
--
-- Fungsi:
--   1. Insert 6 role codes kalau belum ada (idempotent via ON CONFLICT)
--   2. Untuk setiap user Supabase Auth yang terdaftar, link ke Role sesuai
--      email mapping (admin@→SUPER_ADMIN, bendahara@→BENDAHARA, dll).
--   3. Pastikan User.firebaseUid = auth.users.id (link Supabase Auth UID).
--
-- Prasyarat:
--   - Tabel User, Role, UserRole sudah ada di schema
--   - User sudah ada di Supabase Auth (sudah signup/seeded)
--   - User record sudah ada di tabel User (kalau belum, script ini auto-create)
--
-- Catatan: Jalankan dengan service_role key atau di SQL Editor Dashboard.
-- Kalau di-run via anon key + RLS enabled, akan fail karena belum punya role.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Insert 6 role codes (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO "Role" (id, code, name, description, "sortOrder", "createdAt")
SELECT
  gen_random_uuid(),
  r.code,
  r.name,
  r.desc,
  r.sort_order,
  now()
FROM (VALUES
  ('SUPER_ADMIN', 'Super Admin',         'Akses penuh mengelola seluruh sistem', 1),
  ('ADMIN',       'Admin',               'Manajemen harian sistem',              2),
  ('KEPALA',      'Kepala Madrasah',     'Monitoring & pengambilan keputusan',  3),
  ('BENDAHARA',   'Bendahara',           'Pengelolaan keuangan madrasah',       4),
  ('GURU',        'Guru',                'Input absensi, nilai, dan catatan',   5),
  ('WALI',        'Wali Santri',         'Memantau perkembangan & administrasi anak', 6)
) AS r(code, name, desc, sort_order)
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Sync User.firebaseUid = auth.users.id (kalau ada mismatch)
-- ---------------------------------------------------------------------------
UPDATE "User" u
SET "firebaseUid" = au.id,
    "updatedAt" = now()
FROM auth.users au
WHERE u.email = au.email
  AND (u."firebaseUid" IS DISTINCT FROM au.id);

-- ---------------------------------------------------------------------------
-- 3. Auto-create User record untuk akun Supabase Auth yang belum ada di
--    tabel User (kalau ada). Pakai user_metadata.name kalau ada.
-- ---------------------------------------------------------------------------
INSERT INTO "User" (id, email, username, name, "firebaseUid", "isActive", "createdAt", "updatedAt")
SELECT
  au.id,
  au.email,
  split_part(au.email, '@', 1), -- username = bagian sebelum @
  COALESCE(au.raw_user_meta_data->>'name', split_part(au.email, '@', 1)),
  au.id, -- firebaseUid = auth.users.id
  true,
  now(),
  now()
FROM auth.users au
LEFT JOIN "User" u ON u.email = au.email
WHERE u.id IS NULL;

-- ---------------------------------------------------------------------------
-- 4. Link setiap user ke role sesuai email mapping (idempotent)
-- ---------------------------------------------------------------------------
-- Mapping:
--   admin@madrasah.test      → SUPER_ADMIN
--   kepala@madrasah.test     → KEPALA
--   bendahara@madrasah.test  → BENDAHARA
--   guru@madrasah.test       → GURU
--   wali@madrasah.test       → WALI
--   *.test (lainnya)        → WALI (default untuk testing)
-- Kalau di production, sesuaikan mapping atau assign manual via admin UI.

INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
SELECT
  gen_random_uuid(),
  u.id,
  r.id,
  true,
  now()
FROM "User" u
JOIN "Role" r ON (
  (u.email = 'admin@madrasah.test'      AND r.code = 'SUPER_ADMIN')
  OR (u.email = 'kepala@madrasah.test'  AND r.code = 'KEPALA')
  OR (u.email = 'bendahara@madrasah.test' AND r.code = 'BENDAHARA')
  OR (u.email = 'guru@madrasah.test'     AND r.code = 'GURU')
  OR (u.email = 'wali@madrasah.test'     AND r.code = 'WALI')
)
ON CONFLICT ("userId", "roleId") DO UPDATE
SET "isActive" = true, "updatedAt" = now();

-- ---------------------------------------------------------------------------
-- 5. Cleanup: nonaktifkan UserRole yang tidak match mapping baru
--    (opsional — kalau ada user yang sebelumnya punya role salah)
-- ---------------------------------------------------------------------------
-- UPDATE "UserRole" SET "isActive" = false
-- WHERE "userId" || ':' || "roleId" NOT IN (
--   SELECT u.id || ':' || r.id
--   FROM "User" u
--   JOIN "Role" r ON (
--     (u.email = 'admin@madrasah.test'      AND r.code = 'SUPER_ADMIN')
--     OR (u.email = 'kepala@madrasah.test'  AND r.code = 'KEPALA')
--     OR (u.email = 'bendahara@madrasah.test' AND r.code = 'BENDAHARA')
--     OR (u.email = 'guru@madrasah.test'     AND r.code = 'GURU')
--     OR (u.email = 'wali@madrasah.test'     AND r.code = 'WALI')
--   )
-- );

COMMIT;

-- ---------------------------------------------------------------------------
-- 6. Verification query (jalankan terpisah untuk cek hasil)
-- ---------------------------------------------------------------------------
SELECT
  u.email,
  u.name,
  u."firebaseUid" IS NOT NULL AS has_auth_uid,
  array_agg(r.code ORDER BY r."sortOrder") AS roles
FROM "User" u
LEFT JOIN "UserRole" ur ON ur."userId" = u.id AND ur."isActive" = true
LEFT JOIN "Role" r ON r.id = ur."roleId"
GROUP BY u.email, u.name, u."firebaseUid"
ORDER BY u.email;

-- Expected output:
--   admin@madrasah.test       | Administrator Sistem | t | {SUPER_ADMIN}
--   bendahara@madrasah.test   | Bendahara Madrasah  | t | {BENDAHARA}
--   kepala@madrasah.test      | Kepala Madrasah     | t | {KEPALA}
--   guru@madrasah.test        | Ustadz Ahmad Fauzi  | t | {GURU}
--   wali@madrasah.test        | Bapak H. Abdullah   | t | {WALI}
