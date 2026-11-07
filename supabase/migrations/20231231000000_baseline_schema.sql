-- ============================================================================
-- SIM MADIN — Baseline schema (53 tabel)
-- ============================================================================
-- AUTO-GENERATED: tool/prisma_to_ddl.py dari tool/legacy_schema.prisma
-- (schema Prisma asli proyek TS sim-madin). JANGAN edit manual — ubah
-- generator atau schema sumber lalu generate ulang:
--
--   python3 tool/prisma_to_ddl.py tool/legacy_schema.prisma \
--     > supabase/migrations/20231231000000_baseline_schema.sql
--
-- Kenapa timestamp migration ini 2023-12-31 00:00:00 (paling awal)?
--   Semua migration lain (RLS, RPC, trigger, storage, seed) bergantung pada
--   tabel-tabel ini. Tanpa baseline ini, `supabase db push` pada project baru
--   akan GAGAL karena setiap CREATE POLICY / ALTER TABLE menargetkan tabel
--   yang belum ada.
--
-- Catatan penting soal kolom timestamp:
--   Prisma mengisi createdAt/updatedAt di sisi aplikasi (bukan DEFAULT di DB),
--   jadi kolomnya NOT NULL TANPA default. Semua INSERT dari Flutter WAJIB
--   mengirim kedua kolom tersebut. Lihat `nowIso()` + helper builders di
--   `packages/api_client/lib/supabase_write.dart`.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "User" (
  "id" text NOT NULL PRIMARY KEY,
  "email" text NOT NULL UNIQUE,
  "username" text NOT NULL UNIQUE,
  "passwordHash" text NOT NULL,
  "name" text NOT NULL,
  "phone" text,
  "avatarUrl" text,
  "firebaseUid" text UNIQUE,
  "isActive" boolean NOT NULL DEFAULT true,
  "lastLoginAt" timestamp(3) with time zone,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone
);

