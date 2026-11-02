# SIM MADIN — Supabase RLS Migrations

> **Row Level Security** policies untuk semua tabel aplikasi Flutter.
> Production-ready, role-based, dengan helper functions.

## File urutan eksekusi

| # | File | Deskripsi |
|---|------|-----------|
| 0 | `00_rls_helper_functions.sql` | Helper Postgres functions (`has_role`, `is_staff`, `is_admin_level`, `is_wali_of_santri`, dll) |
| 1 | `01_rls_policies_phase23.sql` | Policies untuk tabel Phase 2 + 3 (mobile_kepala + mobile_bendahara): User, Role, Santri, Absensi, Nilai, Tagihan, Payment, Kas, TransaksiKas, HonorGuru, reference data |
| 2 | `02_rls_policies_phase45.sql` | Policies untuk tabel Phase 4 + 5 (mobile_guru + mobile_wali): Materi, Tugas, Ujian, Rapor, Perkembangan, Chat, Notifikasi, Surat, Alumni |

## Cara eksekusi

### Opsi A: Via Supabase Dashboard (rekomendasi untuk testing cepat)

1. Buka [Supabase Dashboard](https://supabase.com/dashboard/project/ooglxextkliuhpequwme/sql/new)
2. Login dengan akun Supabase Anda
3. Pilih project `ooglxextkliuhpequwme`
4. Buka **SQL Editor** → New query
5. Copy-paste isi `00_rls_helper_functions.sql` → Run
6. Copy-paste isi `01_rls_policies_phase23.sql` → Run
7. Copy-paste isi `02_rls_policies_phase45.sql` → Run

### Opsi B: Via `supabase` CLI

```bash
# Install supabase CLI (sekali saja)
brew install supabase/tap/supabase

# Login + link project
supabase login
supabase link --project-ref ooglxextkliuhpequwme

# Apply migrations
supabase db push
```

## Role matrix

| Role | Code | Akses |
|------|------|-------|
| Super Admin | `SUPER_ADMIN` | Full access (CRUD all) |
| Admin | `ADMIN` | Full access (CRUD all) |
| Kepala | `KEPALA` | Read-only (CRUD denied) |
| Bendahara | `BENDAHARA` | Read-mostly + write keuangan (Payment, Tagihan, Kas, HonorGuru) |
| Guru | `GURU` | Read-mostly + write akademik untuk kelas yang diajar |
| Wali | `WALI` | Read-only data anaknya sendiri (via SantriWali link) |

## Helper functions

| Function | Returns | Description |
|----------|---------|-------------|
| `has_role(role_code TEXT)` | BOOLEAN | Cek user login punya role tertentu |
| `has_any_role(role_codes TEXT[])` | BOOLEAN | Cek user punya salah satu dari role list |
| `is_staff()` | BOOLEAN | User = admin/kepala/guru/bendahara (bukan wali) |
| `is_admin_level()` | BOOLEAN | User = super_admin/admin/kepala/bendahara |
| `is_admin()` | BOOLEAN | User = super_admin/admin saja |
| `current_wali_id()` | TEXT | ID Wali yang sedang login (null kalau bukan wali) |
| `current_guru_id()` | TEXT | ID Guru yang sedang login (null kalau bukan guru) |
| `is_wali_of_santri(santri_id TEXT)` | BOOLEAN | Wali yang login adalah wali dari santri ini |
| `is_guru_of_kelas(kelas_id TEXT)` | BOOLEAN | Guru yang login mengajar kelas ini (ada di Jadwal) |
| `is_wali_kelas_of(kelas_id TEXT)` | BOOLEAN | Guru yang login adalah wali kelas ini |

## Prasyarat

Sebelum menjalankan RLS migrations, pastikan:

1. **Tabel Role sudah ter-seed** dengan role codes:
   - `SUPER_ADMIN`, `ADMIN`, `KEPALA`, `BENDAHARA`, `GURU`, `WALI`
   
   Cek via Supabase Dashboard → Table Editor → `Role` table.
   Kalau belum ada, jalankan SQL ini dulu:
   ```sql
   INSERT INTO "Role" (id, code, name, description, "sortOrder", "isSystem", "createdAt")
   VALUES
     (gen_random_uuid(), 'SUPER_ADMIN', 'Super Admin', 'Akses penuh', 1, true, now()),
     (gen_random_uuid(), 'ADMIN', 'Admin', 'Manajemen harian', 2, true, now()),
     (gen_random_uuid(), 'KEPALA', 'Kepala Madrasah', 'Monitoring', 3, true, now()),
     (gen_random_uuid(), 'BENDAHARA', 'Bendahara', 'Keuangan', 4, true, now()),
     (gen_random_uuid(), 'GURU', 'Guru', 'Akademik', 5, true, now()),
     (gen_random_uuid(), 'WALI', 'Wali Santri', 'Memantau anak', 6, true, now())
   ON CONFLICT (code) DO NOTHING;
   ```
   Catatan: kalau `isSystem` column tidak ada di schema Anda, hapus field itu.

2. **Tabel UserRole sudah ter-seed** dengan link user → role:
   ```sql
   -- Untuk setiap user Supabase Auth, link ke role yang sesuai
   INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
   SELECT
     gen_random_uuid(),
     u.id,
     r.id,
     true,
     now()
   FROM "User" u, "Role" r
   WHERE u.email = 'admin@madrasah.test' AND r.code = 'SUPER_ADMIN';
   
   -- Ulangi untuk user lain (ganti email + role code)
   INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
   SELECT gen_random_uuid(), u.id, r.id, true, now()
   FROM "User" u, "Role" r
   WHERE u.email = 'bendahara@madrasah.test' AND r.code = 'BENDAHARA';
   ```

3. **User di tabel User** punya `firebaseUid` yang sama dengan `auth.uid()` Supabase Auth.
   Cek via:
   ```sql
   SELECT u.email, u."firebaseUid", au.id AS auth_uid
   FROM "User" u
   JOIN auth.users au ON au.email = u.email;
   -- Kalau firebaseUid ≠ auth.users.id → UPDATE "User" SET "firebaseUid" = au.id
   ```
   Catatan: di schema TS lama, kolomnya `firebaseUid` padahal isinya sekarang Supabase Auth UID (lihat comment di Prisma schema). Helper function `current_wali_id()` dan `current_guru_id()` pakai `WHERE "userId" = auth.uid()`, jadi pastikan `User.firebaseUid = auth.uid()` ATAU `Wali.userId = auth.uid()` / `Guru.userId = auth.uid()`.

## Verification

Setelah eksekusi 3 file SQL, test dengan:

```bash
# Login sebagai bendahara
TOKEN=$(curl -s 'https://ooglxextkliuhpequwme.supabase.co/auth/v1/token?grant_type=password' \
  -H 'apikey: ANON_KEY' -H 'Content-Type: application/json' \
  -d '{"email":"bendahara@madrasah.test","password":"admin123"}' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

# Query Santri — harusnya return data (kalau RLS sudah di-enable dengan policy staff_read)
curl -s "https://ooglxextkliuhpequwme.supabase.co/rest/v1/Santri?select=name,nis&limit=3" \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer $TOKEN"
# Expected: HTTP 200 + JSON array of santri

# Insert Payment — harusnya sukses (bendahara punya is_admin_level())
curl -s -X POST "https://ooglxextkliuhpequwme.supabase.co/rest/v1/Payment" \
  -H "apikey: ANON_KEY" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"santriId":"SANTRI_ID","amount":50000,"paymentMethod":"TUNAI","paymentDate":"2026-11-02T10:00:00Z","status":"PENDING","invoiceNo":"INV-TEST-001"}'
# Expected: HTTP 201 + JSON record
```

Kalau masih 403, kemungkinan penyebabnya:
1. UserRole record belum ada untuk user yang login → jalankan SQL insert UserRole di atas
2. `User.firebaseUid` ≠ `auth.uid()` → UPDATE manual
3. Helper function gagal karena Security Definer search_path issue → cek function definition

## Rollback

Untuk disable RLS (emergency only, bukan untuk production):

```sql
-- Disable RLS untuk semua tabel (development only)
DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename IN (
        'User', 'Role', 'Permission', 'UserRole', 'RolePermission',
        'TahunAjaran', 'Semester', 'Kelas', 'MataPelajaran', 'Jadwal',
        'JenisTagihan', 'Santri', 'Wali', 'SantriWali', 'WaliActivation',
        'PhoneChangeLog', 'Guru', 'Absensi', 'Nilai', 'Rapor',
        'Tagihan', 'Payment', 'Announcement', 'AuditLog', 'SystemSetting',
        'Materi', 'Tugas', 'PengumpulanTugas', 'Pertemuan', 'Kompetensi',
        'Ujian', 'BankSoal', 'UjianSoal', 'UjianPeserta', 'UjianNilai',
        'RaporMapel', 'RaporCatatan', 'PerkembanganQuran', 'HafalanKitab',
        'AkhlakPenilaian', 'Pembinaan', 'CatatanWaliKelas', 'Kas',
        'TransaksiKas', 'HonorGuru', 'UjianSesi', 'UjianJawaban',
        'Notifikasi', 'ChatRoom', 'ChatMessage', 'Surat', 'QRScan', 'Alumni'
      )
  LOOP
    EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- Drop semua policies (cleanup kalau perlu recreate)
DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'policy_' || t, t);
  END LOOP;
END $$;

-- Drop helper functions
DROP FUNCTION IF EXISTS public.has_role(TEXT);
DROP FUNCTION IF EXISTS public.has_any_role(TEXT[]);
DROP FUNCTION IF EXISTS public.is_staff();
DROP FUNCTION IF EXISTS public.is_admin_level();
DROP FUNCTION IF EXISTS public.is_admin();
DROP FUNCTION IF EXISTS public.current_wali_id();
DROP FUNCTION IF EXISTS public.current_guru_id();
DROP FUNCTION IF EXISTS public.is_wali_of_santri(TEXT);
DROP FUNCTION IF EXISTS public.is_guru_of_kelas(TEXT);
DROP FUNCTION IF EXISTS public.is_wali_kelas_of(TEXT);
```
