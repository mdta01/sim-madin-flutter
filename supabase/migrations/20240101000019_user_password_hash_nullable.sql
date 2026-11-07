-- ============================================================================
-- SIM MADIN — User.passwordHash: legacy column, boleh kosong
-- ============================================================================
-- Bug: `createUser()` di admin_desktop TIDAK pernah mengirim `passwordHash`,
-- padahal kolomnya NOT NULL tanpa DEFAULT. Akibatnya pembuatan user baru
-- SELALU gagal dengan:
--
--   null value in column "passwordHash" of relation "User"
--   violates not-null constraint
--
-- Akar masalahnya: `passwordHash` adalah sisa era Prisma + Next.js, ketika
-- password di-hash dan disimpan sendiri di tabel User. Sejak migrasi ke
-- Supabase Auth, kredensial (password, reset, MFA) dikelola sepenuhnya oleh
-- `auth.users`; tabel `User` hanya menyimpan profil + `firebaseUid` (berisi
-- Supabase Auth UID) untuk joining.
--
-- Fix: jadikan kolom nullable dan beri default string kosong untuk baris
-- lama. Kolom sengaja TIDAK dihapus supaya kode/legacy tooling yang masih
-- membacanya tidak pecah, tapi aplikasi Flutter tidak lagi bergantung padanya.
-- ============================================================================

ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;

-- Baris lama yang NULL diisi string kosong agar tooling lama tidak kaget.
UPDATE "User" SET "passwordHash" = '' WHERE "passwordHash" IS NULL;

ALTER TABLE "User" ALTER COLUMN "passwordHash" SET DEFAULT '';

COMMENT ON COLUMN "User"."passwordHash" IS
  'LEGACY / TIDAK DIPAKAI. Kredensial dikelola Supabase Auth (auth.users). '
  'Tabel User hanya menyimpan profil + firebaseUid (Supabase Auth UID).';

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Verification:
--   SELECT column_name, is_nullable, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'User' AND column_name = 'passwordHash';
-- ============================================================================
