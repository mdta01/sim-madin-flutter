-- ============================================================================
-- SIM MADIN — CEK & PERBAIKI AKUN LOGIN  (file kecil, aman ditempel dari HP)
-- ============================================================================
-- Jalankan di Supabase SQL Editor. Tidak mengubah data kecuali bagian REPAIR.
--
-- Urutan pakai:
--   1. Jalankan bagian CEK. Perhatikan kolom siap_login.
--   2. Kalau ada yang false, jalankan bagian REPAIR.
--   3. Jalankan bagian CEK lagi.
-- ============================================================================


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 1. CEK — status akun                                                 │
-- └──────────────────────────────────────────────────────────────────────────┘
SELECT * FROM public.demo_account_status();

-- Kalau fungsi di atas belum ada (berarti SETUP_ALL.sql belum dijalankan),
-- pakai query manual ini:
--
-- SELECT u.email,
--        (au.id IS NOT NULL)                                  AS ada_login,
--        (au.encrypted_password LIKE '$2%')                   AS password_bcrypt,
--        (au.email_confirmed_at IS NOT NULL)                  AS email_confirmed,
--        EXISTS (SELECT 1 FROM auth.identities i
--                WHERE i.user_id = au.id)                     AS ada_identity,
--        (SELECT string_agg(r.code, ', ')
--           FROM "UserRole" ur JOIN "Role" r ON r.id = ur."roleId"
--          WHERE ur."userId" = u.id AND ur."isActive")        AS peran
-- FROM "User" u
-- LEFT JOIN auth.users au ON lower(au.email) = lower(u.email)
-- WHERE u."deletedAt" IS NULL
-- ORDER BY u.email;


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 2. REPAIR — buat/perbaiki akun login untuk semua akun demo           │
-- └──────────────────────────────────────────────────────────────────────────┘
-- SELECT * FROM public.repair_demo_logins();


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 3. CEK LAGI                                                          │
-- └──────────────────────────────────────────────────────────────────────────┘
-- SELECT * FROM public.demo_account_status();


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 4. TELUSURI satu akun bila masih gagal                               │
-- └──────────────────────────────────────────────────────────────────────────┘
-- SELECT * FROM public.diagnose_login('mdta@madrasah.com');


-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ 5. Bila login ditolak dengan "Invalid login credentials"             │
-- └──────────────────────────────────────────────────────────────────────────┘
-- Penyebab paling sering: "Confirm email" aktif di Supabase.
-- Authentication -> Providers -> Email -> matikan "Confirm email".
--
-- Alternatif tanpa mengubah setting: fungsi repair sudah mengisi
-- email_confirmed_at, sehingga user dianggap terverifikasi.