CREATE TABLE IF NOT EXISTS "Role" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "description" text,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isSystem" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "Permission" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "module" text NOT NULL,
  "description" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "UserRole" (
  "id" text NOT NULL PRIMARY KEY,
  "userId" text NOT NULL,
  "roleId" text NOT NULL,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserRole_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UserRole_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "RolePermission" (
  "id" text NOT NULL PRIMARY KEY,
  "roleId" text NOT NULL,
  "permissionId" text NOT NULL,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "RolePermission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "RolePermission_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES "Permission"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "TahunAjaran" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "startDate" timestamp(3) with time zone NOT NULL,
  "endDate" timestamp(3) with time zone NOT NULL,
  "isActive" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "Semester" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "type" text NOT NULL,
  "startDate" timestamp(3) with time zone NOT NULL,
  "endDate" timestamp(3) with time zone NOT NULL,
  "isActive" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Semester_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Kelas" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "level" text NOT NULL,
  "description" text,
  "capacity" integer NOT NULL DEFAULT 30,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  "waliKelasId" text,
  CONSTRAINT "Kelas_waliKelasId_fkey" FOREIGN KEY ("waliKelasId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "MataPelajaran" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "category" text NOT NULL,
  "description" text,
  "kkm" double precision NOT NULL DEFAULT 70,
  "durationMnt" integer NOT NULL DEFAULT 90,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone
);

CREATE TABLE IF NOT EXISTS "Wali" (
  "id" text NOT NULL PRIMARY KEY,
  "userId" text UNIQUE,
  "name" text NOT NULL,
  "nik" text UNIQUE,
  "phone" text UNIQUE,
  "email" text,
  "occupation" text,
  "address" text,
  "relationship" text NOT NULL DEFAULT 'WALI',
  "activationStatus" text NOT NULL DEFAULT 'PENDING',
  "pinHash" text,
  "otpCode" text,
  "otpExpiresAt" timestamp(3) with time zone,
  "otpAttempts" integer NOT NULL DEFAULT 0,
  "otpRequestCount" integer NOT NULL DEFAULT 0,
  "otpRequestResetAt" timestamp(3) with time zone,
  "failedLoginAttempts" integer NOT NULL DEFAULT 0,
  "lockedUntil" timestamp(3) with time zone,
  "lastLoginAt" timestamp(3) with time zone,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Wali_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "SantriWali" (
  "id" text NOT NULL PRIMARY KEY,
  "santriId" text NOT NULL,
  "waliId" text NOT NULL,
  "relationship" text NOT NULL,
  "isPrimary" boolean NOT NULL DEFAULT false,
  "canAccess" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SantriWali_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "SantriWali_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "WaliActivation" (
  "id" text NOT NULL PRIMARY KEY,
  "waliId" text NOT NULL,
  "token" text NOT NULL UNIQUE,
  "otpCode" text NOT NULL,
  "type" text NOT NULL,
  "expiresAt" timestamp(3) with time zone NOT NULL,
  "usedAt" timestamp(3) with time zone,
  "attempts" integer NOT NULL DEFAULT 0,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "WaliActivation_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "PhoneChangeLog" (
  "id" text NOT NULL PRIMARY KEY,
  "waliId" text NOT NULL,
  "oldPhone" text,
  "newPhone" text NOT NULL,
  "changedById" text,
  "changedAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reason" text,
  CONSTRAINT "PhoneChangeLog_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "Santri" (
  "id" text NOT NULL PRIMARY KEY,
  "nis" text NOT NULL UNIQUE,
  "nisn" text UNIQUE,
  "name" text NOT NULL,
  "gender" text NOT NULL,
  "birthPlace" text,
  "birthDate" timestamp(3) with time zone,
  "address" text,
  "phone" text,
  "photoUrl" text,
  "entryDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" text NOT NULL DEFAULT 'AKTIF',
  "waliId" text,
  "kelasId" text,
  "tahunAjaranId" text,
  "userId" text UNIQUE,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Santri_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Santri_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Santri_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Santri_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Guru" (
  "id" text NOT NULL PRIMARY KEY,
  "userId" text UNIQUE,
  "nip" text UNIQUE,
  "nuptk" text UNIQUE,
  "name" text NOT NULL,
  "gender" text NOT NULL,
  "birthPlace" text,
  "birthDate" timestamp(3) with time zone,
  "address" text,
  "phone" text,
  "email" text,
  "photoUrl" text,
  "joinDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "specialization" text,
  "status" text NOT NULL DEFAULT 'AKTIF',
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Guru_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Jadwal" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "kelasId" text NOT NULL,
  "mapelId" text NOT NULL,
  "guruId" text NOT NULL,
  "dayOfWeek" integer NOT NULL,
  "startTime" text NOT NULL,
  "endTime" text NOT NULL,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Jadwal_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Jadwal_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Jadwal_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Jadwal_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Jadwal_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Absensi" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "santriId" text NOT NULL,
  "kelasId" text NOT NULL,
  "date" timestamp(3) with time zone NOT NULL,
  "status" text NOT NULL,
  "note" text,
  "recordedByGuruId" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Absensi_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Absensi_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Absensi_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Absensi_recordedByGuruId_fkey" FOREIGN KEY ("recordedByGuruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Nilai" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "kelasId" text NOT NULL,
  "mapelId" text NOT NULL,
  "guruId" text,
  "kompetensiId" text,
  "type" text NOT NULL,
  "score" double precision NOT NULL,
  "notes" text,
  "assessmentDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Nilai_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Nilai_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Nilai_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Nilai_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Nilai_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Nilai_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Nilai_kompetensiId_fkey" FOREIGN KEY ("kompetensiId") REFERENCES "Kompetensi"("id") ON DELETE SET NULL ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Rapor" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "kelasId" text NOT NULL,
  "notes" text,
  "absensiHadir" integer NOT NULL DEFAULT 0,
  "absensiSakit" integer NOT NULL DEFAULT 0,
  "absensiIzin" integer NOT NULL DEFAULT 0,
  "absensiAlfa" integer NOT NULL DEFAULT 0,
  "published" boolean NOT NULL DEFAULT false,
  "publishedAt" timestamp(3) with time zone,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Rapor_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Rapor_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Rapor_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Rapor_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "JenisTagihan" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "description" text,
  "defaultAmount" integer NOT NULL,
  "category" text NOT NULL,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "Tagihan" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "santriId" text NOT NULL,
  "kelasId" text,
  "jenisTagihanId" text NOT NULL,
  "amount" double precision NOT NULL,
  "paidAmount" double precision NOT NULL DEFAULT 0,
  "description" text,
  "dueDate" timestamp(3) with time zone,
  "status" text NOT NULL DEFAULT 'BELUM_BAYAR',
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Tagihan_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tagihan_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Tagihan_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tagihan_jenisTagihanId_fkey" FOREIGN KEY ("jenisTagihanId") REFERENCES "JenisTagihan"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Payment" (
  "id" text NOT NULL PRIMARY KEY,
  "invoiceNo" text NOT NULL UNIQUE,
  "tahunAjaranId" text,
  "tagihanId" text,
  "santriId" text,
  "amount" double precision NOT NULL,
  "paymentMethod" text NOT NULL,
  "paymentDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" text NOT NULL DEFAULT 'VERIFIED',
  "note" text,
  "proofUrl" text,
  "recordedById" text,
  "kasId" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Payment_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Payment_tagihanId_fkey" FOREIGN KEY ("tagihanId") REFERENCES "Tagihan"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Payment_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Payment_recordedById_fkey" FOREIGN KEY ("recordedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Payment_kasId_fkey" FOREIGN KEY ("kasId") REFERENCES "Kas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Announcement" (
  "id" text NOT NULL PRIMARY KEY,
  "title" text NOT NULL,
  "content" text NOT NULL,
  "audience" text NOT NULL,
  "kelasId" text,
  "priority" text NOT NULL DEFAULT 'NORMAL',
  "isPublished" boolean NOT NULL DEFAULT true,
  "publishedAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" timestamp(3) with time zone,
  "createdById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Announcement_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "AuditLog" (
  "id" text NOT NULL PRIMARY KEY,
  "userId" text,
  "action" text NOT NULL,
  "module" text NOT NULL,
  "entityId" text,
  "entityType" text,
  "changes" text,
  "ip" text,
  "userAgent" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "SystemSetting" (
  "id" text NOT NULL PRIMARY KEY,
  "key" text NOT NULL UNIQUE,
  "value" text NOT NULL,
  "type" text NOT NULL DEFAULT 'STRING',
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "updatedBy" text
);

CREATE TABLE IF NOT EXISTS "Materi" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "mapelId" text NOT NULL,
  "kelasId" text,
  "guruId" text,
  "title" text NOT NULL,
  "description" text,
  "type" text NOT NULL DEFAULT 'DOKUMEN',
  "fileUrl" text,
  "externalUrl" text,
  "pertemuan" integer,
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isPublished" boolean NOT NULL DEFAULT true,
  "publishedAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Materi_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Materi_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Materi_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Materi_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Materi_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Tugas" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "mapelId" text NOT NULL,
  "kelasId" text NOT NULL,
  "guruId" text,
  "materiId" text,
  "title" text NOT NULL,
  "description" text,
  "type" text NOT NULL DEFAULT 'INDIVIDU',
  "fileUrl" text,
  "maxScore" double precision NOT NULL DEFAULT 100,
  "dueDate" timestamp(3) with time zone NOT NULL,
  "isPublished" boolean NOT NULL DEFAULT true,
  "publishedAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Tugas_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tugas_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tugas_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tugas_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tugas_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Tugas_materiId_fkey" FOREIGN KEY ("materiId") REFERENCES "Materi"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "PengumpulanTugas" (
  "id" text NOT NULL PRIMARY KEY,
  "tugasId" text NOT NULL,
  "santriId" text NOT NULL,
  "fileUrl" text,
  "textAnswer" text,
  "submittedAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" text NOT NULL DEFAULT 'SUBMITTED',
  "score" double precision,
  "feedback" text,
  "gradedAt" timestamp(3) with time zone,
  "gradedById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "PengumpulanTugas_tugasId_fkey" FOREIGN KEY ("tugasId") REFERENCES "Tugas"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "PengumpulanTugas_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "Pertemuan" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "kelasId" text NOT NULL,
  "mapelId" text NOT NULL,
  "guruId" text,
  "pertemuanKe" integer NOT NULL,
  "date" timestamp(3) with time zone NOT NULL,
  "topic" text,
  "description" text,
  "isCompleted" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Pertemuan_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pertemuan_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pertemuan_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pertemuan_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pertemuan_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Kompetensi" (
  "id" text NOT NULL PRIMARY KEY,
  "mapelId" text NOT NULL,
  "tahunAjaranId" text NOT NULL,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "description" text,
  "category" text NOT NULL DEFAULT 'UMUM',
  "sortOrder" integer NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Kompetensi_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Kompetensi_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Ujian" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "mapelId" text NOT NULL,
  "kelasId" text NOT NULL,
  "guruId" text,
  "title" text NOT NULL,
  "type" text NOT NULL,
  "description" text,
  "startTime" timestamp(3) with time zone NOT NULL,
  "endTime" timestamp(3) with time zone NOT NULL,
  "durationMnt" integer NOT NULL DEFAULT 90,
  "ruang" text,
  "pengawas" text,
  "isPublished" boolean NOT NULL DEFAULT false,
  "maxScore" double precision NOT NULL DEFAULT 100,
  "passingScore" double precision,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  "deletedAt" timestamp(3) with time zone,
  CONSTRAINT "Ujian_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Ujian_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Ujian_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Ujian_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "Kelas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Ujian_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "BankSoal" (
  "id" text NOT NULL PRIMARY KEY,
  "mapelId" text NOT NULL,
  "tahunAjaranId" text NOT NULL,
  "guruId" text,
  "code" text NOT NULL UNIQUE,
  "type" text NOT NULL,
  "question" text NOT NULL,
  "options" text,
  "correctAnswer" text,
  "answerKey" text,
  "bobot" double precision NOT NULL DEFAULT 1,
  "difficulty" text NOT NULL DEFAULT 'SEDANG',
  "kompetensiId" text,
  "tags" text,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "BankSoal_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "BankSoal_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "BankSoal_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "BankSoal_kompetensiId_fkey" FOREIGN KEY ("kompetensiId") REFERENCES "Kompetensi"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "UjianSoal" (
  "id" text NOT NULL PRIMARY KEY,
  "ujianId" text NOT NULL,
  "bankSoalId" text NOT NULL,
  "urutan" integer NOT NULL,
  "bobot" double precision NOT NULL DEFAULT 1,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UjianSoal_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "Ujian"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UjianSoal_bankSoalId_fkey" FOREIGN KEY ("bankSoalId") REFERENCES "BankSoal"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "UjianPeserta" (
  "id" text NOT NULL PRIMARY KEY,
  "ujianId" text NOT NULL,
  "santriId" text NOT NULL,
  "ruang" text,
  "pengawas" text,
  "isHadir" boolean NOT NULL DEFAULT true,
  "catatan" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UjianPeserta_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "Ujian"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UjianPeserta_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "UjianNilai" (
  "id" text NOT NULL PRIMARY KEY,
  "ujianId" text NOT NULL,
  "santriId" text NOT NULL,
  "score" double precision NOT NULL,
  "scoreUts" double precision,
  "scoreUas" double precision,
  "scorePraktik" double precision,
  "notes" text,
  "gradedById" text,
  "gradedAt" timestamp(3) with time zone,
  "isAutoCorrect" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "UjianNilai_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "Ujian"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UjianNilai_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "RaporMapel" (
  "id" text NOT NULL PRIMARY KEY,
  "raporId" text NOT NULL,
  "mapelId" text NOT NULL,
  "nilaiAkhir" double precision NOT NULL,
  "predikat" text,
  "deskripsi" text,
  "kkm" double precision NOT NULL DEFAULT 70,
  "isTuntas" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "RaporMapel_raporId_fkey" FOREIGN KEY ("raporId") REFERENCES "Rapor"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "RaporMapel_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "MataPelajaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "RaporCatatan" (
  "id" text NOT NULL PRIMARY KEY,
  "raporId" text NOT NULL UNIQUE,
  "catatanWaliKelas" text,
  "prestasi" text,
  "akhlak" text,
  "kehadiran" text,
  "saran" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "RaporCatatan_raporId_fkey" FOREIGN KEY ("raporId") REFERENCES "Rapor"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "PerkembanganQuran" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "guruId" text,
  "type" text NOT NULL,
  "surah" text,
  "juz" integer,
  "ayatFrom" integer,
  "ayatTo" integer,
  "score" double precision,
  "status" text NOT NULL DEFAULT 'PROGRESS',
  "target" text,
  "catatan" text,
  "pertemuanDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "PerkembanganQuran_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "PerkembanganQuran_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "PerkembanganQuran_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "PerkembanganQuran_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "HafalanKitab" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "guruId" text,
  "type" text NOT NULL,
  "kitabName" text NOT NULL,
  "halaman" text,
  "score" double precision,
  "status" text NOT NULL DEFAULT 'PROGRESS',
  "target" text,
  "catatan" text,
  "pertemuanDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "HafalanKitab_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "HafalanKitab_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "HafalanKitab_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "HafalanKitab_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "AkhlakPenilaian" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "guruId" text,
  "adabGuru" double precision NOT NULL DEFAULT 0,
  "adabOrangTua" double precision NOT NULL DEFAULT 0,
  "adabTeman" double precision NOT NULL DEFAULT 0,
  "kedisiplinan" double precision NOT NULL DEFAULT 0,
  "kebersihan" double precision NOT NULL DEFAULT 0,
  "tanggungJawab" double precision NOT NULL DEFAULT 0,
  "rataRata" double precision NOT NULL DEFAULT 0,
  "predikat" text,
  "catatan" text,
  "periode" text,
  "periodeDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "AkhlakPenilaian_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "AkhlakPenilaian_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "AkhlakPenilaian_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "AkhlakPenilaian_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Pembinaan" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "guruId" text,
  "type" text NOT NULL,
  "category" text,
  "title" text NOT NULL,
  "description" text NOT NULL,
  "severity" text NOT NULL DEFAULT 'RINGAN',
  "tindakan" text,
  "status" text NOT NULL DEFAULT 'OPEN',
  "resolvedAt" timestamp(3) with time zone,
  "resolvedById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Pembinaan_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pembinaan_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "Pembinaan_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Pembinaan_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "CatatanWaliKelas" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "santriId" text NOT NULL,
  "waliKelasId" text,
  "periode" text NOT NULL,
  "periodeDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "catatan" text NOT NULL,
  "rekomendasi" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "CatatanWaliKelas_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "CatatanWaliKelas_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "CatatanWaliKelas_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "CatatanWaliKelas_waliKelasId_fkey" FOREIGN KEY ("waliKelasId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Kas" (
  "id" text NOT NULL PRIMARY KEY,
  "code" text NOT NULL UNIQUE,
  "name" text NOT NULL,
  "accountNumber" text,
  "bankName" text,
  "type" text NOT NULL,
  "balance" double precision NOT NULL DEFAULT 0,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "TransaksiKas" (
  "id" text NOT NULL PRIMARY KEY,
  "kasId" text NOT NULL,
  "tahunAjaranId" text,
  "type" text NOT NULL,
  "category" text NOT NULL,
  "amount" double precision NOT NULL,
  "description" text NOT NULL,
  "reference" text,
  "paymentId" text,
  "honorGuruId" text,
  "transaksiDate" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "recordedById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "TransaksiKas_kasId_fkey" FOREIGN KEY ("kasId") REFERENCES "Kas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "TransaksiKas_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "TransaksiKas_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "TransaksiKas_honorGuruId_fkey" FOREIGN KEY ("honorGuruId") REFERENCES "HonorGuru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "HonorGuru" (
  "id" text NOT NULL PRIMARY KEY,
  "tahunAjaranId" text NOT NULL,
  "semesterId" text NOT NULL,
  "guruId" text NOT NULL,
  "periode" text NOT NULL,
  "periodeLabel" text NOT NULL,
  "honorMengajar" double precision NOT NULL DEFAULT 0,
  "insentif" double precision NOT NULL DEFAULT 0,
  "tunjangan" double precision NOT NULL DEFAULT 0,
  "potongan" double precision NOT NULL DEFAULT 0,
  "totalHonor" double precision NOT NULL DEFAULT 0,
  "status" text NOT NULL DEFAULT 'DRAFT',
  "paidAt" timestamp(3) with time zone,
  "kasId" text,
  "catatan" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "HonorGuru_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "HonorGuru_semesterId_fkey" FOREIGN KEY ("semesterId") REFERENCES "Semester"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "HonorGuru_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "HonorGuru_kasId_fkey" FOREIGN KEY ("kasId") REFERENCES "Kas"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "UjianSesi" (
  "id" text NOT NULL PRIMARY KEY,
  "ujianId" text NOT NULL,
  "santriId" text NOT NULL,
  "startTime" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "endTime" timestamp(3) with time zone,
  "durationUsed" integer,
  "score" double precision,
  "status" text NOT NULL DEFAULT 'NOT_STARTED',
  "soalOrder" text,
  "isAutoCorrected" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "UjianSesi_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "Ujian"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UjianSesi_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "UjianJawaban" (
  "id" text NOT NULL PRIMARY KEY,
  "sesiId" text NOT NULL,
  "ujianSoalId" text NOT NULL,
  "santriId" text NOT NULL,
  "answer" text,
  "optionOrder" text,
  "isCorrect" boolean,
  "score" double precision,
  "isAutoCorrected" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "UjianJawaban_sesiId_fkey" FOREIGN KEY ("sesiId") REFERENCES "UjianSesi"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UjianJawaban_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "Notifikasi" (
  "id" text NOT NULL PRIMARY KEY,
  "waliId" text,
  "santriId" text,
  "type" text NOT NULL,
  "title" text NOT NULL,
  "message" text NOT NULL,
  "priority" text NOT NULL DEFAULT 'NORMAL',
  "isRead" boolean NOT NULL DEFAULT false,
  "readAt" timestamp(3) with time zone,
  "entityType" text,
  "entityId" text,
  "isEmailSent" boolean NOT NULL DEFAULT false,
  "isPushSent" boolean NOT NULL DEFAULT false,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Notifikasi_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Notifikasi_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "ChatRoom" (
  "id" text NOT NULL PRIMARY KEY,
  "type" text NOT NULL,
  "waliId" text,
  "guruId" text,
  "santriId" text,
  "title" text,
  "lastMessageAt" timestamp(3) with time zone,
  "lastMessage" text,
  "isActive" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "ChatRoom_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ChatRoom_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ChatRoom_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "ChatMessage" (
  "id" text NOT NULL PRIMARY KEY,
  "chatRoomId" text NOT NULL,
  "senderType" text NOT NULL,
  "senderWaliId" text,
  "senderGuruId" text,
  "senderUserId" text,
  "message" text NOT NULL,
  "attachments" text,
  "isRead" boolean NOT NULL DEFAULT false,
  "readAt" timestamp(3) with time zone,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ChatMessage_chatRoomId_fkey" FOREIGN KEY ("chatRoomId") REFERENCES "ChatRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ChatMessage_senderWaliId_fkey" FOREIGN KEY ("senderWaliId") REFERENCES "Wali"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT "ChatMessage_senderGuruId_fkey" FOREIGN KEY ("senderGuruId") REFERENCES "Guru"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "Surat" (
  "id" text NOT NULL PRIMARY KEY,
  "nomorSurat" text NOT NULL UNIQUE,
  "type" text NOT NULL,
  "title" text NOT NULL,
  "santriId" text,
  "guruId" text,
  "content" text NOT NULL,
  "periodeMulai" timestamp(3) with time zone,
  "periodeSelesai" timestamp(3) with time zone,
  "tempat" text,
  "tanggalSurat" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" text NOT NULL DEFAULT 'DRAFT',
  "signedBy" text,
  "signedAt" timestamp(3) with time zone,
  "createdById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Surat_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT "Surat_guruId_fkey" FOREIGN KEY ("guruId") REFERENCES "Guru"("id") ON DELETE SET NULL ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS "QRScan" (
  "id" text NOT NULL PRIMARY KEY,
  "qrType" text NOT NULL,
  "entityId" text NOT NULL,
  "scanType" text NOT NULL,
  "scannedById" text,
  "deviceInfo" text,
  "location" text,
  "result" text NOT NULL DEFAULT 'SUCCESS',
  "message" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Alumni" (
  "id" text NOT NULL PRIMARY KEY,
  "santriId" text NOT NULL UNIQUE,
  "tahunLulus" integer NOT NULL,
  "tahunAjaranLulusId" text,
  "statusKelulusan" text NOT NULL DEFAULT 'LULUS',
  "nilaiAkhir" double precision,
  "predikatAkhir" text,
  "syaratNilaiLengkap" boolean NOT NULL DEFAULT false,
  "syaratAbsensiCukup" boolean NOT NULL DEFAULT false,
  "syaratTagihanLunas" boolean NOT NULL DEFAULT false,
  "syaratUjianAkhir" boolean NOT NULL DEFAULT false,
  "syaratLainnya" text,
  "suratKeteranganLulus" boolean NOT NULL DEFAULT false,
  "sertifikat" boolean NOT NULL DEFAULT false,
  "piagam" boolean NOT NULL DEFAULT false,
  "beritaAcaraId" text,
  "pendidikanLanjutan" text,
  "pekerjaan" text,
  "telepon" text,
  "email" text,
  "domisiliKota" text,
  "domisiliAlamat" text,
  "aktivitasAlumni" text,
  "catatan" text,
  "tanggalLulus" timestamp(3) with time zone,
  "createdById" text,
  "createdAt" timestamp(3) with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp(3) with time zone NOT NULL,
  CONSTRAINT "Alumni_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "Santri"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Alumni_tahunAjaranLulusId_fkey" FOREIGN KEY ("tahunAjaranLulusId") REFERENCES "TahunAjaran"("id") ON DELETE RESTRICT ON UPDATE RESTRICT
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS "User_isActive_idx" ON "User" ("isActive");
CREATE INDEX IF NOT EXISTS "User_deletedAt_idx" ON "User" ("deletedAt");
CREATE UNIQUE INDEX IF NOT EXISTS "UserRole_userId_roleId_key" ON "UserRole" ("userId", "roleId");
CREATE INDEX IF NOT EXISTS "UserRole_userId_idx" ON "UserRole" ("userId");
CREATE INDEX IF NOT EXISTS "UserRole_roleId_idx" ON "UserRole" ("roleId");
CREATE UNIQUE INDEX IF NOT EXISTS "RolePermission_roleId_permissionId_key" ON "RolePermission" ("roleId", "permissionId");
CREATE INDEX IF NOT EXISTS "RolePermission_roleId_idx" ON "RolePermission" ("roleId");
CREATE INDEX IF NOT EXISTS "RolePermission_permissionId_idx" ON "RolePermission" ("permissionId");
CREATE INDEX IF NOT EXISTS "Semester_tahunAjaranId_idx" ON "Semester" ("tahunAjaranId");
CREATE INDEX IF NOT EXISTS "Kelas_level_idx" ON "Kelas" ("level");
CREATE INDEX IF NOT EXISTS "Kelas_isActive_idx" ON "Kelas" ("isActive");
CREATE INDEX IF NOT EXISTS "Kelas_deletedAt_idx" ON "Kelas" ("deletedAt");
CREATE INDEX IF NOT EXISTS "MataPelajaran_category_idx" ON "MataPelajaran" ("category");
CREATE INDEX IF NOT EXISTS "MataPelajaran_isActive_idx" ON "MataPelajaran" ("isActive");
CREATE INDEX IF NOT EXISTS "MataPelajaran_deletedAt_idx" ON "MataPelajaran" ("deletedAt");
CREATE INDEX IF NOT EXISTS "Wali_phone_idx" ON "Wali" ("phone");
CREATE INDEX IF NOT EXISTS "Wali_activationStatus_idx" ON "Wali" ("activationStatus");
CREATE INDEX IF NOT EXISTS "Wali_deletedAt_idx" ON "Wali" ("deletedAt");
CREATE UNIQUE INDEX IF NOT EXISTS "SantriWali_santriId_waliId_key" ON "SantriWali" ("santriId", "waliId");
CREATE INDEX IF NOT EXISTS "SantriWali_waliId_idx" ON "SantriWali" ("waliId");
CREATE INDEX IF NOT EXISTS "SantriWali_santriId_isPrimary_idx" ON "SantriWali" ("santriId", "isPrimary");
CREATE INDEX IF NOT EXISTS "WaliActivation_waliId_idx" ON "WaliActivation" ("waliId");
CREATE INDEX IF NOT EXISTS "WaliActivation_token_idx" ON "WaliActivation" ("token");
CREATE INDEX IF NOT EXISTS "WaliActivation_type_expiresAt_idx" ON "WaliActivation" ("type", "expiresAt");
CREATE INDEX IF NOT EXISTS "PhoneChangeLog_waliId_idx" ON "PhoneChangeLog" ("waliId");
CREATE INDEX IF NOT EXISTS "Santri_kelasId_idx" ON "Santri" ("kelasId");
CREATE INDEX IF NOT EXISTS "Santri_waliId_idx" ON "Santri" ("waliId");
CREATE INDEX IF NOT EXISTS "Santri_status_idx" ON "Santri" ("status");
CREATE INDEX IF NOT EXISTS "Santri_deletedAt_idx" ON "Santri" ("deletedAt");
CREATE INDEX IF NOT EXISTS "Guru_status_idx" ON "Guru" ("status");
CREATE INDEX IF NOT EXISTS "Guru_deletedAt_idx" ON "Guru" ("deletedAt");
CREATE UNIQUE INDEX IF NOT EXISTS "Jadwal_kelasId_mapelId_dayOfWeek_startTime_tahunAjaranId_semesterId_key" ON "Jadwal" ("kelasId", "mapelId", "dayOfWeek", "startTime", "tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Jadwal_kelasId_dayOfWeek_idx" ON "Jadwal" ("kelasId", "dayOfWeek");
CREATE INDEX IF NOT EXISTS "Jadwal_guruId_dayOfWeek_idx" ON "Jadwal" ("guruId", "dayOfWeek");
CREATE UNIQUE INDEX IF NOT EXISTS "Absensi_santriId_date_tahunAjaranId_key" ON "Absensi" ("santriId", "date", "tahunAjaranId");
CREATE INDEX IF NOT EXISTS "Absensi_kelasId_date_idx" ON "Absensi" ("kelasId", "date");
CREATE INDEX IF NOT EXISTS "Absensi_santriId_date_idx" ON "Absensi" ("santriId", "date");
CREATE INDEX IF NOT EXISTS "Absensi_status_date_idx" ON "Absensi" ("status", "date");
CREATE UNIQUE INDEX IF NOT EXISTS "Nilai_santriId_mapelId_type_semesterId_tahunAjaranId_key" ON "Nilai" ("santriId", "mapelId", "type", "semesterId", "tahunAjaranId");
CREATE INDEX IF NOT EXISTS "Nilai_kelasId_mapelId_type_idx" ON "Nilai" ("kelasId", "mapelId", "type");
CREATE INDEX IF NOT EXISTS "Nilai_santriId_semesterId_idx" ON "Nilai" ("santriId", "semesterId");
CREATE INDEX IF NOT EXISTS "Nilai_kompetensiId_idx" ON "Nilai" ("kompetensiId");
CREATE UNIQUE INDEX IF NOT EXISTS "Rapor_santriId_semesterId_tahunAjaranId_key" ON "Rapor" ("santriId", "semesterId", "tahunAjaranId");
CREATE INDEX IF NOT EXISTS "Rapor_kelasId_semesterId_idx" ON "Rapor" ("kelasId", "semesterId");
CREATE INDEX IF NOT EXISTS "Tagihan_santriId_status_idx" ON "Tagihan" ("santriId", "status");
CREATE INDEX IF NOT EXISTS "Tagihan_tahunAjaranId_status_idx" ON "Tagihan" ("tahunAjaranId", "status");
CREATE INDEX IF NOT EXISTS "Tagihan_dueDate_idx" ON "Tagihan" ("dueDate");
CREATE INDEX IF NOT EXISTS "Payment_santriId_paymentDate_idx" ON "Payment" ("santriId", "paymentDate");
CREATE INDEX IF NOT EXISTS "Payment_status_paymentDate_idx" ON "Payment" ("status", "paymentDate");
CREATE INDEX IF NOT EXISTS "Payment_tagihanId_idx" ON "Payment" ("tagihanId");
CREATE INDEX IF NOT EXISTS "Announcement_isPublished_publishedAt_idx" ON "Announcement" ("isPublished", "publishedAt");
CREATE INDEX IF NOT EXISTS "Announcement_audience_idx" ON "Announcement" ("audience");
CREATE INDEX IF NOT EXISTS "AuditLog_userId_createdAt_idx" ON "AuditLog" ("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "AuditLog_module_action_createdAt_idx" ON "AuditLog" ("module", "action", "createdAt");
CREATE INDEX IF NOT EXISTS "Materi_mapelId_kelasId_idx" ON "Materi" ("mapelId", "kelasId");
CREATE INDEX IF NOT EXISTS "Materi_tahunAjaranId_semesterId_idx" ON "Materi" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Materi_deletedAt_idx" ON "Materi" ("deletedAt");
CREATE INDEX IF NOT EXISTS "Tugas_kelasId_mapelId_idx" ON "Tugas" ("kelasId", "mapelId");
CREATE INDEX IF NOT EXISTS "Tugas_dueDate_idx" ON "Tugas" ("dueDate");
CREATE INDEX IF NOT EXISTS "Tugas_deletedAt_idx" ON "Tugas" ("deletedAt");
CREATE UNIQUE INDEX IF NOT EXISTS "PengumpulanTugas_tugasId_santriId_key" ON "PengumpulanTugas" ("tugasId", "santriId");
CREATE INDEX IF NOT EXISTS "PengumpulanTugas_santriId_idx" ON "PengumpulanTugas" ("santriId");
CREATE INDEX IF NOT EXISTS "PengumpulanTugas_status_idx" ON "PengumpulanTugas" ("status");
CREATE UNIQUE INDEX IF NOT EXISTS "Pertemuan_kelasId_mapelId_pertemuanKe_tahunAjaranId_semesterId_key" ON "Pertemuan" ("kelasId", "mapelId", "pertemuanKe", "tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Pertemuan_kelasId_date_idx" ON "Pertemuan" ("kelasId", "date");
CREATE INDEX IF NOT EXISTS "Kompetensi_mapelId_idx" ON "Kompetensi" ("mapelId");
CREATE INDEX IF NOT EXISTS "Kompetensi_category_idx" ON "Kompetensi" ("category");
CREATE INDEX IF NOT EXISTS "Ujian_tahunAjaranId_semesterId_idx" ON "Ujian" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Ujian_kelasId_mapelId_idx" ON "Ujian" ("kelasId", "mapelId");
CREATE INDEX IF NOT EXISTS "Ujian_type_startTime_idx" ON "Ujian" ("type", "startTime");
CREATE INDEX IF NOT EXISTS "Ujian_deletedAt_idx" ON "Ujian" ("deletedAt");
CREATE INDEX IF NOT EXISTS "BankSoal_mapelId_type_idx" ON "BankSoal" ("mapelId", "type");
CREATE INDEX IF NOT EXISTS "BankSoal_difficulty_idx" ON "BankSoal" ("difficulty");
CREATE INDEX IF NOT EXISTS "BankSoal_kompetensiId_idx" ON "BankSoal" ("kompetensiId");
CREATE UNIQUE INDEX IF NOT EXISTS "UjianSoal_ujianId_bankSoalId_key" ON "UjianSoal" ("ujianId", "bankSoalId");
CREATE INDEX IF NOT EXISTS "UjianSoal_ujianId_urutan_idx" ON "UjianSoal" ("ujianId", "urutan");
CREATE UNIQUE INDEX IF NOT EXISTS "UjianPeserta_ujianId_santriId_key" ON "UjianPeserta" ("ujianId", "santriId");
CREATE INDEX IF NOT EXISTS "UjianPeserta_santriId_idx" ON "UjianPeserta" ("santriId");
CREATE UNIQUE INDEX IF NOT EXISTS "UjianNilai_ujianId_santriId_key" ON "UjianNilai" ("ujianId", "santriId");
CREATE INDEX IF NOT EXISTS "UjianNilai_santriId_idx" ON "UjianNilai" ("santriId");
CREATE UNIQUE INDEX IF NOT EXISTS "RaporMapel_raporId_mapelId_key" ON "RaporMapel" ("raporId", "mapelId");
CREATE INDEX IF NOT EXISTS "RaporMapel_mapelId_idx" ON "RaporMapel" ("mapelId");
CREATE INDEX IF NOT EXISTS "PerkembanganQuran_santriId_type_idx" ON "PerkembanganQuran" ("santriId", "type");
CREATE INDEX IF NOT EXISTS "PerkembanganQuran_tahunAjaranId_semesterId_idx" ON "PerkembanganQuran" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "PerkembanganQuran_status_idx" ON "PerkembanganQuran" ("status");
CREATE INDEX IF NOT EXISTS "HafalanKitab_santriId_type_idx" ON "HafalanKitab" ("santriId", "type");
CREATE INDEX IF NOT EXISTS "HafalanKitab_tahunAjaranId_semesterId_idx" ON "HafalanKitab" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "AkhlakPenilaian_santriId_periodeDate_idx" ON "AkhlakPenilaian" ("santriId", "periodeDate");
CREATE INDEX IF NOT EXISTS "AkhlakPenilaian_tahunAjaranId_semesterId_idx" ON "AkhlakPenilaian" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Pembinaan_santriId_type_idx" ON "Pembinaan" ("santriId", "type");
CREATE INDEX IF NOT EXISTS "Pembinaan_tahunAjaranId_semesterId_idx" ON "Pembinaan" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Pembinaan_status_idx" ON "Pembinaan" ("status");
CREATE INDEX IF NOT EXISTS "Pembinaan_severity_idx" ON "Pembinaan" ("severity");
CREATE INDEX IF NOT EXISTS "CatatanWaliKelas_santriId_periodeDate_idx" ON "CatatanWaliKelas" ("santriId", "periodeDate");
CREATE INDEX IF NOT EXISTS "CatatanWaliKelas_tahunAjaranId_semesterId_idx" ON "CatatanWaliKelas" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "Kas_isActive_idx" ON "Kas" ("isActive");
CREATE INDEX IF NOT EXISTS "TransaksiKas_kasId_transaksiDate_idx" ON "TransaksiKas" ("kasId", "transaksiDate");
CREATE INDEX IF NOT EXISTS "TransaksiKas_type_category_idx" ON "TransaksiKas" ("type", "category");
CREATE INDEX IF NOT EXISTS "TransaksiKas_transaksiDate_idx" ON "TransaksiKas" ("transaksiDate");
CREATE UNIQUE INDEX IF NOT EXISTS "HonorGuru_guruId_periode_key" ON "HonorGuru" ("guruId", "periode");
CREATE INDEX IF NOT EXISTS "HonorGuru_tahunAjaranId_semesterId_idx" ON "HonorGuru" ("tahunAjaranId", "semesterId");
CREATE INDEX IF NOT EXISTS "HonorGuru_status_idx" ON "HonorGuru" ("status");
CREATE UNIQUE INDEX IF NOT EXISTS "UjianSesi_ujianId_santriId_key" ON "UjianSesi" ("ujianId", "santriId");
CREATE INDEX IF NOT EXISTS "UjianSesi_santriId_idx" ON "UjianSesi" ("santriId");
CREATE INDEX IF NOT EXISTS "UjianSesi_status_idx" ON "UjianSesi" ("status");
CREATE UNIQUE INDEX IF NOT EXISTS "UjianJawaban_sesiId_ujianSoalId_key" ON "UjianJawaban" ("sesiId", "ujianSoalId");
CREATE INDEX IF NOT EXISTS "UjianJawaban_santriId_idx" ON "UjianJawaban" ("santriId");
CREATE INDEX IF NOT EXISTS "Notifikasi_waliId_isRead_idx" ON "Notifikasi" ("waliId", "isRead");
CREATE INDEX IF NOT EXISTS "Notifikasi_type_createdAt_idx" ON "Notifikasi" ("type", "createdAt");
CREATE INDEX IF NOT EXISTS "Notifikasi_createdAt_idx" ON "Notifikasi" ("createdAt");
CREATE INDEX IF NOT EXISTS "ChatRoom_waliId_isActive_idx" ON "ChatRoom" ("waliId", "isActive");
CREATE INDEX IF NOT EXISTS "ChatRoom_guruId_isActive_idx" ON "ChatRoom" ("guruId", "isActive");
CREATE INDEX IF NOT EXISTS "ChatMessage_chatRoomId_createdAt_idx" ON "ChatMessage" ("chatRoomId", "createdAt");
CREATE INDEX IF NOT EXISTS "ChatMessage_senderType_isRead_idx" ON "ChatMessage" ("senderType", "isRead");
CREATE INDEX IF NOT EXISTS "Surat_type_status_idx" ON "Surat" ("type", "status");
CREATE INDEX IF NOT EXISTS "Surat_santriId_idx" ON "Surat" ("santriId");
CREATE INDEX IF NOT EXISTS "Surat_tanggalSurat_idx" ON "Surat" ("tanggalSurat");
CREATE INDEX IF NOT EXISTS "QRScan_qrType_entityId_idx" ON "QRScan" ("qrType", "entityId");
CREATE INDEX IF NOT EXISTS "QRScan_scanType_createdAt_idx" ON "QRScan" ("scanType", "createdAt");
CREATE INDEX IF NOT EXISTS "QRScan_createdAt_idx" ON "QRScan" ("createdAt");
CREATE INDEX IF NOT EXISTS "Alumni_tahunLulus_idx" ON "Alumni" ("tahunLulus");
CREATE INDEX IF NOT EXISTS "Alumni_statusKelulusan_idx" ON "Alumni" ("statusKelulusan");
