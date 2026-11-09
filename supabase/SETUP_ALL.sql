-- ============================================================================
-- SIM MADIN — SETUP DATABASE LENGKAP (SATU FILE)
-- ============================================================================
-- Dibuat otomatis oleh tool/build_setup_sql.py — JANGAN diedit manual.
--
-- CARA PAKAI
-- ----------------------------------------------------------------------------
--   1. Buka Supabase Dashboard -> SQL Editor -> New query
--   2. Buka file ini, salin SELURUH isinya, tempel, lalu klik Run
--   3. Setelah selesai, jalankan bagian DATA DEMO di paling bawah
--      (hapus tanda komentar '--' pada baris SELECT)
--
-- CATATAN
-- ----------------------------------------------------------------------------
--   * Seluruh perintah bersifat idempotent (aman dijalankan berulang).
--   * Bagian yang menyentuh schema `auth` hanya berhasil bila dijalankan
--     sebagai pemilik database — SQL Editor Supabase memenuhi syarat itu.
--   * Setelah selesai, verifikasi dengan file terpisah:
--         docs/sql/cek_login.sql  (kecil, untuk troubleshooting)
--
-- ISI: 34 file migrasi
-- ============================================================================


-- ==========================================================================
-- FILE: 20231231000000_baseline_schema.sql
-- ==========================================================================


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

-- ==========================================================================
-- FILE: 20240101000000_rls_helper_functions.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM "User" WHERE "firebaseUid" = auth.uid()::text LIMIT 1;
$$;

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

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'GURU', 'BENDAHARA']);
$$;

CREATE OR REPLACE FUNCTION public.is_admin_level()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN', 'KEPALA', 'BENDAHARA']);
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.has_any_role(ARRAY['SUPER_ADMIN', 'ADMIN']);
$$;

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

-- ==========================================================================
-- FILE: 20240101000001_rls_policies_phase23.sql
-- ==========================================================================


ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_self_read" ON "User"
  FOR SELECT TO authenticated USING (id = public.current_user_id());
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
  FOR SELECT TO authenticated USING ("userId" = public.current_user_id());
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

-- ==========================================================================
-- FILE: 20240101000002_rls_policies_phase45.sql
-- ==========================================================================


ALTER TABLE "Materi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "materi_staff_read" ON "Materi"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "materi_wali_read" ON "Materi"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Materi"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "materi_guru_write" ON "Materi"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "Pertemuan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pertemuan_staff_read" ON "Pertemuan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pertemuan_wali_read" ON "Pertemuan"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Pertemuan"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "pertemuan_guru_write" ON "Pertemuan"
  FOR ALL TO authenticated
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

ALTER TABLE "Tugas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tugas_staff_read" ON "Tugas"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "tugas_wali_read" ON "Tugas"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Santri" s
      JOIN "SantriWali" sw ON sw."santriId" = s.id
      WHERE s."kelasId" = "Tugas"."kelasId"
        AND sw."waliId" = public.current_wali_id()
        AND sw."canAccess" = true
    )
  );
CREATE POLICY "tugas_guru_write" ON "Tugas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "PengumpulanTugas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pengumpulan_staff_read" ON "PengumpulanTugas"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pengumpulan_wali_read" ON "PengumpulanTugas"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "pengumpulan_guru_write" ON "PengumpulanTugas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Tugas" t
      WHERE t.id = "PengumpulanTugas"."tugasId"
        AND t."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "Kompetensi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "kompetensi_read" ON "Kompetensi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "kompetensi_admin_write" ON "Kompetensi"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "BankSoal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bank_soal_read" ON "BankSoal"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "bank_soal_guru_write" ON "BankSoal"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "Ujian" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_staff_read" ON "Ujian"
  FOR SELECT TO authenticated
  USING ("deletedAt" IS NULL AND public.is_staff());
CREATE POLICY "ujian_wali_read" ON "Ujian"
  FOR SELECT TO authenticated
  USING (
    "deletedAt" IS NULL
    AND public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "UjianPeserta" up
      WHERE up."ujianId" = "Ujian".id
        AND public.is_wali_of_santri(up."santriId")
    )
  );
CREATE POLICY "ujian_guru_write" ON "Ujian"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "UjianSoal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_soal_staff_read" ON "UjianSoal"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_soal_wali_read" ON "UjianSoal"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Ujian" u
      JOIN "UjianPeserta" up ON up."ujianId" = u.id
      WHERE u.id = "UjianSoal"."ujianId"
        AND public.is_wali_of_santri(up."santriId")
    )
  );
CREATE POLICY "ujian_soal_guru_write" ON "UjianSoal"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianSoal"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "UjianPeserta" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_peserta_staff_read" ON "UjianPeserta"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_peserta_wali_read" ON "UjianPeserta"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_peserta_guru_write" ON "UjianPeserta"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianPeserta"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "UjianNilai" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_nilai_staff_read" ON "UjianNilai"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_nilai_wali_read" ON "UjianNilai"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_nilai_guru_write" ON "UjianNilai"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "Ujian" u
      WHERE u.id = "UjianNilai"."ujianId"
        AND u."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "UjianSesi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_sesi_staff_read" ON "UjianSesi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_sesi_wali_read" ON "UjianSesi"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_sesi_wali_insert" ON "UjianSesi"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_sesi_wali_update" ON "UjianSesi"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('WALI')
      AND public.is_wali_of_santri("santriId")
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('WALI')
      AND public.is_wali_of_santri("santriId")
    )
  );

ALTER TABLE "UjianJawaban" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ujian_jawaban_staff_read" ON "UjianJawaban"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "ujian_jawaban_wali_read" ON "UjianJawaban"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_jawaban_wali_insert" ON "UjianJawaban"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "ujian_jawaban_guru_update" ON "UjianJawaban"
  FOR UPDATE TO authenticated
  USING (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "UjianSesi" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."sesiId"
        AND u."guruId" = public.current_guru_id()
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR EXISTS (
      SELECT 1 FROM "UjianSesi" us
      JOIN "Ujian" u ON u.id = us."ujianId"
      WHERE us.id = "UjianJawaban"."sesiId"
        AND u."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "Rapor" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_staff_read" ON "Rapor"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_wali_read" ON "Rapor"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "rapor_admin_write" ON "Rapor"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "RaporMapel" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_mapel_staff_read" ON "RaporMapel"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_mapel_wali_read" ON "RaporMapel"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Rapor" r
      WHERE r.id = "RaporMapel"."raporId"
        AND public.is_wali_of_santri(r."santriId")
    )
  );
CREATE POLICY "rapor_mapel_admin_write" ON "RaporMapel"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "RaporCatatan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rapor_catatan_staff_read" ON "RaporCatatan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "rapor_catatan_wali_read" ON "RaporCatatan"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "Rapor" r
      WHERE r.id = "RaporCatatan"."raporId"
        AND public.is_wali_of_santri(r."santriId")
    )
  );
CREATE POLICY "rapor_catatan_admin_write" ON "RaporCatatan"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "PerkembanganQuran" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "perkembangan_quran_staff_read" ON "PerkembanganQuran"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "perkembangan_quran_wali_read" ON "PerkembanganQuran"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "perkembangan_quran_guru_write" ON "PerkembanganQuran"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "HafalanKitab" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hafalan_kitab_staff_read" ON "HafalanKitab"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "hafalan_kitab_wali_read" ON "HafalanKitab"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "hafalan_kitab_guru_write" ON "HafalanKitab"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "AkhlakPenilaian" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "akhlak_staff_read" ON "AkhlakPenilaian"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "akhlak_wali_read" ON "AkhlakPenilaian"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "akhlak_guru_write" ON "AkhlakPenilaian"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "Pembinaan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pembinaan_staff_read" ON "Pembinaan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "pembinaan_wali_read" ON "Pembinaan"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "pembinaan_guru_write" ON "Pembinaan"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  )
  WITH CHECK (
    public.is_admin_level()
    OR (public.has_role('GURU') AND "guruId" = public.current_guru_id())
  );

ALTER TABLE "CatatanWaliKelas" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "catatan_wali_kelas_staff_read" ON "CatatanWaliKelas"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "catatan_wali_kelas_wali_read" ON "CatatanWaliKelas"
  FOR SELECT TO authenticated
  USING (public.has_role('WALI') AND public.is_wali_of_santri("santriId"));
CREATE POLICY "catatan_wali_kelas_wali_kelas_write" ON "CatatanWaliKelas"
  FOR ALL TO authenticated
  USING (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND EXISTS (
        SELECT 1 FROM "Santri" s
        WHERE s.id = "CatatanWaliKelas"."santriId"
          AND public.is_wali_kelas_of(s."kelasId")
      )
    )
  )
  WITH CHECK (
    public.is_admin_level()
    OR (
      public.has_role('GURU')
      AND EXISTS (
        SELECT 1 FROM "Santri" s
        WHERE s.id = "CatatanWaliKelas"."santriId"
          AND public.is_wali_kelas_of(s."kelasId")
      )
    )
  );

ALTER TABLE "Notifikasi" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifikasi_wali_read" ON "Notifikasi"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "waliId" = public.current_wali_id()
  );
CREATE POLICY "notifikasi_staff_read" ON "Notifikasi"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "notifikasi_admin_insert" ON "Notifikasi"
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin_level());

ALTER TABLE "ChatRoom" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_room_staff_read" ON "ChatRoom"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "chat_room_wali_read" ON "ChatRoom"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "waliId" = public.current_wali_id()
  );
CREATE POLICY "chat_room_guru_read" ON "ChatRoom"
  FOR SELECT TO authenticated
  USING (
    public.has_role('GURU')
    AND "guruId" = public.current_guru_id()
  );
CREATE POLICY "chat_room_admin_write" ON "ChatRoom"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "ChatMessage" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_message_staff_read" ON "ChatMessage"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "chat_message_wali_read" ON "ChatMessage"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = public.current_wali_id()
    )
  );
CREATE POLICY "chat_message_guru_read" ON "ChatMessage"
  FOR SELECT TO authenticated
  USING (
    public.has_role('GURU')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = public.current_guru_id()
    )
  );
CREATE POLICY "chat_message_wali_insert" ON "ChatMessage"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('WALI')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = public.current_wali_id()
    )
  );
CREATE POLICY "chat_message_guru_insert" ON "ChatMessage"
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role('GURU')
    AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = public.current_guru_id()
    )
  );

ALTER TABLE "Surat" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "surat_staff_read" ON "Surat"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "surat_wali_read" ON "Surat"
  FOR SELECT TO authenticated
  USING (
    public.has_role('WALI')
    AND "santriId" IS NOT NULL
    AND public.is_wali_of_santri("santriId")
  );
CREATE POLICY "surat_admin_write" ON "Surat"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

ALTER TABLE "QRScan" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "qr_scan_staff_read" ON "QRScan"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "qr_scan_admin_write" ON "QRScan"
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

ALTER TABLE "Alumni" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alumni_staff_read" ON "Alumni"
  FOR SELECT TO authenticated USING (public.is_staff());
CREATE POLICY "alumni_admin_write" ON "Alumni"
  FOR ALL TO authenticated
  USING (public.is_admin_level())
  WITH CHECK (public.is_admin_level());

-- ==========================================================================
-- FILE: 20240101000003_bootstrap_roles_and_links.sql
-- ==========================================================================


BEGIN;

INSERT INTO "Role" (id, code, name, description, "sortOrder", "createdAt", "updatedAt")
SELECT
  gen_random_uuid(),
  r.code,
  r.name,
  r.desc_text,
  r.sort_order,
  now(),
  now()
FROM (VALUES
  ('SUPER_ADMIN', 'Super Admin',         'Akses penuh mengelola seluruh sistem', 1),
  ('ADMIN',       'Admin',               'Manajemen harian sistem',              2),
  ('KEPALA',      'Kepala Madrasah',     'Monitoring & pengambilan keputusan',  3),
  ('BENDAHARA',   'Bendahara',           'Pengelolaan keuangan madrasah',       4),
  ('GURU',        'Guru',                'Input absensi, nilai, dan catatan',   5),
  ('WALI',        'Wali Santri',         'Memantau perkembangan & administrasi anak', 6)
) AS r(code, name, desc_text, sort_order)
ON CONFLICT (code) DO NOTHING;

UPDATE "User" u
SET "firebaseUid" = au.id::text,
    "updatedAt" = now()
FROM auth.users au
WHERE u.email = au.email
  AND (u."firebaseUid" IS DISTINCT FROM au.id::text);

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
SET "isActive" = true;

COMMIT;

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

-- ==========================================================================
-- FILE: 20240101000004_rpc_functions_and_triggers.sql
-- ==========================================================================


BEGIN;

CREATE OR REPLACE FUNCTION public.verify_payment(
  p_payment_id TEXT,
  p_kas_id TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  new_kas_balance DOUBLE PRECISION,
  new_tagihan_paid DOUBLE PRECISION,
  new_tagihan_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment RECORD;
  v_kas_id TEXT;
  v_new_balance DOUBLE PRECISION DEFAULT 0;
  v_new_paid DOUBLE PRECISION DEFAULT 0;
  v_new_status TEXT DEFAULT NULL;
BEGIN
  SELECT id, amount, "tagihanId", status, "kasId"
    INTO v_payment
  FROM "Payment"
  WHERE id = p_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran tidak ditemukan'::TEXT,
      0.0, 0.0, NULL::TEXT;
    RETURN;
  END IF;

  IF v_payment.status != 'PENDING' THEN
    RETURN QUERY SELECT FALSE,
      'Pembayaran sudah ' || v_payment.status::TEXT,
      0.0, 0.0, NULL::TEXT;
    RETURN;
  END IF;

  v_kas_id := COALESCE(p_kas_id, v_payment."kasId");

  UPDATE "Payment"
  SET status = 'VERIFIED',
      "kasId" = v_kas_id,
      "verifiedAt" = NOW(),
      "updatedAt" = NOW()
  WHERE id = p_payment_id;

  IF v_kas_id IS NOT NULL AND v_kas_id != '' THEN
    UPDATE "Kas"
    SET balance = balance + v_payment.amount,
        "updatedAt" = NOW()
    WHERE id = v_kas_id
    RETURNING balance INTO v_new_balance;
  END IF;

  IF v_payment."tagihanId" IS NOT NULL AND v_payment."tagihanId" != '' THEN
    UPDATE "Tagihan"
    SET "paidAmount" = LEAST("paidAmount" + v_payment.amount, amount),
        status = CASE
          WHEN "paidAmount" + v_payment.amount >= amount THEN 'LUNAS'
          WHEN "paidAmount" + v_payment.amount > 0 THEN 'CICIL'
          ELSE 'BELUM_BAYAR'
        END,
        "updatedAt" = NOW()
    WHERE id = v_payment."tagihanId"
    RETURNING "paidAmount", status INTO v_new_paid, v_new_status;
  END IF;

  IF v_kas_id IS NOT NULL AND v_kas_id != '' THEN
    INSERT INTO "TransaksiKas" (
      id, "kasId", type, category, amount, description,
      "paymentId", "transaksiDate", "recordedById",
      "createdAt", "updatedAt"
    )
    VALUES (
      gen_random_uuid(), v_kas_id, 'PEMASUKAN', 'PEMBAYARAN_SANTRI',
      v_payment.amount,
      'Pembayaran ' || p_payment_id || ' (auto from verify_payment)',
      p_payment_id, NOW(), auth.uid()::text,
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING; -- idempotent
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT,
    COALESCE(v_new_balance, 0.0),
    COALESCE(v_new_paid, 0.0),
    COALESCE(v_new_status, ''::TEXT);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_payment(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_payment(
  p_payment_id TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
BEGIN
  SELECT status INTO v_status FROM "Payment" WHERE id = p_payment_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran tidak ditemukan'::TEXT;
    RETURN;
  END IF;

  IF v_status != 'PENDING' THEN
    RETURN QUERY SELECT FALSE, 'Pembayaran sudah ' || v_status::TEXT;
    RETURN;
  END IF;

  UPDATE "Payment"
  SET status = 'REJECTED',
      note = COALESCE(p_reason, note),
      "updatedAt" = NOW()
  WHERE id = p_payment_id;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_payment(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_kas_balance(
  p_kas_id TEXT,
  p_delta DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_balance DOUBLE PRECISION;
BEGIN
  UPDATE "Kas"
  SET balance = balance + p_delta,
      "updatedAt" = NOW()
  WHERE id = p_kas_id
  RETURNING balance INTO v_new_balance;

  RETURN COALESCE(v_new_balance, 0.0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_kas_balance(TEXT, DOUBLE PRECISION) TO authenticated;

CREATE OR REPLACE FUNCTION public.create_transaksi_kas(
  p_kas_id TEXT,
  p_type TEXT,         -- PEMASUKAN | PENGELUARAN
  p_category TEXT,     -- PEMBAYARAN_SANTRI | HONOR_GURU | OPERASIONAL | dll
  p_amount DOUBLE PRECISION,
  p_description TEXT,
  p_reference TEXT DEFAULT NULL,
  p_recorded_by TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  transaksi_id TEXT,
  new_kas_balance DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id TEXT;
  v_delta DOUBLE PRECISION;
  v_new_balance DOUBLE PRECISION;
BEGIN
  v_delta := CASE WHEN p_type = 'PEMASUKAN' THEN p_amount ELSE -p_amount END;

  v_id := gen_random_uuid()::text;
  INSERT INTO "TransaksiKas" (
    id, "kasId", type, category, amount, description,
    reference, "transaksiDate", "recordedById",
    "createdAt", "updatedAt"
  )
  VALUES (
    v_id, p_kas_id, p_type, p_category, p_amount, p_description,
    p_reference, NOW(), p_recorded_by,
    NOW(), NOW()
  );

  v_new_balance := public.update_kas_balance(p_kas_id, v_delta);

  RETURN QUERY SELECT TRUE, v_id, v_new_balance;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_transaksi_kas(
  TEXT, TEXT, TEXT, DOUBLE PRECISION, TEXT, TEXT, TEXT
) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_honor_guru_status(
  p_honor_id TEXT,
  p_new_status TEXT,    -- DISETUJUI | DIBAYARKAN
  p_kas_id TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  new_kas_balance DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_honor RECORD;
  v_total DOUBLE PRECISION;
  v_new_balance DOUBLE PRECISION DEFAULT 0;
BEGIN
  SELECT id, status, "totalHonor", "honorMengajar", insentif, tunjangan, potongan,
    "guruId", "periodeLabel"
    INTO v_honor
  FROM "HonorGuru"
  WHERE id = p_honor_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Honor tidak ditemukan'::TEXT, 0.0;
    RETURN;
  END IF;

  IF p_new_status = 'DISETUJUI' AND v_honor.status != 'DRAFT' THEN
    RETURN QUERY SELECT FALSE, 'Honor harus berstatus DRAFT'::TEXT, 0.0;
    RETURN;
  END IF;

  IF p_new_status = 'DIBAYARKAN' AND v_honor.status != 'DISETUJUI' THEN
    RETURN QUERY SELECT FALSE, 'Honor harus berstatus DISETUJUI'::TEXT, 0.0;
    RETURN;
  END IF;

  v_total := COALESCE(v_honor."totalHonor", 0);
  IF v_total <= 0 THEN
    v_total := COALESCE(v_honor."honorMengajar", 0)
      + COALESCE(v_honor.insentif, 0)
      + COALESCE(v_honor.tunjangan, 0)
      - COALESCE(v_honor.potongan, 0);
  END IF;

  UPDATE "HonorGuru"
  SET status = p_new_status,
      "updatedAt" = NOW()
  WHERE id = p_honor_id;

  IF p_new_status = 'DIBAYARKAN' AND p_kas_id IS NOT NULL AND p_kas_id != '' THEN
    v_new_balance := public.update_kas_balance(p_kas_id, -v_total);

    INSERT INTO "TransaksiKas" (
      id, "kasId", type, category, amount, description,
      "honorGuruId", "transaksiDate", "recordedById",
      "createdAt", "updatedAt"
    )
    VALUES (
      gen_random_uuid()::text, p_kas_id, 'PENGELUARAN', 'HONOR_GURU',
      v_total,
      'Pembayaran honor ' || v_honor."periodeLabel" || ' (auto)',
      p_honor_id, NOW(), auth.uid()::text,
      NOW(), NOW()
    )
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, COALESCE(v_new_balance, 0.0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_honor_guru_status(TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.submit_ujian(
  p_sesi_id TEXT,
  p_answers JSONB
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  final_score DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sesi RECORD;
  v_answer RECORD;
  v_soal RECORD;
  v_total_score DOUBLE PRECISION := 0;
  v_total_bobot DOUBLE PRECISION := 0;
  v_final_score DOUBLE PRECISION;
  v_answer_item JSONB;
BEGIN
  SELECT id, "ujianId", "santriId", status, "startTime"
    INTO v_sesi
  FROM "UjianSesi"
  WHERE id = p_sesi_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Sesi ujian tidak ditemukan'::TEXT, 0.0;
    RETURN;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN QUERY SELECT FALSE, 'Ujian sudah selesai'::TEXT, 0.0;
    RETURN;
  END IF;

  FOR v_answer_item IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    SELECT us.id, us.bobot, bs.type, bs."correctAnswer"
      INTO v_soal
    FROM "UjianSoal" us
    JOIN "BankSoal" bs ON bs.id = us."bankSoalId"
    WHERE us.id = v_answer_item->>'ujianSoalId';

    IF FOUND AND v_soal.type = 'PG' THEN
      v_total_bobot := v_total_bobot + COALESCE(v_soal.bobot, 1.0);

      IF UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer") THEN
        v_total_score := v_total_score + COALESCE(v_soal.bobot, 1.0);
      END IF;

      INSERT INTO "UjianJawaban" (
        id, "sesiId", "ujianSoalId", "santriId", answer,
        "isCorrect", score, "isAutoCorrected",
        "createdAt", "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text, p_sesi_id,
        v_answer_item->>'ujianSoalId', v_sesi."santriId",
        v_answer_item->>'answer',
        UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer"),
        CASE WHEN UPPER(v_answer_item->>'answer') = UPPER(v_soal."correctAnswer")
          THEN v_soal.bobot ELSE 0 END,
        true,
        NOW(), NOW()
      )
      ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
        answer = EXCLUDED.answer,
        "isCorrect" = EXCLUDED."isCorrect",
        score = EXCLUDED.score,
        "isAutoCorrected" = true,
        "updatedAt" = NOW();
    ELSE
      INSERT INTO "UjianJawaban" (
        id, "sesiId", "ujianSoalId", "santriId", answer,
        "isAutoCorrected",
        "createdAt", "updatedAt"
      )
      VALUES (
        gen_random_uuid()::text, p_sesi_id,
        v_answer_item->>'ujianSoalId', v_sesi."santriId",
        v_answer_item->>'answer',
        false,
        NOW(), NOW()
      )
      ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
        answer = EXCLUDED.answer,
        "updatedAt" = NOW();
    END IF;
  END LOOP;

  v_final_score := CASE WHEN v_total_bobot > 0
    THEN (v_total_score / v_total_bobot) * 100
    ELSE 0 END;

  UPDATE "UjianSesi"
  SET status = 'FINISHED',
      "endTime" = NOW(),
      score = v_final_score,
      "durationUsed" = EXTRACT(EPOCH FROM (NOW() - "startTime"))::INT,
      "updatedAt" = NOW()
  WHERE id = p_sesi_id;

  INSERT INTO "UjianNilai" (
    id, "ujianId", "santriId", score, "isAutoCorrect", "gradedAt",
    "createdAt", "updatedAt"
  )
  VALUES (
    gen_random_uuid()::text, v_sesi."ujianId", v_sesi."santriId",
    v_final_score, true, NOW(),
    NOW(), NOW()
  )
  ON CONFLICT ("ujianId", "santriId") DO UPDATE SET
    score = EXCLUDED.score,
    "isAutoCorrect" = true,
    "gradedAt" = NOW(),
    "updatedAt" = NOW();

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, v_final_score;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_ujian(TEXT, JSONB) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_update_chat_room_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE "ChatRoom"
    SET "lastMessage" = NEW.message,
        "lastMessageAt" = NOW(),
        "updatedAt" = NOW()
    WHERE id = NEW."chatRoomId";
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_chat_message_update_room ON "ChatMessage";
CREATE TRIGGER trg_chat_message_update_room
  AFTER INSERT ON "ChatMessage"
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_update_chat_room_last_message();

CREATE OR REPLACE FUNCTION public.fn_payment_verified_update_tagihan()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_paid DOUBLE PRECISION;
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status = 'PENDING' AND NEW.status = 'VERIFIED' THEN

    IF NEW."tagihanId" IS NOT NULL AND NEW."tagihanId" != '' THEN
      SELECT "paidAmount" INTO v_old_paid FROM "Tagihan" WHERE id = NEW."tagihanId";

      UPDATE "Tagihan"
      SET status = CASE
          WHEN "paidAmount" >= amount THEN 'LUNAS'
          WHEN "paidAmount" > 0 THEN 'CICIL'
          ELSE 'BELUM_BAYAR'
        END,
        "updatedAt" = NOW()
      WHERE id = NEW."tagihanId";
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_verified_update_tagihan ON "Payment";
CREATE TRIGGER trg_payment_verified_update_tagihan
  AFTER UPDATE ON "Payment"
  FOR EACH ROW
  WHEN (OLD.status = 'PENDING' AND NEW.status = 'VERIFIED')
  EXECUTE FUNCTION public.fn_payment_verified_update_tagihan();

CREATE OR REPLACE FUNCTION public.fn_payment_insert_auto_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'VERIFIED' THEN
    IF NEW."kasId" IS NOT NULL AND NEW."kasId" != '' THEN
      UPDATE "Kas"
      SET balance = balance + NEW.amount,
          "updatedAt" = NOW()
      WHERE id = NEW."kasId";
    END IF;

    IF NEW."tagihanId" IS NOT NULL AND NEW."tagihanId" != '' THEN
      UPDATE "Tagihan"
      SET "paidAmount" = LEAST("paidAmount" + NEW.amount, amount),
          status = CASE
            WHEN "paidAmount" + NEW.amount >= amount THEN 'LUNAS'
            WHEN "paidAmount" + NEW.amount > 0 THEN 'CICIL'
            ELSE 'BELUM_BAYAR'
          END,
          "updatedAt" = NOW()
      WHERE id = NEW."tagihanId";
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_insert_auto_update ON "Payment";
CREATE TRIGGER trg_payment_insert_auto_update
  AFTER INSERT ON "Payment"
  FOR EACH ROW
  WHEN (NEW.status = 'VERIFIED')
  EXECUTE FUNCTION public.fn_payment_insert_auto_update();

CREATE OR REPLACE FUNCTION public.fn_santri_insert_auto_wali_link()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW."waliId" IS NOT NULL AND NEW."waliId" != '' THEN
    INSERT INTO "SantriWali" (
      id, "santriId", "waliId", "canAccess", "createdAt"
    )
    VALUES (
      gen_random_uuid()::text, NEW.id, NEW."waliId", true,
      NOW()
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_santri_insert_auto_wali_link ON "Santri";
CREATE TRIGGER trg_santri_insert_auto_wali_link
  AFTER INSERT ON "Santri"
  FOR EACH ROW
  WHEN (NEW."waliId" IS NOT NULL)
  EXECUTE FUNCTION public.fn_santri_insert_auto_wali_link();

CREATE OR REPLACE FUNCTION public.fn_payment_auto_invoice_no()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year INT;
  v_count INT;
  v_invoice TEXT;
BEGIN
  IF TG_OP = 'INSERT' AND (NEW."invoiceNo" IS NULL OR NEW."invoiceNo" = '') THEN
    v_year := EXTRACT(YEAR FROM NOW());
    SELECT COUNT(*) + 1 INTO v_count FROM "Payment"
    WHERE "invoiceNo" LIKE 'INV-' || v_year || '-%';

    v_invoice := 'INV-' || v_year || '-' || LPAD(v_count::TEXT, 6, '0');
    NEW."invoiceNo" := v_invoice;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_auto_invoice_no ON "Payment";
CREATE TRIGGER trg_payment_auto_invoice_no
  BEFORE INSERT ON "Payment"
  FOR EACH ROW
  WHEN (NEW."invoiceNo" IS NULL OR NEW."invoiceNo" = '')
  EXECUTE FUNCTION public.fn_payment_auto_invoice_no();

CREATE OR REPLACE FUNCTION public.fn_auto_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_santri_updated_at ON "Santri";
CREATE TRIGGER trg_santri_updated_at BEFORE UPDATE ON "Santri"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_payment_updated_at ON "Payment";
CREATE TRIGGER trg_payment_updated_at BEFORE UPDATE ON "Payment"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_tagihan_updated_at ON "Tagihan";
CREATE TRIGGER trg_tagihan_updated_at BEFORE UPDATE ON "Tagihan"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_kas_updated_at ON "Kas";
CREATE TRIGGER trg_kas_updated_at BEFORE UPDATE ON "Kas"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_honor_guru_updated_at ON "HonorGuru";
CREATE TRIGGER trg_honor_guru_updated_at BEFORE UPDATE ON "HonorGuru"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_chat_room_updated_at ON "ChatRoom";
CREATE TRIGGER trg_chat_room_updated_at BEFORE UPDATE ON "ChatRoom"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_wali_updated_at ON "Wali";
CREATE TRIGGER trg_wali_updated_at BEFORE UPDATE ON "Wali"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_user_updated_at ON "User";
CREATE TRIGGER trg_user_updated_at BEFORE UPDATE ON "User"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

DROP TRIGGER IF EXISTS trg_guru_updated_at ON "Guru";
CREATE TRIGGER trg_guru_updated_at BEFORE UPDATE ON "Guru"
  FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at();

COMMIT;

-- ==========================================================================
-- FILE: 20240101000005_fcm_token_column.sql
-- ==========================================================================


ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

CREATE POLICY "user_update_fcm_token_self"
  ON "User"
  FOR UPDATE TO authenticated
  USING (id = public.current_user_id())
  WITH CHECK (id = public.current_user_id());

COMMENT ON COLUMN "User"."fcmToken" IS
  'Firebase Cloud Messaging token untuk push notification. Null jika user belum login di device atau tidak ada FCM.';

-- ==========================================================================
-- FILE: 20240101000006_fcm_push_notification.sql
-- ==========================================================================


BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.fn_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_fcm_token TEXT;
  v_wali_user_id TEXT;
  v_edge_function_url TEXT;
  v_payload JSONB;
  v_response JSONB;
BEGIN
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  IF NEW."isPushSent" = true THEN
    RETURN NEW;
  END IF;

  SELECT "userId" INTO v_wali_user_id
  FROM "Wali"
  WHERE id = NEW."waliId"
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF v_wali_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT "fcmToken" INTO v_fcm_token
  FROM "User"
  WHERE id = v_wali_user_id;

  IF v_fcm_token IS NULL OR v_fcm_token = '' THEN
    RETURN NEW;
  END IF;

  v_payload := jsonb_build_object(
    'fcm_token', v_fcm_token,
    'title', NEW.title,
    'body', NEW.message,
    'priority', COALESCE(NEW.priority, 'NORMAL'),
    'data', jsonb_build_object(
      'type', NEW.type,
      'waliId', NEW."waliId",
      'santriId', COALESCE(NEW."santriId", ''),
      'entityType', COALESCE(NEW."entityType", ''),
      'entityId', COALESCE(NEW."entityId", ''),
      'notifikasiId', NEW.id,
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    )
  );

  v_edge_function_url := 'https://bhogtbhzeoxsowcbspjr.supabase.co/functions/v1/send-fcm-notification';

  SELECT * INTO v_response FROM extensions.http_post(
    url := v_edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJob2d0YmhoemVveHNvd2Nic3BqciIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI5OTU5MjE3LCJleHAiOjIwNDUzMzUyMTd9.q0nTj2cVD6Vk1YBm4PjK6K5v4vLqP1Ph8cYKQ3qWJ8c'
    ),
    body := v_payload::text
  );

  IF v_response->>'status_code' = '200' THEN
    IF (v_response->'body'->>'success')::boolean = true THEN
      UPDATE "Notifikasi"
      SET "isPushSent" = true
      WHERE id = NEW.id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notifikasi_send_fcm ON "Notifikasi";
CREATE TRIGGER trg_notifikasi_send_fcm
  AFTER INSERT ON "Notifikasi"
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_send_fcm_notification();

COMMIT;

-- ==========================================================================
-- FILE: 20240101000007_storage_buckets_and_policies.sql
-- ==========================================================================


INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('photos', 'photos', true, 5242880,
    ARRAY['image/jpeg','image/png','image/webp','image/gif']),

  ('materi', 'materi', true, 52428800,
    ARRAY['application/pdf',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),

  ('surat', 'surat', false, 10485760,
    ARRAY['application/pdf']),

  ('tugas', 'tugas', false, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png']),

  ('pengumuman', 'pengumuman', true, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png']),

  ('ujian', 'ujian', false, 10485760,
    ARRAY['application/pdf','image/jpeg','image/png'])
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "photos_select_public"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'photos');

CREATE POLICY "photos_insert_authenticated"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND public.is_staff()
  );

CREATE POLICY "photos_update_owner_or_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (public.is_admin_level() OR public.is_staff())
  );

CREATE POLICY "photos_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND public.is_admin_level()
  );

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

CREATE POLICY "tugas_select_authenticated"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'tugas');

CREATE POLICY "tugas_insert_guru_or_admin"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'tugas'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

CREATE POLICY "tugas_update_guru_or_admin"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'tugas'
    AND (public.is_admin_level() OR public.has_role('GURU'))
  );

CREATE POLICY "tugas_delete_admin"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'tugas'
    AND public.is_admin_level()
  );

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

-- ==========================================================================
-- FILE: 20240101000008_storage_columns.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Materi'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Materi" ADD COLUMN "filePath" TEXT;
    COMMENT ON COLUMN "Materi"."filePath" IS
      'Path object di Supabase Storage bucket materi (cth: mapelId/filename.pdf). Dipakai untuk delete.';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Tugas'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Tugas" ADD COLUMN "filePath" TEXT;
    COMMENT ON COLUMN "Tugas"."filePath" IS
      'Path object di Supabase Storage bucket tugas.';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Surat'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Surat" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Surat" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Surat"."filePath" IS
      'Path object PDF di Supabase Storage bucket surat.';
    COMMENT ON COLUMN "Surat"."fileUrl" IS
      'Public/signed URL untuk PDF surat (diisi saat generate).';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Announcement'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Announcement" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Announcement" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Announcement"."filePath" IS
      'Path object lampiran di Supabase Storage bucket pengumuman.';
    COMMENT ON COLUMN "Announcement"."fileUrl" IS
      'Public URL untuk lampiran pengumuman.';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Ujian'
      AND column_name = 'filePath'
  ) THEN
    ALTER TABLE "Ujian" ADD COLUMN "filePath" TEXT;
    ALTER TABLE "Ujian" ADD COLUMN "fileUrl" TEXT;
    COMMENT ON COLUMN "Ujian"."filePath" IS
      'Path object lampiran di Supabase Storage bucket ujian.';
    COMMENT ON COLUMN "Ujian"."fileUrl" IS
      'Public/signed URL untuk lampiran ujian.';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'Wali'
      AND column_name = 'photoUrl'
  ) THEN
    ALTER TABLE "Wali" ADD COLUMN "photoUrl" TEXT;
    COMMENT ON COLUMN "Wali"."photoUrl" IS
      'Public URL foto profil wali (di Supabase Storage bucket photos).';
  END IF;
END $$;

-- ==========================================================================
-- FILE: 20240101000009_postgrest_schema_cache_reload.sql
-- ==========================================================================


NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000010_enable_realtime_publication.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime
      WITH (publish = 'insert, update, delete, truncate');
  END IF;
END $$;

DO $$
DECLARE
  tbl_name TEXT;
  tables TEXT[] := ARRAY[
    'Santri', 'Guru', 'Kelas', 'MataPelajaran', 'Jadwal',
    'Materi', 'Tugas', 'Pertemuan', 'Absensi', 'Nilai',
    'Ujian', 'UjianSoal', 'UjianPeserta', 'UjianSesi', 'UjianJawaban',
    'UjianNilai', 'BankSoal', 'PengumpulanTugas',
    'PerkembanganQuran', 'HafalanKitab', 'AkhlakPenilaian', 'Pembinaan',
    'Tagihan', 'Payment', 'Kas', 'TransaksiKas', 'HonorGuru',
    'Announcement', 'Notifikasi', 'Surat',
    'ChatRoom', 'ChatMessage', 'AuditLog', 'Alumni'
  ];
BEGIN
  FOREACH tbl_name IN ARRAY tables LOOP
    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        tbl_name
      );
      RAISE NOTICE 'Added % to supabase_realtime', tbl_name;
    EXCEPTION
      WHEN duplicate_table THEN
        NULL;
      WHEN OTHERS THEN
        RAISE NOTICE 'Skipped %: %', tbl_name, SQLERRM;
    END;
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000011_fix_fcm_trigger_function.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Notifikasi' AND column_name = 'updatedAt'
  ) THEN
    ALTER TABLE "Notifikasi" ADD COLUMN "updatedAt" TIMESTAMPTZ DEFAULT now();
    UPDATE "Notifikasi" SET "updatedAt" = "createdAt" WHERE "updatedAt" IS NULL;
    RAISE NOTICE 'Added updatedAt column to Notifikasi';
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.fn_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net
AS $$
DECLARE
  v_fcm_token TEXT;
  v_wali_user_id TEXT;
  v_edge_function_url TEXT;
  v_payload JSONB;
  v_request_id BIGINT;
BEGIN
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  IF NEW."isPushSent" = true THEN
    RETURN NEW;
  END IF;

  SELECT "userId" INTO v_wali_user_id
  FROM "Wali"
  WHERE id = NEW."waliId"
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF v_wali_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT "fcmToken" INTO v_fcm_token
  FROM "User"
  WHERE id = v_wali_user_id;

  IF v_fcm_token IS NULL OR v_fcm_token = '' THEN
    RETURN NEW;
  END IF;

  v_payload := jsonb_build_object(
    'fcm_token', v_fcm_token,
    'title', NEW.title,
    'body', NEW.message,
    'priority', COALESCE(NEW.priority, 'NORMAL'),
    'data', jsonb_build_object(
      'type', NEW.type,
      'waliId', NEW."waliId",
      'santriId', COALESCE(NEW."santriId", ''),
      'entityType', COALESCE(NEW."entityType", ''),
      'entityId', COALESCE(NEW."entityId", ''),
      'notifikasiId', NEW.id,
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    )
  );

  v_edge_function_url := 'https://bhogtbhzeoxsowcbspjr.supabase.co/functions/v1/send-fcm-notification';

  SELECT * INTO v_request_id FROM net.http_post(
    url := v_edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJob2d0YmhoemVveHNvd2Nic3BqciIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI5OTU5MjE3LCJleHAiOjIwNDUzMzUyMTd9.q0nTj2cVD6Vk1YBm4PjK6K5v4vLqP1Ph8cYKQ3qWJ8c'
    ),
    body := v_payload  -- FIX: pass jsonb directly (v_payload already JSONB)
  );

  IF v_request_id IS NOT NULL AND v_request_id > 0 THEN
    UPDATE "Notifikasi" SET "isPushSent" = true WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_notifikasi_send_fcm'
  ) THEN
    CREATE TRIGGER trg_notifikasi_send_fcm
      AFTER INSERT ON "Notifikasi"
      FOR EACH ROW
      EXECUTE FUNCTION public.fn_send_fcm_notification();
    RAISE NOTICE 'Created trigger trg_notifikasi_send_fcm';
  ELSE
    RAISE NOTICE 'Trigger trg_notifikasi_send_fcm already exists (function updated)';
  END IF;
END $$;

-- ==========================================================================
-- FILE: 20240101000012_seed_test_data.sql
-- ==========================================================================


DO $$
DECLARE
  v_guru_id TEXT;
  v_santri_id TEXT;
  v_santri2_id TEXT;
  v_santri3_id TEXT;
  v_kelas_id TEXT;
  v_mapel_id TEXT;
  v_mapel2_id TEXT;
  v_ta_id TEXT;
  v_sem_id TEXT;
  v_ujian_id TEXT;
  v_ujian_id2 TEXT;
  v_soal_id TEXT;
  v_soal_id2 TEXT;
  v_soal_id3 TEXT;
  v_soal_id4 TEXT;
  v_bank_soal_id TEXT;
  v_bank_soal_id2 TEXT;
  v_tugas_id TEXT;
  v_pertemuan_id TEXT;
  v_surat_id TEXT;
  v_alumni_id TEXT;
BEGIN
  SELECT id INTO v_guru_id FROM "Guru" WHERE "deletedAt" IS NULL LIMIT 1;
  SELECT id INTO v_santri_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" LIMIT 1;
  SELECT id INTO v_santri2_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" OFFSET 1 LIMIT 1;
  SELECT id INTO v_santri3_id FROM "Santri" WHERE "deletedAt" IS NULL ORDER BY "createdAt" OFFSET 2 LIMIT 1;
  SELECT id INTO v_kelas_id FROM "Kelas" LIMIT 1;
  SELECT id INTO v_mapel_id FROM "MataPelajaran" LIMIT 1;
  SELECT id INTO v_mapel2_id FROM "MataPelajaran" OFFSET 1 LIMIT 1;
  SELECT id INTO v_ta_id FROM "TahunAjaran" LIMIT 1;
  SELECT id INTO v_sem_id FROM "Semester" LIMIT 1;

  RAISE NOTICE 'Guru ID: %', v_guru_id;
  RAISE NOTICE 'Santri ID: %', v_santri_id;
  RAISE NOTICE 'Kelas ID: %', v_kelas_id;
  RAISE NOTICE 'Mapel ID: %', v_mapel_id;

  IF NOT EXISTS (SELECT 1 FROM "BankSoal" LIMIT 1) THEN
    INSERT INTO "BankSoal" ("mapelId", "tahunAjaranId", "guruId", "code", "type", "question", "options", "correctAnswer", "answerKey", "bobot", "difficulty")
    VALUES
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-001', 'PG', 'Hukum bacaan nun mati/tanwin ketemu huruf ba disebut?',
        '["Ikhfa","Idgham","Iqlab","Ikhfa Syafawi"]'::jsonb, 'Iqlab', NULL, 1.0, 'EASY'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-002', 'PG', 'Hukum bacaan nun mati/tanwin ketemu huruf ta disebut?',
        '["Ikhfa","Idgham","Iqlab","Ikhfa Syafawi"]'::jsonb, 'Ikhfa', NULL, 1.0, 'EASY'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-003', 'ESSAY', 'Jelaskan pengertian tajwid dan tujuannya!',
        NULL, NULL, 'Tajwid adalah ilmu yang mempelajari kaidah membaca Al-Quran dengan baik dan benar. Tujuannya untuk menjaga kesempurnaan bacaan dan menjaga dari kesalahan.', 2.0, 'MEDIUM'),
      (v_mapel_id, v_ta_id, v_guru_id, 'BS-004', 'PG', 'Berapa jumlah huruf hijaiyah?',
        '["26","28","29","30"]'::jsonb, '28', NULL, 1.0, 'EASY'),
      (v_mapel2_id, v_ta_id, v_guru_id, 'BS-005', 'ESSAY', 'Sebutkan rukun iman yang enam!',
        NULL, NULL, 'Iman kepada Allah, Malaikat, Kitab, Rasul, Hari Kiamat, Qada dan Qadar', 2.0, 'MEDIUM');
    RAISE NOTICE 'Created 5 BankSoal records';
  END IF;
  SELECT id INTO v_bank_soal_id FROM "BankSoal" ORDER BY "createdAt" LIMIT 1;
  SELECT id INTO v_bank_soal_id2 FROM "BankSoal" ORDER BY "createdAt" OFFSET 1 LIMIT 1;

  IF NOT EXISTS (SELECT 1 FROM "Ujian" LIMIT 1) THEN
    INSERT INTO "Ujian" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "type", "description", "startTime", "endTime", "durationMnt", "ruang", "pengawas", "isPublished", "maxScore", "passingScore")
    VALUES
      (v_ta_id, v_sem_id, v_mapel_id, v_kelas_id, v_guru_id,
       'Ujian Tengah Semester Tajwid',
       'UTS',
       'Ujian tengah semester untuk mapel Tajwid. Materi: Hukum Nun Mati & Tanwin.',
       NOW() - INTERVAL '1 day',
       NOW() + INTERVAL '7 days',
       60, -- 60 menit
       'Ruang Kelas 1', 'Ustadz Ahmad Fauzi',
       true, -- published — wali bisa take
       100, 70)
    RETURNING id INTO v_ujian_id;
    RAISE NOTICE 'Created Ujian (published): %', v_ujian_id;

    INSERT INTO "Ujian" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "type", "description", "startTime", "endTime", "durationMnt", "ruang", "pengawas", "isPublished", "maxScore", "passingScore")
    VALUES
      (v_ta_id, v_sem_id, v_mapel2_id, v_kelas_id, v_guru_id,
       'Ujian Akhir Semester Akidah Akhlak',
       'UAS',
       'Ujian akhir semester untuk mapel Akidah Akhlak.',
       NOW() + INTERVAL '3 days',
       NOW() + INTERVAL '10 days',
       90,
       'Ruang Kelas 1', 'Ustadz Ahmad Fauzi',
       false, -- draft — belum published
       100, 70)
    RETURNING id INTO v_ujian_id2;
    RAISE NOTICE 'Created Ujian (draft): %', v_ujian_id2;
  ELSE
    SELECT id INTO v_ujian_id FROM "Ujian" WHERE "isPublished" = true LIMIT 1;
    SELECT id INTO v_ujian_id2 FROM "Ujian" WHERE "isPublished" = false LIMIT 1;
  END IF;

  IF v_ujian_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "UjianSoal" WHERE "ujianId" = v_ujian_id) THEN
    INSERT INTO "UjianSoal" ("ujianId", "bankSoalId", "urutan", "bobot")
    SELECT v_ujian_id, id, ROW_NUMBER() OVER (), "bobot"
    FROM "BankSoal"
    WHERE "mapelId" = v_mapel_id
    ORDER BY "createdAt"
    LIMIT 4;
    RAISE NOTICE 'Created UjianSoal for ujian: %', v_ujian_id;
  END IF;

  IF v_ujian_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM "UjianPeserta" WHERE "ujianId" = v_ujian_id) THEN
    INSERT INTO "UjianPeserta" ("ujianId", "santriId", "ruang", "pengawas", "isHadir")
    VALUES
      (v_ujian_id, v_santri_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true),
      (v_ujian_id, v_santri2_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true),
      (v_ujian_id, v_santri3_id, 'Ruang Kelas 1', 'Ustadz Ahmad Fauzi', true);
    RAISE NOTICE 'Created UjianPeserta for ujian: %', v_ujian_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "Tugas" WHERE "deletedAt" IS NULL) THEN
    INSERT INTO "Tugas" ("tahunAjaranId", "semesterId", "mapelId", "kelasId", "guruId", "title", "description", "type", "fileUrl", "maxScore", "dueDate", "isPublished", "publishedAt")
    VALUES
      (v_ta_id, v_sem_id, v_mapel_id, v_kelas_id, v_guru_id,
       'Tugas Tajwid: Hafalan Surat An-Nas',
       'Hafalkan Surat An-Nas dengan tajwid yang benar. Rekam suara dan kirim via app.',
       'INDIVIDU',
       NULL, 100,
       NOW() + INTERVAL '7 days',
       true,
       NOW())
    RETURNING id INTO v_tugas_id;
    RAISE NOTICE 'Created Tugas (published): %', v_tugas_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "Pertemuan") THEN
    INSERT INTO "Pertemuan" (
      id, "tahunAjaranId", "semesterId", "kelasId", "mapelId", "guruId",
      "pertemuanKe", date, topic, description, "isCompleted", "createdAt", "updatedAt"
    )
    SELECT gen_random_uuid()::text, j."tahunAjaranId", j."semesterId", j."kelasId",
           j."mapelId", j."guruId", 1, CURRENT_DATE, 'Pertemuan hari ini',
           NULL, false, now(), now()
    FROM "Jadwal" j LIMIT 1
    RETURNING id INTO v_pertemuan_id;

    INSERT INTO "Pertemuan" (
      id, "tahunAjaranId", "semesterId", "kelasId", "mapelId", "guruId",
      "pertemuanKe", date, topic, description, "isCompleted", "createdAt", "updatedAt"
    )
    SELECT gen_random_uuid()::text, j."tahunAjaranId", j."semesterId", j."kelasId",
           j."mapelId", j."guruId", 2, CURRENT_DATE - INTERVAL '1 day',
           'Pertemuan kemarin', 'Berjalan lancar', true, now(), now()
    FROM "Jadwal" j LIMIT 1;
    RAISE NOTICE 'Created Pertemuan: %', v_pertemuan_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "Surat") THEN
    INSERT INTO "Surat" ("santriId", "nomorSurat", "type", "title", "content", "status", "tanggalSurat")
    VALUES
      (v_santri_id, 'SURAT-001/2026', 'KETERANGAN_AKTIF', 'Surat Keterangan Aktif Belajar', 'Yang bertanda tangan di bawah ini, Kepala Madrasah Miftahul Ulum 01, menerangkan bahwa:', 'PUBLISHED', NOW()),
      (v_santri_id, 'SURAT-002/2026', 'PINDAH', 'Surat Keterangan Pindah', 'Yang bertanda tangan di bawah ini...', 'DRAFT', NOW())
    RETURNING id INTO v_surat_id;
    RAISE NOTICE 'Created Surat: %', v_surat_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "Alumni") THEN
    INSERT INTO "Alumni" ("santriId", "tahunLulus", "statusKelulusan", "pekerjaan", "domisiliKota")
    VALUES
      (v_santri_id, 2023, 'LULUS', 'Santri di Pondok Modern', 'Jakarta'),
      (v_santri2_id, 2024, 'LULUS', 'Pelajar SMA', 'Bandung'),
      (v_santri3_id, 2024, 'LULUS', 'Santri Lanjutan', 'Surabaya');
    RAISE NOTICE 'Created 3 Alumni records';
  END IF;

  RAISE NOTICE '\n=== SEED DATA COMPLETED ===';
  RAISE NOTICE 'Ujian Take dapat di-test dengan santri pertama (id: %)', v_santri_id;
END $$;

-- ==========================================================================
-- FILE: 20240101000013_wali_read_policies.sql
-- ==========================================================================


DROP POLICY IF EXISTS "uj_wali_read_published" ON "Ujian";
CREATE POLICY "uj_wali_read_published"
  ON "Ujian" FOR SELECT
  TO authenticated
  USING (
    "isPublished" = true
    AND has_role('WALI')
    AND "deletedAt" IS NULL
  );

DROP POLICY IF EXISTS "up_wali_read_own" ON "UjianPeserta";
CREATE POLICY "up_wali_read_own"
  ON "UjianPeserta" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND is_wali_of_santri("santriId")
  );

DROP POLICY IF EXISTS "us_wali_read_published" ON "UjianSoal";
CREATE POLICY "us_wali_read_published"
  ON "UjianSoal" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "ujianId" IN (
      SELECT u.id FROM "Ujian" u
      WHERE u."isPublished" = true
        AND u."deletedAt" IS NULL
        AND EXISTS (
          SELECT 1 FROM "UjianPeserta" up
          WHERE up."ujianId" = u.id
            AND is_wali_of_santri(up."santriId")
        )
    )
  );

DROP POLICY IF EXISTS "bs_wali_read_published" ON "BankSoal";
CREATE POLICY "bs_wali_read_published"
  ON "BankSoal" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND id IN (
      SELECT us."bankSoalId" FROM "UjianSoal" us
      WHERE us."ujianId" IN (
        SELECT u.id FROM "Ujian" u
        WHERE u."isPublished" = true
          AND u."deletedAt" IS NULL
      )
    )
  );

DROP POLICY IF EXISTS "tug_wali_read_published" ON "Tugas";
CREATE POLICY "tug_wali_read_published"
  ON "Tugas" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "isPublished" = true
    AND "deletedAt" IS NULL
    AND "kelasId" IN (
      SELECT s."kelasId" FROM "SantriWali" sw
      JOIN "Santri" s ON s.id = sw."santriId"
      WHERE sw."waliId" = current_wali_id()
        AND sw."canAccess" = true
        AND s."deletedAt" IS NULL
    )
  );

DROP POLICY IF EXISTS "per_wali_read_own" ON "Pertemuan";
CREATE POLICY "per_wali_read_own"
  ON "Pertemuan" FOR SELECT
  TO authenticated
  USING (
    has_role('WALI')
    AND "kelasId" IN (
      SELECT s."kelasId" FROM "SantriWali" sw
      JOIN "Santri" s ON s.id = sw."santriId"
      WHERE sw."waliId" = current_wali_id()
        AND sw."canAccess" = true
        AND s."deletedAt" IS NULL
    )
  );

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000014_chat_message_insert_policy.sql
-- ==========================================================================


DROP POLICY IF EXISTS "cm_insert_participant" ON "ChatMessage";
CREATE POLICY "cm_insert_participant"
  ON "ChatMessage" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
        AND cr."isActive" = true
    ))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
        AND cr."isActive" = true
    ))
    OR (is_staff())
  );

DROP POLICY IF EXISTS "cm_update_participant" ON "ChatMessage";
CREATE POLICY "cm_update_participant"
  ON "ChatMessage" FOR UPDATE
  TO authenticated
  USING (
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
    ))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
    ))
    OR is_staff()
  )
  WITH CHECK (
    (has_role('WALI') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."waliId" = current_wali_id()
    ))
    OR (has_role('GURU') AND EXISTS (
      SELECT 1 FROM "ChatRoom" cr
      WHERE cr.id = "ChatMessage"."chatRoomId"
        AND cr."guruId" = current_guru_id()
    ))
    OR is_staff()
  );

DROP POLICY IF EXISTS "cm_delete_admin" ON "ChatMessage";
CREATE POLICY "cm_delete_admin"
  ON "ChatMessage" FOR DELETE
  TO authenticated
  USING (is_admin_level());

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000015_bcrypt_pin_and_wali_login_rpc.sql
-- ==========================================================================


CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  UPDATE "Wali"
  SET "pinHash" = crypt("pinHash", gen_salt('bf', 10))
  WHERE "pinHash" IS NOT NULL
    AND "pinHash" != ''
    AND "pinHash" NOT LIKE '$2%';

  RAISE NOTICE 'PIN hashing completed. Affected rows: %', ROW_COUNT;
END $$;

CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali RECORD;
  v_santri_list JSONB;
  v_result JSONB;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "phone" = p_phone
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor WhatsApp tidak terdaftar'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun Anda dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."activationStatus" != 'ACTIVE' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun belum aktif (status: ' || v_wali."activationStatus" || '). Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun terkunci. Coba lagi dalam ' ||
        EXTRACT(EPOCH FROM (v_wali."lockedUntil" - NOW()))::int / 60 ||
        ' menit.'
    );
  END IF;

  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = '' OR
     crypt(p_pin, v_wali."pinHash") != v_wali."pinHash" THEN

    UPDATE "Wali"
    SET "failedLoginAttempts" = COALESCE("failedLoginAttempts", 0) + 1,
        "lockedUntil" = CASE
          WHEN COALESCE("failedLoginAttempts", 0) + 1 >= 5
          THEN NOW() + INTERVAL '15 minutes'
          ELSE "lockedUntil"
        END
    WHERE id = v_wali.id;

    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN salah. Sisa percobaan: ' ||
        GREATEST(0, 5 - COALESCE(v_wali."failedLoginAttempts", 0) - 1)
    );
  END IF;

  UPDATE "Wali"
  SET "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'nis', s.nis,
    'nisn', s.nisn,
    'gender', s.gender,
    'kelasId', s."kelasId",
    'kelasName', k.name,
    'kelasCode', k.code,
    'status', s.status,
    'photoUrl', s."photoUrl",
    'birthDate', s."birthDate",
    'birthPlace', s."birthPlace",
    'address', s.address,
    'entryDate', s."entryDate"
  )), '[]'::jsonb) INTO v_santri_list
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id
    AND sw."canAccess" = true;

  v_result := jsonb_build_object(
    'success', true,
    'wali', jsonb_build_object(
      'id', v_wali.id,
      'name', v_wali.name,
      'phone', v_wali."phone",
      'email', v_wali."email",
      'nik', v_wali."nik",
      'occupation', v_wali."occupation",
      'address', v_wali."address",
      'photoUrl', v_wali."photoUrl",
      'relationship', v_wali."relationship",
      'activationStatus', v_wali."activationStatus",
      'userId', v_wali."userId",
      'lastLoginAt', NOW()
    ),
    'santriList', v_santri_list
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon;

CREATE OR REPLACE FUNCTION public.wali_set_pin(p_wali_id TEXT, p_new_pin TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_new_pin !~ '^\d{6}$' THEN
    RETURN false;
  END IF;

  UPDATE "Wali"
  SET "pinHash" = crypt(p_new_pin, gen_salt('bf', 10)),
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "otpCode" = NULL,
      "otpExpiresAt" = NULL
  WHERE id = p_wali_id
    AND "deletedAt" IS NULL;

  RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_set_pin(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_set_pin(TEXT, TEXT) TO anon;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000016_wali_auth_password.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'Wali' AND column_name = 'authPassword'
  ) THEN
    ALTER TABLE "Wali" ADD COLUMN "authPassword" TEXT;
    RAISE NOTICE 'Added authPassword column to Wali';
  END IF;
END $$;

DO $$
DECLARE
  v_wali RECORD;
  v_password TEXT;
BEGIN
  FOR v_wali IN
    SELECT id, email FROM "Wali"
    WHERE "deletedAt" IS NULL
      AND email IS NOT NULL AND email != ''
      AND ("authPassword" IS NULL OR "authPassword" = '')
  LOOP
    v_password := substring(
      regexp_replace(
        encode(gen_random_bytes(32), 'hex'),
        '[^a-zA-Z0-9]', '', 'g'
      ),
      1, 16
    );

    UPDATE "Wali" SET "authPassword" = v_password WHERE id = v_wali.id;
    RAISE NOTICE 'Generated authPassword for wali: %', v_wali.email;
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali RECORD;
  v_santri_list JSONB;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "phone" = p_phone
    AND "deletedAt" IS NULL
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Nomor WhatsApp tidak terdaftar');
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun dinonaktifkan.');
  END IF;

  IF v_wali."activationStatus" != 'ACTIVE' THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun belum aktif.');
  END IF;

  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object('success', false, 'message', 'Akun terkunci.');
  END IF;

  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = '' OR
     crypt(p_pin, v_wali."pinHash") != v_wali."pinHash" THEN
    UPDATE "Wali"
    SET "failedLoginAttempts" = COALESCE("failedLoginAttempts", 0) + 1,
        "lockedUntil" = CASE
          WHEN COALESCE("failedLoginAttempts", 0) + 1 >= 5 THEN NOW() + INTERVAL '15 minutes'
          ELSE "lockedUntil"
        END
    WHERE id = v_wali.id;
    RETURN jsonb_build_object('success', false, 'message', 'PIN salah.');
  END IF;

  UPDATE "Wali"
  SET "failedLoginAttempts" = 0, "lockedUntil" = NULL, "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id, 'name', s.name, 'nis', s.nis, 'nisn', s.nisn,
    'gender', s.gender, 'kelasId', s."kelasId", 'kelasName', k.name,
    'kelasCode', k.code, 'status', s.status, 'photoUrl', s."photoUrl",
    'birthDate', s."birthDate", 'birthPlace', s."birthPlace",
    'address', s.address, 'entryDate', s."entryDate"
  )), '[]'::jsonb) INTO v_santri_list
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id AND sw."canAccess" = true;

  RETURN jsonb_build_object(
    'success', true,
    'wali', jsonb_build_object(
      'id', v_wali.id, 'name', v_wali.name, 'phone', v_wali."phone",
      'email', v_wali."email", 'nik', v_wali."nik",
      'occupation', v_wali."occupation", 'address', v_wali."address",
      'photoUrl', v_wali."photoUrl", 'relationship', v_wali."relationship",
      'activationStatus', v_wali."activationStatus",
      'userId', v_wali."userId", 'lastLoginAt', NOW(),
      'authPassword', v_wali."authPassword"
    ),
    'santriList', v_santri_list
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000017_ujian_rls_policies.sql
-- ==========================================================================


DROP POLICY IF EXISTS "usesi_wali_select_own" ON "UjianSesi";
CREATE POLICY "usesi_wali_select_own"
  ON "UjianSesi" FOR SELECT
  TO authenticated
  USING (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

DROP POLICY IF EXISTS "usesi_wali_insert_own" ON "UjianSesi";
CREATE POLICY "usesi_wali_insert_own"
  ON "UjianSesi" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

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

DROP POLICY IF EXISTS "ujaw_wali_insert_own" ON "UjianJawaban";
CREATE POLICY "ujaw_wali_insert_own"
  ON "UjianJawaban" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

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

DROP POLICY IF EXISTS "pt_wali_insert_own" ON "PengumpulanTugas";
CREATE POLICY "pt_wali_insert_own"
  ON "PengumpulanTugas" FOR INSERT
  TO authenticated
  WITH CHECK (
    (has_role('WALI') AND is_wali_of_santri("santriId"))
    OR is_staff()
  );

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

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000018_system_setting_public_columns.sql
-- ==========================================================================


ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "description" TEXT;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "isPublic" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "SystemSetting_isPublic_idx" ON "SystemSetting" ("isPublic");

UPDATE "SystemSetting"
SET "description" = CASE "key"
  WHEN 'MADRASAH_NAME'    THEN 'Nama resmi madrasah (tampil di app & rapor)'
  WHEN 'MADRASAH_ADDRESS' THEN 'Alamat madrasah'
  WHEN 'MADRASAH_PHONE'   THEN 'Nomor telepon madrasah'
  WHEN 'MADRASAH_HEAD'    THEN 'Nama kepala madrasah (tanda tangan rapor)'
  WHEN 'ACTIVE_TA_ID'     THEN 'ID tahun ajaran aktif'
  WHEN 'ACTIVE_SEMESTER_ID' THEN 'ID semester aktif'
  ELSE "description"
END
WHERE "description" IS NULL;

UPDATE "SystemSetting"
SET "isPublic" = true
WHERE "key" IN (
  'MADRASAH_NAME', 'MADRASAH_ADDRESS', 'MADRASAH_PHONE',
  'MADRASAH_LOGO', 'MADRASAH_HEAD', 'APP_MIN_VERSION'
);

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000019_user_password_hash_nullable.sql
-- ==========================================================================


ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;

UPDATE "User" SET "passwordHash" = '' WHERE "passwordHash" IS NULL;

ALTER TABLE "User" ALTER COLUMN "passwordHash" SET DEFAULT '';

COMMENT ON COLUMN "User"."passwordHash" IS
  'LEGACY / TIDAK DIPAKAI. Kredensial dikelola Supabase Auth (auth.users). '
  'Tabel User hanya menyimpan profil + firebaseUid (Supabase Auth UID).';

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000020_wali_pin_reset_secure.sql
-- ==========================================================================


CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.normalize_phone(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v TEXT;
BEGIN
  IF p_phone IS NULL THEN
    RETURN NULL;
  END IF;
  v := regexp_replace(p_phone, '\D', '', 'g');
  IF v = '' THEN
    RETURN NULL;
  END IF;
  IF left(v, 1) = '0' THEN
    v := '62' || substr(v, 2);
  ELSIF left(v, 2) = '62' THEN
    NULL;
  ELSIF left(v, 1) = '8' THEN
    v := '62' || v;
  END IF;
  RETURN v;
END;
$$;

CREATE TABLE IF NOT EXISTS "WaliPinReset" (
  "id"          TEXT NOT NULL PRIMARY KEY,
  "waliId"      TEXT NOT NULL,
  "otpHash"     TEXT NOT NULL,
  "expiresAt"   TIMESTAMPTZ NOT NULL,
  "attempts"    INTEGER NOT NULL DEFAULT 0,
  "consumedAt"  TIMESTAMPTZ,
  "resetTokenHash" TEXT,
  "resetTokenExpiresAt" TIMESTAMPTZ,
  "requestedIp" TEXT,
  "createdAt"   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT "WaliPinReset_waliId_fkey"
    FOREIGN KEY ("waliId") REFERENCES "Wali"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "WaliPinReset_waliId_createdAt_idx"
  ON "WaliPinReset" ("waliId", "createdAt" DESC);
CREATE INDEX IF NOT EXISTS "WaliPinReset_resetTokenHash_idx"
  ON "WaliPinReset" ("resetTokenHash");

ALTER TABLE "WaliPinReset" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "WaliPinReset" FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.wali_request_otp(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali      RECORD;
  v_req_count INTEGER;
  v_otp       TEXT;
  v_debug     TEXT;
  v_reset_id  TEXT;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'Jika nomor terdaftar, kode OTP akan dikirim via WhatsApp.'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  SELECT count(*) INTO v_req_count
  FROM "WaliPinReset"
  WHERE "waliId" = v_wali.id
    AND "createdAt" > now() - INTERVAL '1 hour';

  IF v_req_count >= 5 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Terlalu banyak permintaan OTP. Coba lagi dalam 1 jam.'
    );
  END IF;

  v_otp := lpad(
    (floor(random() * 1000000))::int::text, 6, '0'
  );

  UPDATE "WaliPinReset"
  SET "consumedAt" = now()
  WHERE "waliId" = v_wali.id
    AND "consumedAt" IS NULL;

  INSERT INTO "WaliPinReset" (
    "id", "waliId", "otpHash", "expiresAt", "createdAt"
  ) VALUES (
    replace(gen_random_uuid()::text, '-', ''),
    v_wali.id,
    crypt(v_otp, gen_salt('bf', 10)),
    now() + INTERVAL '5 minutes',
    now()
  )
  RETURNING "id" INTO v_reset_id;

  INSERT INTO "Notifikasi" (
    "id", "waliId", "type", "title", "message", "isRead", "createdAt"
  ) VALUES (
    replace(gen_random_uuid()::text, '-', ''),
    v_wali.id,
    'SYSTEM',
    'Kode OTP Reset PIN',
    'Kode OTP Anda: ' || v_otp || '. Berlaku 5 menit. Jangan bagikan ke siapa pun.',
    false,
    now()
  );

  SELECT value INTO v_debug FROM "SystemSetting" WHERE key = 'OTP_DEBUG' LIMIT 1;

  IF v_debug = 'true' THEN
    RETURN jsonb_build_object(
      'success', true,
      'message', 'OTP dibuat (mode debug).',
      'otp', v_otp
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Kode OTP dikirim via notifikasi WhatsApp.'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.wali_verify_otp(p_phone TEXT, p_otp TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali      RECORD;
  v_row       RECORD;
  v_token     TEXT;
BEGIN
  IF p_otp IS NULL OR p_otp !~ '^\d{6}$' THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP harus 6 digit.');
  END IF;

  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP salah atau kedaluwarsa.');
  END IF;

  SELECT * INTO v_row
  FROM "WaliPinReset"
  WHERE "waliId" = v_wali.id
    AND "consumedAt" IS NULL
    AND "expiresAt" > now()
  ORDER BY "createdAt" DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'OTP salah atau kedaluwarsa.');
  END IF;

  IF v_row.attempts >= 5 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Terlalu banyak percobaan. Minta OTP baru.'
    );
  END IF;

  IF crypt(p_otp, v_row."otpHash") <> v_row."otpHash" THEN
    UPDATE "WaliPinReset" SET "attempts" = "attempts" + 1 WHERE "id" = v_row.id;
    RETURN jsonb_build_object(
      'success', false,
      'message', 'OTP salah. Sisa percobaan: ' || (4 - v_row.attempts)
    );
  END IF;

  v_token := encode(gen_random_bytes(32), 'hex');

  UPDATE "WaliPinReset"
  SET "consumedAt" = now(),
      "resetTokenHash" = encode(digest(v_token, 'sha256'), 'hex'),
      "resetTokenExpiresAt" = now() + INTERVAL '10 minutes'
  WHERE "id" = v_row.id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP terverifikasi.',
    'resetToken', v_token
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.wali_reset_pin(p_reset_token TEXT, p_new_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_row RECORD;
BEGIN
  IF p_new_pin IS NULL OR p_new_pin !~ '^\d{6}$' THEN
    RETURN jsonb_build_object('success', false, 'message', 'PIN harus 6 digit.');
  END IF;

  IF p_reset_token IS NULL OR length(p_reset_token) < 32 THEN
    RETURN jsonb_build_object('success', false, 'message', 'Token reset tidak valid.');
  END IF;

  SELECT * INTO v_row
  FROM "WaliPinReset"
  WHERE "resetTokenHash" = encode(digest(p_reset_token, 'sha256'), 'hex')
    AND "resetTokenExpiresAt" > now()
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Token reset tidak valid atau kedaluwarsa. Ulangi dari minta OTP.'
    );
  END IF;

  UPDATE "Wali"
  SET "pinHash" = crypt(p_new_pin, gen_salt('bf', 10)),
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "otpCode" = NULL,
      "otpExpiresAt" = NULL
  WHERE "id" = v_row."waliId"
    AND "deletedAt" IS NULL;

  UPDATE "WaliPinReset"
  SET "resetTokenHash" = NULL,
      "resetTokenExpiresAt" = NULL
  WHERE "id" = v_row.id;

  RETURN jsonb_build_object('success', true, 'message', 'PIN berhasil diubah.');
END;
$$;

DROP FUNCTION IF EXISTS public.wali_set_pin(TEXT, TEXT);

GRANT EXECUTE ON FUNCTION public.wali_request_otp(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_verify_otp(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_reset_pin(TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000021_wali_login_normalize_phone.sql
-- ==========================================================================


DO $$
BEGIN
  IF to_regproc('public.normalize_phone') IS NULL THEN
    RAISE EXCEPTION
      'public.normalize_phone() belum ada — jalankan migration 20 dulu';
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.wali_login(p_phone TEXT, p_pin TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali        RECORD;
  v_santri_list JSONB;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor WhatsApp tidak terdaftar'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun Anda dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."activationStatus" <> 'ACTIVE' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message',
      'Akun belum aktif (status: ' || v_wali."activationStatus" ||
      '). Hubungi admin madrasah.'
    );
  END IF;

  IF v_wali."lockedUntil" IS NOT NULL AND v_wali."lockedUntil" > NOW() THEN
    RETURN jsonb_build_object(
      'success', false,
      'message',
      'Akun terkunci. Coba lagi dalam ' ||
      (EXTRACT(EPOCH FROM (v_wali."lockedUntil" - NOW()))::int / 60) ||
      ' menit.'
    );
  END IF;

  IF v_wali."pinHash" IS NULL OR v_wali."pinHash" = ''
     OR crypt(p_pin, v_wali."pinHash") <> v_wali."pinHash" THEN
    UPDATE "Wali"
    SET "failedLoginAttempts" = COALESCE("failedLoginAttempts", 0) + 1,
        "lockedUntil" = CASE
          WHEN COALESCE("failedLoginAttempts", 0) + 1 >= 5
          THEN NOW() + INTERVAL '15 minutes'
          ELSE "lockedUntil"
        END
    WHERE id = v_wali.id;

    RETURN jsonb_build_object(
      'success', false,
      'message',
      'PIN salah. Sisa percobaan: ' ||
      GREATEST(0, 5 - COALESCE(v_wali."failedLoginAttempts", 0) - 1)
    );
  END IF;

  UPDATE "Wali"
  SET "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "lastLoginAt" = NOW()
  WHERE id = v_wali.id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'name', s.name,
    'nis', s.nis,
    'nisn', s.nisn,
    'gender', s.gender,
    'kelasId', s."kelasId",
    'kelasName', k.name,
    'kelasCode', k.code,
    'status', s.status,
    'photoUrl', s."photoUrl",
    'birthDate', s."birthDate",
    'birthPlace', s."birthPlace",
    'address', s.address,
    'entryDate', s."entryDate"
  )), '[]'::jsonb) INTO v_santri_list
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id
    AND sw."canAccess" = true;

  RETURN jsonb_build_object(
    'success', true,
    'wali', jsonb_build_object(
      'id', v_wali.id,
      'name', v_wali.name,
      'phone', v_wali."phone",
      'email', v_wali."email",
      'nik', v_wali."nik",
      'occupation', v_wali."occupation",
      'address', v_wali."address",
      'photoUrl', v_wali."photoUrl",
      'relationship', v_wali."relationship",
      'activationStatus', v_wali."activationStatus",
      'userId', v_wali."userId",
      'lastLoginAt', NOW(),
      'authPassword', v_wali."authPassword"
    ),
    'santriList', v_santri_list
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.wali_login(TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000022_realtime_publication_complete.sql
-- ==========================================================================


DO $$
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    'TahunAjaran',
    'Semester',
    'JenisTagihan',
    'Wali',
    'User',
    'UserRole',
    'Role',
    'RolePermission',
    'SystemSetting',
    'Kompetensi',
    'Rapor',
    'CatatanWaliKelas',
    'PerkembanganQuran'
  ];
  added INT := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime
      WITH (publish = 'insert, update, delete, truncate');
  END IF;

  FOREACH tbl IN ARRAY tables LOOP
    IF to_regclass(format('public.%I', tbl)) IS NULL THEN
      RAISE NOTICE 'Lewati %: tabel belum ada', tbl;
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = tbl
    ) THEN
      CONTINUE;
    END IF;

    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl
      );
      added := added + 1;
      RAISE NOTICE 'Ditambahkan ke realtime: %', tbl;
    EXCEPTION
      WHEN duplicate_object THEN
        NULL; -- balapan dengan migrasi lain, aman diabaikan
      WHEN OTHERS THEN
        RAISE NOTICE 'Gagal menambahkan %: %', tbl, SQLERRM;
    END;
  END LOOP;

  RAISE NOTICE 'Selesai. % tabel baru ditambahkan ke publication.', added;
END $$;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000023_wali_auth_provisioning.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.provision_wali_auth(
  p_wali_id TEXT,
  p_auth_uid UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali     RECORD;
  v_user_id  TEXT;
  v_role_id  TEXT;
  v_uid      UUID;
BEGIN
  SELECT * INTO v_wali FROM "Wali" WHERE id = p_wali_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Wali tidak ditemukan');
  END IF;

  IF v_wali."deletedAt" IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Wali sudah dihapus');
  END IF;

  v_uid := p_auth_uid;
  IF v_uid IS NULL AND v_wali.email IS NOT NULL AND v_wali.email <> '' THEN
    SELECT id INTO v_uid FROM auth.users WHERE email = v_wali.email LIMIT 1;
  END IF;

  SELECT id INTO v_user_id
  FROM "User"
  WHERE "firebaseUid" = v_uid::text
     OR (v_wali.email IS NOT NULL AND email = v_wali.email)
  LIMIT 1;

  IF v_user_id IS NULL THEN
    IF v_uid IS NULL THEN
      RETURN jsonb_build_object(
        'success', false,
        'message',
        'Akun Supabase Auth untuk wali ini belum ada. Buat user auth dulu '
        '(email wali) atau kirim p_auth_uid.'
      );
    END IF;

    INSERT INTO "User" (
      id, email, username, "passwordHash", name, phone,
      "firebaseUid", "isActive", "createdAt", "updatedAt"
    ) VALUES (
      replace(gen_random_uuid()::text, '-', ''),
      COALESCE(v_wali.email, 'wali+' || v_wali.id || '@madrasah.local'),
      'wali_' || left(v_wali.id, 12),
      '',
      v_wali.name,
      v_wali."phone",
      v_uid::text,
      true,
      now(),
      now()
    )
    RETURNING id INTO v_user_id;
  ELSE
    UPDATE "User"
    SET "firebaseUid" = COALESCE("firebaseUid", v_uid::text),
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  UPDATE "Wali"
  SET "userId" = v_user_id, "updatedAt" = now()
  WHERE id = p_wali_id
    AND ("userId" IS DISTINCT FROM v_user_id);

  SELECT id INTO v_role_id FROM "Role" WHERE code = 'WALI' LIMIT 1;
  IF v_role_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Role WALI belum ada. Jalankan migration 3 (bootstrap roles).'
    );
  END IF;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (
    replace(gen_random_uuid()::text, '-', ''), v_user_id, v_role_id, true, now()
  )
  ON CONFLICT ("userId", "roleId") DO UPDATE
  SET "isActive" = true;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Akun wali berhasil di-provision',
    'userId', v_user_id,
    'authUid', v_uid::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.check_wali_link(p_wali_id TEXT)
RETURNS TABLE (
  check_name TEXT,
  ok BOOLEAN,
  detail TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wali      RECORD;
  v_user      RECORD;
  v_role_id   TEXT;
  v_ur_active BOOLEAN;
  v_santri    INT;
  v_auth_uid  UUID;
BEGIN
  SELECT * INTO v_wali FROM "Wali" WHERE id = p_wali_id;

  check_name := 'wali_exists';
  ok := FOUND AND v_wali."deletedAt" IS NULL;
  detail := CASE WHEN FOUND THEN COALESCE(v_wali.name, '-') ELSE 'Wali tidak ada' END;
  RETURN NEXT;
  IF NOT ok THEN RETURN; END IF;

  check_name := 'activation_status';
  ok := v_wali."activationStatus" = 'ACTIVE';
  detail := COALESCE(v_wali."activationStatus", 'NULL');
  RETURN NEXT;

  check_name := 'pin_hash_set';
  ok := v_wali."pinHash" IS NOT NULL AND v_wali."pinHash" LIKE '$2%';
  detail := CASE
    WHEN v_wali."pinHash" IS NULL THEN 'PIN belum diset'
    WHEN v_wali."pinHash" NOT LIKE '$2%' THEN 'PIN masih plain-text (jalankan migration 15)'
    ELSE 'bcrypt ok' END;
  RETURN NEXT;

  check_name := 'auth_password_set';
  ok := v_wali."authPassword" IS NOT NULL AND v_wali."authPassword" <> '';
  detail := CASE WHEN ok THEN 'ada' ELSE 'kosong (jalankan migration 16)' END;
  RETURN NEXT;

  check_name := 'wali_user_linked';
  ok := v_wali."userId" IS NOT NULL;
  detail := COALESCE(v_wali."userId", 'Wali.userId NULL');
  RETURN NEXT;

  IF NOT ok THEN RETURN; END IF;

  SELECT * INTO v_user FROM "User" WHERE id = v_wali."userId";

  check_name := 'user_firebase_uid';
  ok := v_user."firebaseUid" IS NOT NULL;
  detail := COALESCE(v_user."firebaseUid", 'User.firebaseUid NULL');
  RETURN NEXT;

  IF ok THEN
    BEGIN
      SELECT au.id INTO v_auth_uid
      FROM auth.users au
      WHERE au.id = v_user."firebaseUid"::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      v_auth_uid := NULL;
    END;

    check_name := 'auth_user_exists';
    ok := v_auth_uid IS NOT NULL;
    detail := CASE WHEN ok THEN v_auth_uid::text
                   ELSE 'Tidak ada di auth.users (provision dulu)' END;
    RETURN NEXT;
  END IF;

  SELECT id INTO v_role_id FROM "Role" WHERE code = 'WALI' LIMIT 1;
  check_name := 'role_wali_exists';
  ok := v_role_id IS NOT NULL;
  detail := COALESCE(v_role_id, 'Role WALI tidak ada');
  RETURN NEXT;

  IF ok THEN
    SELECT ur."isActive" INTO v_ur_active
    FROM "UserRole" ur
    WHERE ur."userId" = v_wali."userId" AND ur."roleId" = v_role_id;
    check_name := 'has_active_role_wali';
    ok := COALESCE(v_ur_active, false);
    detail := CASE WHEN ok THEN 'aktif' ELSE 'UserRole WALI tidak aktif/tidak ada' END;
    RETURN NEXT;
  END IF;

  SELECT count(*) INTO v_santri
  FROM "SantriWali" sw
  WHERE sw."waliId" = p_wali_id AND sw."canAccess" = true;
  check_name := 'linked_santri';
  ok := v_santri > 0;
  detail := v_santri || ' santri';
  RETURN NEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.provision_wali_auth(TEXT, UUID) FROM anon;
REVOKE ALL ON FUNCTION public.check_wali_link(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.provision_wali_auth(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.check_wali_link(TEXT) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000024_id_and_timestamp_defaults.sql
-- ==========================================================================


CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.fn_auto_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW."updatedAt" := now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  r RECORD;
  v_count INT := 0;
BEGIN
  FOR r IN
    SELECT c.table_name, c.column_name, c.data_type, c.is_nullable,
           c.column_default, t.column_name AS updated_col
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema
     AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    LEFT JOIN information_schema.columns u
      ON u.table_schema = c.table_schema
     AND u.table_name = c.table_name
     AND u.column_name = 'updatedAt'
    WHERE c.table_schema = 'public'
      AND c.column_name IN ('id', 'createdAt')
  LOOP
    IF r.column_name = 'id'
       AND r.data_type IN ('text', 'character varying', 'uuid')
       AND r.column_default IS NULL THEN
      BEGIN
        IF r.data_type = 'uuid' THEN
          EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN id SET DEFAULT gen_random_uuid()',
            r.table_name
          );
        ELSE
          EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN id SET DEFAULT '
            'replace(gen_random_uuid()::text, ''-'', '''')',
            r.table_name
          );
        END IF;
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default id untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;

    IF r.column_name = 'createdAt'
       AND r.is_nullable = 'NO'
       AND r.column_default IS NULL THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE public.%I ALTER COLUMN "createdAt" SET DEFAULT now()',
          r.table_name
        );
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default createdAt untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  FOR r IN
    SELECT c.table_name, c.is_nullable, c.column_default
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
  LOOP
    IF r.is_nullable = 'NO' AND r.column_default IS NULL THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE public.%I ALTER COLUMN "updatedAt" SET DEFAULT now()',
          r.table_name
        );
        v_count := v_count + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Gagal set default updatedAt untuk %: %', r.table_name, SQLERRM;
      END;
    END IF;
  END LOOP;

  FOR r IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
      AND c.is_nullable = 'YES'
  LOOP
    BEGIN
      EXECUTE format(
        'UPDATE public.%I SET "updatedAt" = now() WHERE "updatedAt" IS NULL',
        r.table_name
      );
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;

  RAISE NOTICE 'Selesai: % default kolom ditambahkan.', v_count;
END $$;

DO $$
DECLARE
  r RECORD;
  v_count INT := 0;
BEGIN
  FOR r IN
    SELECT c.table_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public'
      AND c.column_name = 'updatedAt'
    ORDER BY c.table_name
  LOOP
    BEGIN
      EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON public.%I',
        'trg_' || r.table_name || '_updated_at', r.table_name
      );
      EXECUTE format(
        'CREATE TRIGGER %I BEFORE UPDATE ON public.%I '
        'FOR EACH ROW EXECUTE FUNCTION public.fn_auto_updated_at()',
        'trg_' || r.table_name || '_updated_at', r.table_name
      );
      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Gagal pasang trigger updatedAt untuk %: %', r.table_name, SQLERRM;
    END;
  END LOOP;
  RAISE NOTICE 'Selesai: % trigger updatedAt dipasang.', v_count;
END $$;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000025_ujian_server_side_time_limit.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.ujian_remaining_seconds(p_sesi_id TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sesi     RECORD;
  v_duration INTEGER;
  v_elapsed  INTEGER;
BEGIN
  SELECT s.id, s."startTime", s.status, u."durationMnt"
    INTO v_sesi
  FROM "UjianSesi" s
  JOIN "Ujian" u ON u.id = s."ujianId"
  WHERE s.id = p_sesi_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN 0;
  END IF;

  v_duration := COALESCE(v_sesi."durationMnt", 90) * 60;
  v_elapsed  := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(v_sesi."startTime", NOW())))::INT
  );

  RETURN GREATEST(0, v_duration - v_elapsed);
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_ujian(
  p_sesi_id TEXT,
  p_answers JSONB
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  final_score DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sesi        RECORD;
  v_soal        RECORD;
  v_existing    RECORD;
  v_total_score DOUBLE PRECISION := 0;
  v_total_bobot DOUBLE PRECISION := 0;
  v_final_score DOUBLE PRECISION;
  v_answer_item JSONB;
  v_elapsed     INTEGER;
  v_duration    INTEGER;
  v_tolerance   INTEGER := 90;  -- detik
  v_late        BOOLEAN := FALSE;
  v_answer      TEXT;
  v_is_correct  BOOLEAN;
BEGIN
  SELECT s.id, s."ujianId", s."santriId", s.status, s."startTime",
         s.score, u."durationMnt"
    INTO v_sesi
  FROM "UjianSesi" s
  JOIN "Ujian" u ON u.id = s."ujianId"
  WHERE s.id = p_sesi_id
  FOR UPDATE OF s;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Sesi ujian tidak ditemukan'::TEXT,
      0.0::DOUBLE PRECISION;
    RETURN;
  END IF;

  IF v_sesi.status = 'FINISHED' THEN
    RETURN QUERY SELECT FALSE, 'Ujian sudah selesai'::TEXT,
      COALESCE(v_sesi.score, 0.0::DOUBLE PRECISION);
    RETURN;
  END IF;

  v_duration := COALESCE(v_sesi."durationMnt", 90) * 60;
  v_elapsed  := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(v_sesi."startTime", NOW())))::INT
  );
  v_late := v_elapsed > (v_duration + v_tolerance);

  IF p_answers IS NOT NULL THEN
    FOR v_answer_item IN SELECT * FROM jsonb_array_elements(p_answers)
    LOOP
      SELECT us.id, us.bobot, bs.type, bs."correctAnswer"
        INTO v_soal
      FROM "UjianSoal" us
      JOIN "BankSoal" bs ON bs.id = us."bankSoalId"
      WHERE us.id = v_answer_item->>'ujianSoalId';

      IF NOT FOUND THEN
        CONTINUE;
      END IF;

      v_answer := v_answer_item->>'answer';

      IF v_soal.type = 'PG' THEN
        v_total_bobot := v_total_bobot + COALESCE(v_soal.bobot, 1.0);
        v_is_correct := UPPER(COALESCE(v_answer, ''))
                        = UPPER(COALESCE(v_soal."correctAnswer", '~'));

        IF v_is_correct THEN
          v_total_score := v_total_score + COALESCE(v_soal.bobot, 1.0);
        END IF;

        INSERT INTO "UjianJawaban" (
          id, "sesiId", "ujianSoalId", "santriId", answer,
          "isCorrect", score, "isAutoCorrected", "createdAt", "updatedAt"
        ) VALUES (
          gen_random_uuid()::text, p_sesi_id,
          v_answer_item->>'ujianSoalId', v_sesi."santriId",
          v_answer, v_is_correct,
          CASE WHEN v_is_correct THEN COALESCE(v_soal.bobot, 1.0) ELSE 0 END,
          true, NOW(), NOW()
        )
        ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
          answer = EXCLUDED.answer,
          "isCorrect" = EXCLUDED."isCorrect",
          score = EXCLUDED.score,
          "isAutoCorrected" = true,
          "updatedAt" = NOW();
      ELSE
        INSERT INTO "UjianJawaban" (
          id, "sesiId", "ujianSoalId", "santriId", answer,
          "isAutoCorrected", "createdAt", "updatedAt"
        ) VALUES (
          gen_random_uuid()::text, p_sesi_id,
          v_answer_item->>'ujianSoalId', v_sesi."santriId",
          v_answer, false, NOW(), NOW()
        )
        ON CONFLICT ("sesiId", "ujianSoalId") DO UPDATE SET
          answer = EXCLUDED.answer,
          "updatedAt" = NOW();
      END IF;
    END LOOP;
  END IF;

  v_final_score := CASE WHEN v_total_bobot > 0
    THEN (v_total_score / v_total_bobot) * 100
    ELSE 0 END;

  UPDATE "UjianSesi"
  SET status = 'FINISHED',
      "endTime" = NOW(),
      score = v_final_score,
      "durationUsed" = LEAST(GREATEST(v_elapsed, 0), v_duration + v_tolerance),
      "isAutoCorrected" = true,
      "updatedAt" = NOW()
  WHERE id = p_sesi_id;

  SELECT id INTO v_existing
  FROM "UjianNilai"
  WHERE "ujianId" = v_sesi."ujianId" AND "santriId" = v_sesi."santriId";

  IF FOUND THEN
    UPDATE "UjianNilai"
    SET score = v_final_score,
        "isAutoCorrect" = true,
        "gradedAt" = NOW(),
        notes = CASE WHEN v_late THEN
          'Dikumpulkan melewati batas waktu (' || v_elapsed || ' dari '
          || v_duration || ' detik) — perlu ditinjau guru.'
          ELSE notes END,
        "updatedAt" = NOW()
    WHERE id = v_existing.id;
  ELSE
    INSERT INTO "UjianNilai" (
      id, "ujianId", "santriId", score, "isAutoCorrect", "gradedAt",
      notes, "createdAt", "updatedAt"
    ) VALUES (
      gen_random_uuid()::text, v_sesi."ujianId", v_sesi."santriId",
      v_final_score, true, NOW(),
      CASE WHEN v_late THEN
        'Dikumpulkan melewati batas waktu (' || v_elapsed || ' dari '
        || v_duration || ' detik) — perlu ditinjau guru.' ELSE NULL END,
      NOW(), NOW()
    );
  END IF;

  IF v_late THEN
    RETURN QUERY SELECT TRUE,
      ('Dikumpulkan terlambat (' || v_elapsed || ' detik) — ditandai untuk '
       || 'ditinjau guru.')::TEXT, v_final_score;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'OK'::TEXT, v_final_score;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ujian_remaining_seconds(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_ujian(TEXT, JSONB) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000026_access_diagnostics_and_provisioning.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.diagnose_account_access(p_email TEXT)
RETURNS TABLE(
  step TEXT,
  ok BOOLEAN,
  detail TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id   UUID;
  v_user_id   TEXT;
  v_active    BOOLEAN;
  v_roles     TEXT;
  v_guru_id   TEXT;
  v_wali_id   TEXT;
  v_santri_ct INT;
  v_kelas_ct  INT;
BEGIN
  SELECT au.id INTO v_auth_id
  FROM auth.users au
  WHERE lower(au.email) = lower(trim(p_email));

  step := 'auth_user_exists';
  ok := v_auth_id IS NOT NULL;
  detail := CASE WHEN ok THEN v_auth_id::TEXT
                 ELSE 'Tidak ada akun login dengan email ini. Buat dulu di Supabase Auth.' END;
  RETURN NEXT;

  IF NOT ok THEN
    RETURN;
  END IF;

  SELECT u.id, u."isActive" INTO v_user_id, v_active
  FROM "User" u
  WHERE u."firebaseUid" = v_auth_id::TEXT
     OR lower(u.email) = lower(trim(p_email))
  ORDER BY (u."firebaseUid" = v_auth_id::TEXT) DESC NULLS LAST
  LIMIT 1;

  step := 'user_row_linked';
  ok := v_user_id IS NOT NULL;
  detail := CASE WHEN ok
                 THEN 'User.id = ' || v_user_id
                 ELSE 'Tidak ada baris "User" yang terhubung ke auth.uid. Jalankan provision_account_role().' END;
  RETURN NEXT;

  IF NOT ok THEN
    RETURN;
  END IF;

  step := 'user_active';
  ok := COALESCE(v_active, false);
  detail := CASE WHEN ok THEN 'Aktif' ELSE 'User.isActive = false — akun dinonaktifkan.' END;
  RETURN NEXT;

  SELECT string_agg(r.code, ', ' ORDER BY r.code) INTO v_roles
  FROM "UserRole" ur
  JOIN "Role" r ON r.id = ur."roleId"
  WHERE ur."userId" = v_user_id
    AND ur."isActive" = true;

  step := 'has_role';
  ok := v_roles IS NOT NULL;
  detail := CASE WHEN ok
                 THEN 'Peran: ' || v_roles
                 ELSE 'TIDAK PUNYA PERAN — semua data akan tampak kosong. Jalankan provision_account_role().' END;
  RETURN NEXT;

  IF v_roles IS NULL THEN
    RETURN;
  END IF;

  IF v_roles LIKE '%GURU%' THEN
    SELECT g.id INTO v_guru_id FROM "Guru" g
    WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

    step := 'guru_row_exists';
    ok := v_guru_id IS NOT NULL;
    detail := CASE WHEN ok
                   THEN 'Guru.id = ' || v_guru_id
                   ELSE 'Belum ada baris "Guru". current_guru_id() = NULL sehingga data kelas/absensi kosong. Jalankan provision_guru_profile().' END;
    RETURN NEXT;

    IF v_guru_id IS NOT NULL THEN
      SELECT count(DISTINCT j."kelasId") INTO v_kelas_ct
      FROM "Jadwal" j WHERE j."guruId" = v_guru_id;

      step := 'guru_has_kelas';
      ok := COALESCE(v_kelas_ct, 0) > 0;
      detail := CASE WHEN ok
                     THEN v_kelas_ct || ' kelas terdaftar'
                     ELSE 'Guru belum dijadwalkan ke kelas mana pun. is_guru_of_kelas() selalu false sehingga absensi/nilai tidak bisa diisi.' END;
      RETURN NEXT;
    END IF;
  END IF;

  IF v_roles LIKE '%WALI%' THEN
    SELECT w.id INTO v_wali_id FROM "Wali" w
    WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

    step := 'wali_row_exists';
    ok := v_wali_id IS NOT NULL;
    detail := CASE WHEN ok
                   THEN 'Wali.id = ' || v_wali_id
                   ELSE 'Belum ada baris "Wali". Jalankan provision_wali_profile().' END;
    RETURN NEXT;

    IF v_wali_id IS NOT NULL THEN
      SELECT count(*) INTO v_santri_ct
      FROM "SantriWali" sw WHERE sw."waliId" = v_wali_id;

      step := 'wali_has_santri';
      ok := COALESCE(v_santri_ct, 0) > 0;
      detail := CASE WHEN ok
                     THEN v_santri_ct || ' santri tertaut'
                     ELSE 'Wali belum tertaut ke santri mana pun — dashboard akan kosong.' END;
      RETURN NEXT;
    END IF;
  END IF;

  RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.provision_account_role(
  p_email     TEXT,
  p_role_code TEXT,
  p_full_name TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_id UUID;
  v_user_id TEXT;
  v_role_id TEXT;
  v_name    TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM "Role" WHERE code = p_role_code) THEN
    RETURN QUERY SELECT FALSE,
      format('Peran "%s" tidak dikenal. Pilihan: SUPER_ADMIN, ADMIN, KEPALA, '
             'BENDAHARA, GURU, WALI.', p_role_code);
    RETURN;
  END IF;

  SELECT au.id, COALESCE(p_full_name, au.raw_user_meta_data->>'name',
                         split_part(au.email, '@', 1))
    INTO v_auth_id, v_name
  FROM auth.users au
  WHERE lower(au.email) = lower(trim(p_email));

  IF v_auth_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Email %s belum terdaftar di Supabase Auth. Buat akunnya dulu.',
             p_email);
    RETURN;
  END IF;

  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_auth_id::TEXT OR lower(u.email) = lower(trim(p_email))
  ORDER BY (u."firebaseUid" = v_auth_id::TEXT) DESC NULLS LAST
  LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, "firebaseUid", "isActive",
                        "createdAt", "updatedAt")
    VALUES (v_user_id, lower(trim(p_email)),
            split_part(lower(trim(p_email)), '@', 1),
            v_name, v_auth_id::TEXT, TRUE, now(), now());
  ELSE
    UPDATE "User"
    SET "firebaseUid" = v_auth_id::TEXT,
        "isActive" = TRUE,
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = p_role_code;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
  ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;

  RETURN QUERY SELECT TRUE,
    format('Berhasil: %s sekarang punya peran %s (User.id = %s).',
           p_email, p_role_code, v_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.provision_guru_profile(
  p_email         TEXT,
  p_nip           TEXT DEFAULT NULL,
  p_specialization TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id TEXT;
  v_name    TEXT;
  v_guru_id TEXT;
BEGIN
  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email) INTO v_user_id, v_name
  FROM "User" u
  WHERE lower(u.email) = lower(trim(p_email));

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  SELECT g.id INTO v_guru_id FROM "Guru" g
  WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

  IF v_guru_id IS NOT NULL THEN
    RETURN QUERY SELECT TRUE,
      format('Guru sudah ada untuk %s (Guru.id = %s).', p_email, v_guru_id);
    RETURN;
  END IF;

  v_guru_id := gen_random_uuid()::TEXT;

  INSERT INTO "Guru" (id, "userId", name, nip, specialization, status,
                      "joinDate", "createdAt", "updatedAt")
  VALUES (v_guru_id, v_user_id, v_name, p_nip, p_specialization, 'AKTIF',
          CURRENT_DATE, now(), now());

  RETURN QUERY SELECT TRUE,
    format('Profil Guru dibuat untuk %s (Guru.id = %s).', p_email, v_guru_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.provision_wali_profile(
  p_email       TEXT,
  p_nis_santri  TEXT DEFAULT NULL,
  p_relationship TEXT DEFAULT 'AYAH'
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id   TEXT;
  v_name      TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
BEGIN
  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email) INTO v_user_id, v_name
  FROM "User" u WHERE lower(u.email) = lower(trim(p_email));

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    INSERT INTO "Wali" (id, "userId", name, phone, "activationStatus",
                        "createdAt", "updatedAt")
    SELECT v_wali_id, v_user_id, v_name, u.phone, 'PENDING', now(), now()
    FROM "User" u WHERE u.id = v_user_id;
  END IF;

  IF p_nis_santri IS NULL THEN
    RETURN QUERY SELECT TRUE,
      format('Profil Wali siap (Wali.id = %s). Tautkan santri dengan NIS.', v_wali_id);
    RETURN;
  END IF;

  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = p_nis_santri AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Santri dengan NIS %s tidak ditemukan.', p_nis_santri);
    RETURN;
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", relationship, "isPrimary",
                            "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id,
          p_relationship, TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Wali %s tertaut ke santri NIS %s.', p_email, p_nis_santri);
END;
$$;

CREATE OR REPLACE FUNCTION public.assign_guru_to_kelas(
  p_email_guru TEXT,
  p_nama_kelas TEXT,
  p_nama_mapel TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guru_id  TEXT;
  v_kelas_id TEXT;
  v_mapel_id TEXT;
  v_ta_id    TEXT;
  v_sem_id   TEXT;
  v_ct       INT;
BEGIN
  SELECT g.id INTO v_guru_id
  FROM "Guru" g JOIN "User" u ON u.id = g."userId"
  WHERE lower(u.email) = lower(trim(p_email_guru)) AND g."deletedAt" IS NULL
  LIMIT 1;

  IF v_guru_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Guru untuk %s belum ada. Jalankan provision_guru_profile() dulu.', p_email_guru);
    RETURN;
  END IF;

  SELECT k.id INTO v_kelas_id FROM "Kelas" k
  WHERE lower(k.name) = lower(trim(p_nama_kelas)) AND k."deletedAt" IS NULL LIMIT 1;

  IF v_kelas_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Kelas "%s" tidak ditemukan.', p_nama_kelas);
    RETURN;
  END IF;

  IF p_nama_mapel IS NOT NULL THEN
    SELECT m.id INTO v_mapel_id FROM "MataPelajaran" m
    WHERE lower(m.name) = lower(trim(p_nama_mapel)) AND m."deletedAt" IS NULL LIMIT 1;
  END IF;

  SELECT count(*) INTO v_ct FROM "Jadwal" j
  WHERE j."guruId" = v_guru_id AND j."kelasId" = v_kelas_id
    AND (v_mapel_id IS NULL OR j."mapelId" = v_mapel_id);

  IF v_ct > 0 THEN
    RETURN QUERY SELECT TRUE, format('Guru sudah terjadwal di kelas "%s".', p_nama_kelas);
    RETURN;
  END IF;

  SELECT ta.id INTO v_ta_id FROM "TahunAjaran" ta
  WHERE ta."isActive" = TRUE AND ta."deletedAt" IS NULL LIMIT 1;
  IF v_ta_id IS NULL THEN
    SELECT ta.id INTO v_ta_id FROM "TahunAjaran" ta
    ORDER BY ta."createdAt" DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sem_id FROM "Semester" s
  WHERE s."tahunAjaranId" = v_ta_id AND s."isActive" = TRUE
  ORDER BY s."createdAt" DESC LIMIT 1;
  IF v_sem_id IS NULL THEN
    SELECT s.id INTO v_sem_id FROM "Semester" s
    WHERE s."tahunAjaranId" = v_ta_id ORDER BY s."createdAt" DESC LIMIT 1;
  END IF;

  IF v_ta_id IS NULL OR v_sem_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      'Belum ada TahunAjaran/Semester. Buat lewat aplikasi admin dulu '
      '(menu Tahun Ajaran) sebelum menjadwalkan guru.';
    RETURN;
  END IF;

  INSERT INTO "Jadwal" (id, "guruId", "kelasId", "mapelId", "tahunAjaranId",
                        "semesterId", "dayOfWeek", "startTime", "endTime",
                        "createdAt", "updatedAt")
  VALUES (gen_random_uuid()::TEXT, v_guru_id, v_kelas_id, v_mapel_id,
          v_ta_id, v_sem_id, 1, '07:00', '08:30', now(), now());

  RETURN QUERY SELECT TRUE,
    format('Guru %s ditautkan ke kelas "%s" (Jadwal dibuat).', p_email_guru, p_nama_kelas);
END;
$$;

CREATE OR REPLACE FUNCTION public.access_audit()
RETURNS TABLE(
  email        TEXT,
  user_id      TEXT,
  active       BOOLEAN,
  roles        TEXT,
  has_guru_row BOOLEAN,
  has_wali_row BOOLEAN,
  santri_count BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.email,
    u.id,
    COALESCE(u."isActive", FALSE),
    COALESCE((SELECT string_agg(r.code, ', ' ORDER BY r.code)
              FROM "UserRole" ur JOIN "Role" r ON r.id = ur."roleId"
              WHERE ur."userId" = u.id AND ur."isActive"), '— TANPA PERAN —'),
    EXISTS (SELECT 1 FROM "Guru" g WHERE g."userId" = u.id AND g."deletedAt" IS NULL),
    EXISTS (SELECT 1 FROM "Wali" w WHERE w."userId" = u.id AND w."deletedAt" IS NULL),
    (SELECT count(*) FROM "SantriWali" sw
     JOIN "Wali" w2 ON w2.id = sw."waliId"
     WHERE w2."userId" = u.id)
  FROM "User" u
  ORDER BY (u.email);
$$;

REVOKE ALL ON FUNCTION public.diagnose_account_access(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_account_role(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_guru_profile(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_wali_profile(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.assign_guru_to_kelas(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.access_audit() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000027_wali_test_account.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.provision_wali_profile(
  p_email        TEXT,
  p_nis_santri   TEXT DEFAULT NULL,
  p_relationship TEXT DEFAULT 'AYAH',
  p_phone        TEXT DEFAULT NULL,
  p_pin          TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id   TEXT;
  v_name      TEXT;
  v_phone     TEXT;
  v_email     TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
  v_pin       TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  v_email := lower(trim(p_email));

  SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email), u.phone
    INTO v_user_id, v_name, v_phone
  FROM "User" u WHERE lower(u.email) = v_email;

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('User %s belum ada. Jalankan provision_account_role() dulu.', p_email);
    RETURN;
  END IF;

  v_phone := COALESCE(NULLIF(trim(p_phone), ''), v_phone);
  IF v_phone IS NULL OR v_phone = '' THEN
    RETURN QUERY SELECT FALSE,
      'Nomor WhatsApp wajib: isi lewat parameter p_phone atau kolom User.phone. '
      'Tanpa nomor, wali tidak bisa login.';
    RETURN;
  END IF;

  v_pin := COALESCE(NULLIF(trim(p_pin), ''), '123456');

  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    INSERT INTO "Wali" (id, "userId", name, phone, email,
                        "activationStatus", "pinHash", "authPassword",
                        "createdAt", "updatedAt")
    VALUES (v_wali_id, v_user_id, v_name, v_phone, v_email,
            'ACTIVE',
            crypt(v_pin, gen_salt('bf', 10)),
            substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                     '[^a-zA-Z0-9]', '', 'g'), 1, 16),
            now(), now());
  ELSE
    UPDATE "Wali"
    SET phone = v_phone,
        email = COALESCE(NULLIF(email, ''), v_email),
        "activationStatus" = 'ACTIVE',
        "pinHash" = CASE
          WHEN p_pin IS NULL OR trim(p_pin) = '' THEN "pinHash"
          ELSE crypt(v_pin, gen_salt('bf', 10))
        END,
        "authPassword" = COALESCE(NULLIF("authPassword", ''),
          substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                   '[^a-zA-Z0-9]', '', 'g'), 1, 16)),
        "failedLoginAttempts" = 0,
        "lockedUntil" = NULL,
        "updatedAt" = now()
    WHERE id = v_wali_id;
  END IF;

  IF p_nis_santri IS NULL OR trim(p_nis_santri) = '' THEN
    RETURN QUERY SELECT TRUE,
      format('Wali siap login (Wali.id = %s). Nomor: %s. Tautkan santri '
             'dengan NIS agar dashboard berisi data.', v_wali_id, v_phone);
    RETURN;
  END IF;

  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = trim(p_nis_santri) AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Santri dengan NIS %s tidak ditemukan. Buat dulu (atau pakai '
             'create_wali_test_account() yang membuatnya otomatis).', p_nis_santri);
    RETURN;
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                            relationship, "isPrimary", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id, TRUE,
          p_relationship, TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Wali siap login. Nomor: %s, PIN: %s. Tertaut ke santri NIS %s.',
           v_phone, v_pin, trim(p_nis_santri));
END;
$$;

CREATE OR REPLACE FUNCTION public.create_wali_test_account(
  p_phone   TEXT DEFAULT '081234567890',
  p_pin     TEXT DEFAULT '123456',
  p_name    TEXT DEFAULT 'Bapak Wali Uji',
  p_email   TEXT DEFAULT NULL,
  p_nis     TEXT DEFAULT '2024001',
  p_santri  TEXT DEFAULT 'Santri Uji'
)
RETURNS TABLE(success BOOLEAN, message TEXT, phone TEXT, pin TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email     TEXT;
  v_phone     TEXT;
  v_user_id   TEXT;
  v_role_id   TEXT;
  v_wali_id   TEXT;
  v_santri_id TEXT;
  v_kelas_id  TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  v_phone := public.normalize_phone(p_phone);
  IF v_phone IS NULL OR length(v_phone) < 9 THEN
    RETURN QUERY SELECT FALSE, 'Nomor WhatsApp tidak valid.', p_phone, p_pin;
    RETURN;
  END IF;

  v_email := COALESCE(NULLIF(lower(trim(p_email)), ''),
                      'wali' || right(v_phone, 4) || '@madrasah.test');

  SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = 'WALI';
  IF v_role_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      'Role WALI tidak ada. Jalankan migration 03 lebih dulu.', v_phone, p_pin;
    RETURN;
  END IF;

  SELECT u.id INTO v_user_id FROM "User" u
  WHERE lower(u.email) = v_email OR u.phone = v_phone
  ORDER BY (lower(u.email) = v_email) DESC NULLS LAST LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, phone, "isActive",
                        "createdAt", "updatedAt")
    VALUES (v_user_id, v_email, split_part(v_email, '@', 1), p_name, v_phone,
            TRUE, now(), now());
  END IF;

  INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
  ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;

  SELECT w.id INTO v_wali_id FROM "Wali" w
  WHERE w."userId" = v_user_id AND w."deletedAt" IS NULL LIMIT 1;

  IF v_wali_id IS NULL THEN
    v_wali_id := gen_random_uuid()::TEXT;
    INSERT INTO "Wali" (id, "userId", name, phone, email, "activationStatus",
                        "pinHash", "authPassword", "createdAt", "updatedAt")
    VALUES (v_wali_id, v_user_id, p_name, v_phone, v_email, 'ACTIVE',
            crypt(p_pin, gen_salt('bf', 10)),
            substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                     '[^a-zA-Z0-9]', '', 'g'), 1, 16),
            now(), now());
  ELSE
    UPDATE "Wali"
    SET phone = v_phone, email = v_email, "activationStatus" = 'ACTIVE',
        "pinHash" = crypt(p_pin, gen_salt('bf', 10)),
        "authPassword" = COALESCE(NULLIF("authPassword", ''),
          substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                   '[^a-zA-Z0-9]', '', 'g'), 1, 16)),
        "failedLoginAttempts" = 0, "lockedUntil" = NULL, "updatedAt" = now()
    WHERE id = v_wali_id;
  END IF;

  SELECT s.id INTO v_santri_id FROM "Santri" s
  WHERE s.nis = p_nis AND s."deletedAt" IS NULL LIMIT 1;

  IF v_santri_id IS NULL THEN
    SELECT k.id INTO v_kelas_id FROM "Kelas" k
    WHERE k."deletedAt" IS NULL ORDER BY k."createdAt" LIMIT 1;

    v_santri_id := gen_random_uuid()::TEXT;
    INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                          "entryDate", "createdAt", "updatedAt")
    VALUES (v_santri_id, p_nis, p_santri, 'L', 'AKTIF', v_kelas_id,
            CURRENT_DATE, now(), now());
  END IF;

  INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                            relationship, "isPrimary", "createdAt")
  VALUES (gen_random_uuid()::TEXT, v_santri_id, v_wali_id, TRUE,
          'AYAH', TRUE, now())
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT TRUE,
    format('Akun wali uji siap. Nomor %s / PIN %s. Santri NIS %s (%s anak).',
           v_phone, p_pin, p_nis,
           (SELECT count(*) FROM "SantriWali" sw WHERE sw."waliId" = v_wali_id)),
    v_phone, p_pin;
END;
$$;

REVOKE ALL ON FUNCTION public.provision_wali_profile(TEXT, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.create_wali_test_account(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000028_seed_demo_data.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.seed_demo_data()
RETURNS TABLE(step TEXT, ok BOOLEAN, detail TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_ta_id      TEXT;
  v_sem_ganjil TEXT;
  v_sem_genap  TEXT;

  v_kls        RECORD;
  v_kelas_ids  TEXT[];
  v_kelas_1a   TEXT;

  v_mapel_ids  TEXT[];
  v_mp         RECORD;

  v_guru       RECORD;
  v_guru_ids   TEXT[] := ARRAY[]::TEXT[];

  v_santri     RECORD;
  v_santri_ids TEXT[];
  v_santri_a   TEXT;
  v_santri_b   TEXT;

  v_kas_id     TEXT;
  v_jt_id      TEXT;
  v_tagihan_id TEXT;

  v_abs_count  INT;
  v_nilai_count INT;
  v_total      DOUBLE PRECISION;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;

  SELECT id INTO v_ta_id FROM "TahunAjaran" WHERE code = '2025/2026' LIMIT 1;
  IF v_ta_id IS NULL THEN
    v_ta_id := gen_random_uuid()::TEXT;
    INSERT INTO "TahunAjaran" (id, code, name, "startDate", "endDate", "isActive",
                               "createdAt", "updatedAt")
    VALUES (v_ta_id, '2025/2026', 'Tahun Ajaran 2025/2026',
            '2025-07-01', '2026-06-30', TRUE, now(), now());
  END IF;

  SELECT id INTO v_sem_ganjil FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND code = 'GANJIL' LIMIT 1;
  IF v_sem_ganjil IS NULL THEN
    v_sem_ganjil := gen_random_uuid()::TEXT;
    INSERT INTO "Semester" (id, "tahunAjaranId", code, name, type,
                            "startDate", "endDate", "isActive",
                            "createdAt", "updatedAt")
    VALUES (v_sem_ganjil, v_ta_id, 'GANJIL', 'Semester Ganjil', 'GANJIL',
            '2025-07-01', '2025-12-31', TRUE, now(), now());
  END IF;

  SELECT id INTO v_sem_genap FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND code = 'GENAP' LIMIT 1;
  IF v_sem_genap IS NULL THEN
    v_sem_genap := gen_random_uuid()::TEXT;
    INSERT INTO "Semester" (id, "tahunAjaranId", code, name, type,
                            "startDate", "endDate", "isActive",
                            "createdAt", "updatedAt")
    VALUES (v_sem_genap, v_ta_id, 'GENAP', 'Semester Genap', 'GENAP',
            '2026-01-01', '2026-06-30', FALSE, now(), now());
  END IF;

  step := 'tahun_ajaran_semester';
  ok := TRUE;
  detail := 'Tahun ajaran 2025/2026 + semester Ganjil & Genap siap';
  RETURN NEXT;

  FOR v_kls IN
    SELECT * FROM (VALUES
      ('KLS-1A', 'Kelas 1A', '1'::TEXT, 1),
      ('KLS-1B', 'Kelas 1B', '1', 2),
      ('KLS-2A', 'Kelas 2A', '2', 3),
      ('KLS-2B', 'Kelas 2B', '2', 4),
      ('KLS-3A', 'Kelas 3A', '3', 5),
      ('KLS-4A', 'Kelas 4A', '4', 6)
    ) AS t(code, name, level, sort_order)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM "Kelas" WHERE code = v_kls.code) THEN
      INSERT INTO "Kelas" (id, code, name, level, capacity, "sortOrder",
                           "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_kls.code, v_kls.name, v_kls.level,
              30, v_kls.sort_order, TRUE, now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY "sortOrder") INTO v_kelas_ids
  FROM "Kelas" WHERE "deletedAt" IS NULL;

  SELECT id INTO v_kelas_1a FROM "Kelas" WHERE code = 'KLS-1A' LIMIT 1;

  step := 'kelas';
  ok := TRUE;
  detail := COALESCE(array_length(v_kelas_ids, 1), 0) || ' kelas tersedia';
  RETURN NEXT;

  FOR v_mp IN
    SELECT * FROM (VALUES
      ('MP-QURAN',   'Al-Qur''an',        'QURAN'::TEXT,   75.0, 1),
      ('MP-FIQIH',   'Fiqih',             'DINIYAH',       70.0, 2),
      ('MP-AKHLAK',  'Akhlak',            'DINIYAH',       70.0, 3),
      ('MP-BACA',    'Baca Tulis',        'UMUM',          65.0, 4),
      ('MP-HAFALAN', 'Hafalan Kitab',     'DINIYAH',       75.0, 5),
      ('MP-BAHASA',  'Bahasa Arab',       'UMUM',          70.0, 6)
    ) AS t(code, name, category, kkm, sort_order)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM "MataPelajaran" WHERE code = v_mp.code) THEN
      INSERT INTO "MataPelajaran" (id, code, name, category, kkm, "durationMnt",
                                   "sortOrder", "isActive", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_mp.code, v_mp.name, v_mp.category,
              v_mp.kkm, 90, v_mp.sort_order, TRUE, now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY "sortOrder") INTO v_mapel_ids
  FROM "MataPelajaran" WHERE "deletedAt" IS NULL;

  step := 'mata_pelajaran';
  ok := TRUE;
  detail := COALESCE(array_length(v_mapel_ids, 1), 0) || ' mapel tersedia';
  RETURN NEXT;

  FOR v_guru IN
    SELECT g.id, g.name,
           row_number() OVER (ORDER BY g.name) AS rn
    FROM "Guru" g WHERE g."deletedAt" IS NULL
  LOOP
    v_guru_ids := v_guru_ids || v_guru.id;

    DECLARE
      i INT := 0;
    BEGIN
      WHILE i < 2 LOOP
        IF NOT EXISTS (
          SELECT 1 FROM "Jadwal"
          WHERE "guruId" = v_guru.id
            AND "kelasId" = v_kelas_ids[((v_guru.rn::INT + i - 1) %
                          COALESCE(array_length(v_kelas_ids, 1), 1)) + 1]
            AND "dayOfWeek" = (1 + i)
        ) THEN
          INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                                "mapelId", "guruId", "dayOfWeek", "startTime",
                                "endTime", "createdAt", "updatedAt")
          VALUES (
            gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil,
            v_kelas_ids[((v_guru.rn::INT + i - 1) %
              COALESCE(array_length(v_kelas_ids, 1), 1)) + 1],
            v_mapel_ids[((v_guru.rn::INT + i - 1) %
              COALESCE(array_length(v_mapel_ids, 1), 1)) + 1],
            v_guru.id, 1 + i, '07:00', '08:30', now(), now()
          );
        END IF;
        i := i + 1;
      END LOOP;
    END;
  END LOOP;

  step := 'jadwal';
  ok := EXISTS (SELECT 1 FROM "Jadwal");
  detail := (SELECT count(*) FROM "Jadwal") || ' baris jadwal';
  RETURN NEXT;

  FOR v_santri IN
    SELECT * FROM (VALUES
      ('2025001', 'Muhammad Fauzan',   'L'::TEXT, 'KLS-1A'),
      ('2025002', 'Aisyah Nur Fadhilah', 'P',    'KLS-1A')
    ) AS t(nis, name, gender, kelas_code)
  LOOP
    SELECT s.id INTO v_santri_a FROM "Santri" s
    WHERE s.nis = v_santri.nis AND s."deletedAt" IS NULL LIMIT 1;

    IF v_santri_a IS NULL THEN
      SELECT k.id INTO v_santri_b FROM "Kelas" k
      WHERE k.code = v_santri.kelas_code LIMIT 1;

      v_santri_a := gen_random_uuid()::TEXT;
      INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                            "tahunAjaranId", "entryDate", "birthPlace",
                            "createdAt", "updatedAt")
      VALUES (v_santri_a, v_santri.nis, v_santri.name, v_santri.gender,
              'AKTIF', COALESCE(v_santri_b, v_kelas_1a), v_ta_id,
              CURRENT_DATE, 'Malang', now(), now());
    END IF;
  END LOOP;

  SELECT array_agg(id ORDER BY nis) INTO v_santri_ids
  FROM "Santri" WHERE "deletedAt" IS NULL;
  SELECT id INTO v_santri_a FROM "Santri" WHERE nis = '2025001';
  SELECT id INTO v_santri_b FROM "Santri" WHERE nis = '2025002';

  DECLARE
    w RECORD;
    idx INT := 0;
  BEGIN
    FOR w IN SELECT id FROM "Wali" WHERE "deletedAt" IS NULL ORDER BY "createdAt"
    LOOP
      EXIT WHEN idx >= 2;
      IF NOT EXISTS (SELECT 1 FROM "SantriWali"
                     WHERE "waliId" = w.id AND "santriId" = v_santri_ids[idx + 1]) THEN
        INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                                  relationship, "isPrimary", "createdAt")
        VALUES (gen_random_uuid()::TEXT, v_santri_ids[idx + 1], w.id, TRUE,
                'AYAH', TRUE, now());
      END IF;
      UPDATE "Santri" SET "waliId" = w.id
      WHERE id = v_santri_ids[idx + 1] AND "waliId" IS DISTINCT FROM w.id;
      idx := idx + 1;
    END LOOP;
  END;

  step := 'santri_dan_wali';
  ok := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL) >= 2;
  detail := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL)
            || ' santri, '
            || (SELECT count(*) FROM "SantriWali") || ' tautan wali';
  RETURN NEXT;

  DECLARE
    d INT;
    s TEXT;
    v_status TEXT;
  BEGIN
    FOR d IN 0..13 LOOP
      FOREACH s IN ARRAY v_santri_ids LOOP
        IF EXTRACT(DOW FROM (CURRENT_DATE - d))::INT = 5 THEN
          CONTINUE;
        END IF;

        v_status := CASE WHEN (d % 7) = 3 THEN 'SAKIT'
                         WHEN (d % 11) = 5 THEN 'IZIN'
                         WHEN (d % 13) = 6 THEN 'ALPA'
                         ELSE 'HADIR' END;

        IF NOT EXISTS (
          SELECT 1 FROM "Absensi"
          WHERE "santriId" = s AND date::date = (CURRENT_DATE - d)::date
        ) THEN
          INSERT INTO "Absensi" (id, "tahunAjaranId", "santriId", "kelasId",
                                 date, status, "recordedByGuruId",
                                 "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, s, st."kelasId",
                 (CURRENT_DATE - d), v_status,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" LIMIT 1),
                 now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;
      END LOOP;
    END LOOP;
  END;

  SELECT count(*) INTO v_abs_count FROM "Absensi";
  step := 'absensi';
  ok := v_abs_count > 0;
  detail := v_abs_count || ' catatan absensi (14 hari terakhir)';
  RETURN NEXT;

  DECLARE
    s TEXT;
    m TEXT;
    base DOUBLE PRECISION;
    n INT := 0;
  BEGIN
    FOREACH s IN ARRAY v_santri_ids LOOP
      n := n + 1;
      FOREACH m IN ARRAY v_mapel_ids LOOP
        base := 78 + (n * 3) + (length(m) % 5);

        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = s AND "mapelId" = m
                         AND "tahunAjaranId" = v_ta_id) THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, s,
                 st."kelasId", m,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" AND j."mapelId" = m LIMIT 1),
                 'UH', LEAST(100, base), CURRENT_DATE - 7, now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = s AND "mapelId" = m
                         AND "tahunAjaranId" = v_ta_id AND type = 'UTS') THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          SELECT gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, s,
                 st."kelasId", m,
                 (SELECT "guruId" FROM "Jadwal" j
                  WHERE j."kelasId" = st."kelasId" AND j."mapelId" = m LIMIT 1),
                 'UTS', LEAST(100, base + 2), CURRENT_DATE - 3, now(), now()
          FROM "Santri" st WHERE st.id = s;
        END IF;
      END LOOP;
    END LOOP;
  END;

  SELECT count(*) INTO v_nilai_count FROM "Nilai";
  step := 'nilai';
  ok := v_nilai_count > 0;
  detail := v_nilai_count || ' nilai (UH + UTS)';
  RETURN NEXT;

  DECLARE
    g RECORD;
    m_id TEXT;
  BEGIN
    FOR g IN
      SELECT DISTINCT j."guruId", j."kelasId", j."mapelId"
      FROM "Jadwal" j
    LOOP
      IF NOT EXISTS (SELECT 1 FROM "Materi"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        m_id := gen_random_uuid()::TEXT;
        INSERT INTO "Materi" (id, "tahunAjaranId", "semesterId", "mapelId",
                              "kelasId", "guruId", title, description, type,
                              pertemuan, "sortOrder", "isPublished",
                              "publishedAt", "createdAt", "updatedAt")
        VALUES (m_id, v_ta_id, v_sem_ganjil, g."mapelId", g."kelasId",
                g."guruId", 'Materi Pengantar', 'Ringkasan materi pertemuan 1',
                'TEKS', 1, 1, TRUE, now(), now(), now());
      END IF;

      IF NOT EXISTS (SELECT 1 FROM "Tugas"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        INSERT INTO "Tugas" (id, "tahunAjaranId", "semesterId", "mapelId",
                             "kelasId", "guruId", title, description, type,
                             "maxScore", "dueDate", "isPublished",
                             "publishedAt", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g."mapelId",
                g."kelasId", g."guruId", 'Latihan Pertemuan 1',
                'Kerjakan latihan pada buku halaman 10', 'TUGAS',
                100, CURRENT_DATE + 7, TRUE, now(), now(), now());
      END IF;

      IF NOT EXISTS (SELECT 1 FROM "Pertemuan"
                     WHERE "guruId" = g."guruId" AND "kelasId" = g."kelasId"
                       AND "mapelId" = g."mapelId") THEN
        INSERT INTO "Pertemuan" (id, "tahunAjaranId", "semesterId", "kelasId",
                                 "mapelId", "guruId", "pertemuanKe", date,
                                 topic, description, "isCompleted",
                                 "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g."kelasId",
                g."mapelId", g."guruId", 1, CURRENT_DATE, 'Pengenalan materi',
                'Pertemuan perdana', TRUE, now(), now());
      END IF;
    END LOOP;
  END;

  step := 'materi_tugas_pertemuan';
  ok := (SELECT count(*) FROM "Materi") > 0;
  detail := (SELECT count(*) FROM "Materi") || ' materi, '
            || (SELECT count(*) FROM "Tugas") || ' tugas, '
            || (SELECT count(*) FROM "Pertemuan") || ' pertemuan';
  RETURN NEXT;

  SELECT id INTO v_jt_id FROM "JenisTagihan" WHERE code = 'SPP' LIMIT 1;
  IF v_jt_id IS NULL THEN
    v_jt_id := gen_random_uuid()::TEXT;
    INSERT INTO "JenisTagihan" (id, code, name, description, "defaultAmount",
                                category, "isActive", "createdAt", "updatedAt")
    VALUES (v_jt_id, 'SPP', 'SPP Bulanan', 'Syahriah bulanan santri',
            150000, 'BULANAN', TRUE, now(), now());

    INSERT INTO "JenisTagihan" (id, code, name, description, "defaultAmount",
                                category, "isActive", "createdAt", "updatedAt")
    VALUES (gen_random_uuid()::TEXT, 'UANG-PANGKAL', 'Uang Pangkal',
            'Biaya masuk awal tahun', 500000, 'SEKALI', TRUE, now(), now());
  END IF;

  DECLARE
    s TEXT;
    sisa DOUBLE PRECISION;
  BEGIN
    FOREACH s IN ARRAY v_santri_ids LOOP
      IF NOT EXISTS (SELECT 1 FROM "Tagihan"
                     WHERE "santriId" = s AND "jenisTagihanId" = v_jt_id
                       AND "tahunAjaranId" = v_ta_id) THEN
        v_tagihan_id := gen_random_uuid()::TEXT;
        INSERT INTO "Tagihan" (id, "tahunAjaranId", "santriId", "kelasId",
                               "jenisTagihanId", amount, "paidAmount",
                               description, "dueDate", status,
                               "createdAt", "updatedAt")
        SELECT v_tagihan_id, v_ta_id, s, st."kelasId", v_jt_id, 150000, 0,
               'SPP bulan ini', CURRENT_DATE + 10, 'BELUM_BAYAR', now(), now()
        FROM "Santri" st WHERE st.id = s;

        IF s = v_santri_a THEN
          sisa := 150000;
          UPDATE "Tagihan" SET "paidAmount" = 150000, status = 'LUNAS',
                 "updatedAt" = now() WHERE id = v_tagihan_id;

          INSERT INTO "Payment" (id, "invoiceNo", "tahunAjaranId", "tagihanId",
                                 "santriId", amount, "paymentMethod",
                                 "paymentDate", status, note, "createdAt",
                                 "updatedAt")
          VALUES (gen_random_uuid()::TEXT, 'INV-DEMO-001', v_ta_id,
                  v_tagihan_id, s, 150000, 'TUNAI', now() - INTERVAL '2 days',
                  'VERIFIED', 'Pembayaran lunas (demo)', now(), now());
        ELSE
          sisa := 100000;
          UPDATE "Tagihan" SET "paidAmount" = 50000, status = 'SEBAGIAN',
                 "updatedAt" = now() WHERE id = v_tagihan_id;

          INSERT INTO "Payment" (id, "invoiceNo", "tahunAjaranId", "tagihanId",
                                 "santriId", amount, "paymentMethod",
                                 "paymentDate", status, note, "createdAt",
                                 "updatedAt")
          VALUES (gen_random_uuid()::TEXT, 'INV-DEMO-002', v_ta_id,
                  v_tagihan_id, s, 50000, 'TRANSFER', now() - INTERVAL '1 day',
                  'VERIFIED', 'Cicilan pertama (demo)', now(), now());
        END IF;
      END IF;
    END LOOP;
  END;

  step := 'tagihan_dan_pembayaran';
  ok := (SELECT count(*) FROM "Tagihan") > 0;
  detail := (SELECT count(*) FROM "Tagihan") || ' tagihan, '
            || (SELECT count(*) FROM "Payment") || ' pembayaran';
  RETURN NEXT;

  SELECT id INTO v_kas_id FROM "Kas" WHERE code = 'KAS-UTAMA' LIMIT 1;
  IF v_kas_id IS NULL THEN
    v_kas_id := gen_random_uuid()::TEXT;
    INSERT INTO "Kas" (id, code, name, "accountNumber", "bankName", type,
                       balance, "isActive", "createdAt", "updatedAt")
    VALUES (v_kas_id, 'KAS-UTAMA', 'Kas Utama Madrasah', '1234567890',
            'BSI', 'TUNAI', 0, TRUE, now(), now());
  END IF;

  SELECT COALESCE(sum(amount), 0) INTO v_total
  FROM "Payment" WHERE status = 'VERIFIED';

  UPDATE "Kas" SET balance = v_total, "updatedAt" = now() WHERE id = v_kas_id;

  IF NOT EXISTS (SELECT 1 FROM "TransaksiKas" WHERE "kasId" = v_kas_id) THEN
    INSERT INTO "TransaksiKas" (id, "kasId", "tahunAjaranId", type, category,
                                amount, description, "transaksiDate",
                                "createdAt", "updatedAt")
    VALUES (gen_random_uuid()::TEXT, v_kas_id, v_ta_id, 'MASUK', 'SPP',
            v_total, 'Penerimaan SPP (demo)', CURRENT_DATE, now(), now());
  END IF;

  DECLARE
    g2 RECORD;
  BEGIN
    FOR g2 IN SELECT id, name FROM "Guru" WHERE "deletedAt" IS NULL LOOP
      IF NOT EXISTS (SELECT 1 FROM "HonorGuru"
                     WHERE "guruId" = g2.id AND periode = to_char(CURRENT_DATE, 'YYYY-MM')) THEN
        INSERT INTO "HonorGuru" (id, "tahunAjaranId", "semesterId", "guruId",
                                 periode, "periodeLabel", "honorMengajar",
                                 insentif, tunjangan, potongan, "totalHonor",
                                 status, "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_ganjil, g2.id,
                to_char(CURRENT_DATE, 'YYYY-MM'),
                'Bulan ' || to_char(CURRENT_DATE, 'MM/YYYY'),
                750000, 100000, 50000, 0, 900000, 'BELUM_DIBAYAR', now(), now());
      END IF;
    END LOOP;
  END;

  step := 'kas_dan_honor';
  ok := (SELECT count(*) FROM "Kas") > 0;
  detail := (SELECT count(*) FROM "TransaksiKas") || ' transaksi kas, '
            || (SELECT count(*) FROM "HonorGuru") || ' honor guru, saldo '
            || to_char(v_total, 'FM999G999G999');
  RETURN NEXT;

  IF NOT EXISTS (SELECT 1 FROM "Announcement" WHERE title = 'Selamat Datang di SIM MADIN') THEN
    INSERT INTO "Announcement" (id, title, content, audience, priority,
                                "isPublished", "publishedAt", "createdAt",
                                "updatedAt")
    VALUES (gen_random_uuid()::TEXT, 'Selamat Datang di SIM MADIN',
            'Aplikasi SIM Madrasah Diniyah Miftahul Ulum kini aktif. '
            'Silakan gunakan untuk memantau absensi, nilai, dan tagihan putra-putri Anda.',
            'ALL', 'NORMAL', TRUE, now(), now(), now());
  END IF;

  DECLARE
    w RECORD;
  BEGIN
    FOR w IN SELECT id FROM "Wali" WHERE "deletedAt" IS NULL LOOP
      IF NOT EXISTS (SELECT 1 FROM "Notifikasi" WHERE "waliId" = w.id) THEN
        INSERT INTO "Notifikasi" (id, "waliId", type, title, message, priority,
                                  "isRead", "isEmailSent", "isPushSent", "createdAt")
        VALUES (gen_random_uuid()::TEXT, w.id, 'ANNOUNCEMENT',
                'Selamat Datang di SIM MADIN',
                'Anda dapat memantau absensi, nilai, dan tagihan ananda di aplikasi ini.',
                'NORMAL', FALSE, FALSE, FALSE, now());
      END IF;
    END LOOP;
  END;

  step := 'pengumuman_dan_notifikasi';
  ok := TRUE;
  detail := (SELECT count(*) FROM "Announcement") || ' pengumuman, '
            || (SELECT count(*) FROM "Notifikasi") || ' notifikasi';
  RETURN NEXT;

  RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.seed_demo_data() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000029_account_management.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_create_staff_account(
  p_email       TEXT,
  p_password    TEXT,
  p_name        TEXT,
  p_roles       TEXT[],
  p_phone       TEXT DEFAULT NULL,
  p_username    TEXT DEFAULT NULL,
  p_guru_nip    TEXT DEFAULT NULL,
  p_specialization TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, user_id TEXT, auth_uid UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email    TEXT := lower(trim(p_email));
  v_username TEXT;
  v_uid      UUID;
  v_user_id  TEXT;
  v_role     TEXT;
  v_role_id  TEXT;
  v_guru_id  TEXT;
BEGIN
  IF v_email IS NULL OR v_email = '' OR position('@' IN v_email) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Email tidak valid.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN QUERY SELECT FALSE, 'Password minimal 6 karakter.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  v_username := COALESCE(NULLIF(trim(p_username), ''), split_part(v_email, '@', 1));

  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;

  IF v_uid IS NULL THEN
    v_uid := gen_random_uuid();

    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      v_email, crypt(p_password, gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('name', p_name, 'role', COALESCE(p_roles[1], 'WALI')),
      '', '', '', ''
    );

    INSERT INTO auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
      jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                         'email_verified', TRUE, 'phone_verified', FALSE),
      now(), now(), now()
    )
    ON CONFLICT DO NOTHING;
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt(p_password, gen_salt('bf', 10)),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now(),
        banned_until = NULL
    WHERE id = v_uid;
  END IF;

  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST
  LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, phone, "firebaseUid",
                        "isActive", "createdAt", "updatedAt")
    VALUES (v_user_id, v_email, v_username, p_name, p_phone, v_uid::TEXT,
            TRUE, now(), now());
  ELSE
    UPDATE "User"
    SET email = v_email,
        username = COALESCE(NULLIF(username, ''), v_username),
        name = p_name,
        phone = COALESCE(p_phone, phone),
        "firebaseUid" = v_uid::TEXT,
        "isActive" = TRUE,
        "deletedAt" = NULL,
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  FOREACH v_role IN ARRAY COALESCE(p_roles, ARRAY[]::TEXT[]) LOOP
    SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = v_role;
    IF v_role_id IS NULL THEN
      RETURN QUERY SELECT FALSE,
        format('Peran "%s" tidak dikenal.', v_role), v_user_id, v_uid;
      RETURN;
    END IF;

    INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
    VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
    ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;
  END LOOP;

  IF 'GURU' = ANY (p_roles) THEN
    SELECT g.id INTO v_guru_id FROM "Guru" g
    WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

    IF v_guru_id IS NULL THEN
      INSERT INTO "Guru" (id, "userId", name, nip, specialization, status,
                          "joinDate", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_user_id, p_name, p_guru_nip,
              p_specialization, 'AKTIF', CURRENT_DATE, now(), now());
    ELSE
      UPDATE "Guru" SET name = p_name,
             nip = COALESCE(p_guru_nip, nip),
             specialization = COALESCE(p_specialization, specialization),
             "updatedAt" = now()
      WHERE id = v_guru_id;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun %s siap. Peran: %s.', v_email,
           COALESCE(array_to_string(p_roles, ', '), '-')),
    v_user_id, v_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_account(
  p_email       TEXT,
  p_hard_delete BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(success BOOLEAN, message TEXT, auth_deleted BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email     TEXT := lower(trim(p_email));
  v_uid       UUID;
  v_user_id   TEXT;
  v_historis  INT := 0;
BEGIN
  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;
  SELECT u.id INTO v_user_id FROM "User" u
  WHERE lower(u.email) = v_email OR (v_uid IS NOT NULL AND u."firebaseUid" = v_uid::TEXT)
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

  IF v_uid IS NULL AND v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Akun %s tidak ditemukan.', p_email), FALSE;
    RETURN;
  END IF;

  IF v_user_id IS NOT NULL THEN
    SELECT (
      (SELECT count(*) FROM "Guru"   WHERE "userId" = v_user_id)
    + (SELECT count(*) FROM "Wali"   WHERE "userId" = v_user_id)
    + (SELECT count(*) FROM "Santri" WHERE "userId" = v_user_id)
    ) INTO v_historis;
  END IF;

  IF v_user_id IS NOT NULL THEN
    UPDATE "UserRole" SET "isActive" = FALSE WHERE "userId" = v_user_id;

    UPDATE "User"
    SET "isActive" = FALSE, "deletedAt" = now(), "updatedAt" = now(),
        "firebaseUid" = NULL, "fcmToken" = NULL
    WHERE id = v_user_id;

    UPDATE "Wali"
    SET "activationStatus" = 'SUSPENDED', "pinHash" = NULL,
        "authPassword" = NULL, "userId" = NULL, "updatedAt" = now()
    WHERE "userId" = v_user_id;

    UPDATE "Guru"
    SET status = 'NONAKTIF', "userId" = NULL, "updatedAt" = now()
    WHERE "userId" = v_user_id;
  END IF;

  IF v_uid IS NOT NULL THEN
    DELETE FROM auth.identities WHERE user_id = v_uid;
    DELETE FROM auth.sessions   WHERE user_id = v_uid;
    DELETE FROM auth.refresh_tokens WHERE user_id = v_uid::TEXT;
    DELETE FROM auth.users      WHERE id = v_uid;
  END IF;

  IF p_hard_delete THEN
    IF v_historis > 0 THEN
      RETURN QUERY SELECT TRUE,
        format('Akun %s dinonaktifkan & login dihapus. Baris "User" '
               'dipertahankan karena punya %s data historis (guru/wali/santri).',
               p_email, v_historis),
        v_uid IS NOT NULL;
      RETURN;
    END IF;
    IF v_user_id IS NOT NULL THEN
      DELETE FROM "UserRole" WHERE "userId" = v_user_id;
      DELETE FROM "User" WHERE id = v_user_id;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun %s dihapus. Login ke aplikasi mobile sudah tidak bisa.', p_email),
    v_uid IS NOT NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_restore_account(p_email TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email   TEXT := lower(trim(p_email));
  v_user_id TEXT;
BEGIN
  SELECT u.id INTO v_user_id FROM "User" u WHERE lower(u.email) = v_email LIMIT 1;
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Akun %s tidak ada. Buat ulang lewat admin_create_staff_account().', p_email);
    RETURN;
  END IF;

  UPDATE "User" SET "isActive" = TRUE, "deletedAt" = NULL, "updatedAt" = now()
  WHERE id = v_user_id;

  UPDATE "Wali" SET "activationStatus" = 'ACTIVE', "userId" = v_user_id,
         "updatedAt" = now()
  WHERE lower(email) = v_email AND "activationStatus" = 'SUSPENDED';

  RETURN QUERY SELECT TRUE, format('Akun %s diaktifkan kembali.', p_email);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_staff_account(TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_delete_account(TEXT, BOOLEAN)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_restore_account(TEXT)
  FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000030_seed_all_demo.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.seed_all_demo()
RETURNS TABLE(step TEXT, ok BOOLEAN, detail TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_negara RECORD;
  v_ta_id   TEXT;
  v_sem_id  TEXT;
  v_kelas_a TEXT;
  v_kelas_b TEXT;
  v_mapel   TEXT;
  v_guru_id TEXT;
  v_santri  TEXT;
  v_wali_id TEXT;
BEGIN
  FOR v_negara IN
    SELECT * FROM (VALUES
      ('mdta@madrasah.com',      'admin@mdta01', 'Administrator Madrasah',
       ARRAY['SUPER_ADMIN','ADMIN']::TEXT[], '081200000000'::TEXT, NULL::TEXT),
      ('kepala@madrasah.com',    'kepala123',    'H. Abdul Ghofur',
       ARRAY['KEPALA']::TEXT[],    '081200000001', NULL),
      ('bendahara@madrasah.com', 'bendahara123', 'Hj. Sri Wahyuni',
       ARRAY['BENDAHARA']::TEXT[], '081200000002', NULL),
      ('guru@madrasah.com',      'guru123',      'Ustadz Ahmad Fauzi',
       ARRAY['GURU']::TEXT[],      '081200000003', 'Al-Qur''an'),
      ('guru2@madrasah.com',     'guru123',      'Ustadzah Siti Aminah',
       ARRAY['GURU']::TEXT[],      '081200000004', 'Fiqih')
    ) AS t(email, pass, nama, roles, phone, spesialisasi)
  LOOP
    PERFORM public.admin_create_staff_account(
      v_negara.email, v_negara.pass, v_negara.nama, v_negara.roles,
      v_negara.phone, NULL, NULL, v_negara.spesialisasi);
  END LOOP;

  step := 'akun_staf';
  ok := (SELECT count(*) FROM "UserRole" ur
         JOIN "Role" r ON r.id = ur."roleId"
         WHERE r.code IN ('SUPER_ADMIN','KEPALA','BENDAHARA','GURU')
           AND ur."isActive") >= 5;
  detail := 'Admin, kepala, bendahara, 2 guru';
  RETURN NEXT;

  PERFORM public.seed_demo_data();

  SELECT id INTO v_ta_id FROM "TahunAjaran" WHERE "isActive" LIMIT 1;
  SELECT id INTO v_sem_id FROM "Semester"
  WHERE "tahunAjaranId" = v_ta_id AND "isActive" LIMIT 1;
  SELECT id INTO v_kelas_a FROM "Kelas" WHERE code = 'KLS-1A';
  SELECT id INTO v_kelas_b FROM "Kelas" WHERE code = 'KLS-1B';
  SELECT id INTO v_mapel FROM "MataPelajaran" WHERE code = 'MP-QURAN';

  step := 'data_akademik';
  ok := v_ta_id IS NOT NULL AND v_kelas_a IS NOT NULL AND v_mapel IS NOT NULL;
  detail := 'Tahun ajaran, 6 kelas, 6 mapel';
  RETURN NEXT;

  FOR v_negara IN
    SELECT g.id, g.name, u.email
    FROM "Guru" g JOIN "User" u ON u.id = g."userId"
    WHERE g."deletedAt" IS NULL AND u."deletedAt" IS NULL
  LOOP
    v_guru_id := v_negara.id;

    IF v_kelas_a IS NOT NULL AND v_mapel IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM "Jadwal"
                     WHERE "guruId" = v_guru_id AND "kelasId" = v_kelas_a
                       AND "dayOfWeek" = 1) THEN
        INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                              "mapelId", "guruId", "dayOfWeek", "startTime",
                              "endTime", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_kelas_a,
                v_mapel, v_guru_id, 1, '07:00', '08:30', now(), now());
      END IF;
    END IF;

    IF v_kelas_b IS NOT NULL THEN
      IF NOT EXISTS (SELECT 1 FROM "Jadwal"
                     WHERE "guruId" = v_guru_id AND "kelasId" = v_kelas_b
                       AND "dayOfWeek" = 2) THEN
        INSERT INTO "Jadwal" (id, "tahunAjaranId", "semesterId", "kelasId",
                              "mapelId", "guruId", "dayOfWeek", "startTime",
                              "endTime", "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_kelas_b,
                (SELECT id FROM "MataPelajaran" WHERE code = 'MP-FIQIH'),
                v_guru_id, 2, '08:30', '10:00', now(), now());
      END IF;
    END IF;
  END LOOP;

  step := 'jadwal_guru';
  ok := (SELECT count(*) FROM "Jadwal") > 0;
  detail := (SELECT count(*) FROM "Jadwal") || ' jadwal';
  RETURN NEXT;

  FOR v_negara IN
    SELECT * FROM (VALUES
      ('Bapak Abdullah', '081234567801', '2025001', 'Muhammad Fauzan',      'L'::TEXT, 'KLS-1A'),
      ('Bapak Hasan',    '081234567802', '2025002', 'Aisyah Nur Fadhilah',  'P',       'KLS-1A')
    ) AS t(nama_wali, phone, nis, nama_santri, gender, kelas)
  LOOP
    DECLARE
      v_email TEXT := 'wali' || right(v_negara.phone, 3) || '@madrasah.com';
      v_uid   UUID;
      v_user  TEXT;
      v_role  TEXT;
    BEGIN
      SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;
      IF v_uid IS NULL THEN
        v_uid := gen_random_uuid();
        INSERT INTO auth.users (
          id, instance_id, aud, role, email, encrypted_password,
          email_confirmed_at, created_at, updated_at,
          raw_app_meta_data, raw_user_meta_data,
          confirmation_token, recovery_token, email_change_token_new, email_change
        ) VALUES (
          v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          v_email, crypt(encode(gen_random_bytes(12), 'hex'), gen_salt('bf', 10)),
          now(), now(), now(),
          jsonb_build_object('provider','email','providers',jsonb_build_array('email')),
          jsonb_build_object('name', v_negara.nama_wali, 'role','WALI'),
          '', '', '', ''
        );
        INSERT INTO auth.identities (
          id, user_id, provider_id, provider, identity_data,
          last_sign_in_at, created_at, updated_at
        ) VALUES (
          gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
          jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                             'email_verified', TRUE, 'phone_verified', FALSE),
          now(), now(), now()
        ) ON CONFLICT DO NOTHING;
      END IF;

      SELECT u.id INTO v_user FROM "User" u
      WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email LIMIT 1;

      IF v_user IS NULL THEN
        v_user := gen_random_uuid()::TEXT;
        INSERT INTO "User" (id, email, username, name, phone, "firebaseUid",
                            "isActive", "createdAt", "updatedAt")
        VALUES (v_user, v_email, 'wali' || right(v_negara.phone, 3),
                v_negara.nama_wali, v_negara.phone, v_uid::TEXT, TRUE, now(), now());
      END IF;

      SELECT r.id INTO v_role FROM "Role" r WHERE r.code = 'WALI';
      INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
      VALUES (gen_random_uuid()::TEXT, v_user, v_role, TRUE, now())
      ON CONFLICT ("userId","roleId") DO UPDATE SET "isActive" = TRUE;

      SELECT w.id INTO v_wali_id FROM "Wali" w
      WHERE w."userId" = v_user AND w."deletedAt" IS NULL LIMIT 1;

      IF v_wali_id IS NULL THEN
        v_wali_id := gen_random_uuid()::TEXT;
        INSERT INTO "Wali" (id, "userId", name, phone, email, "activationStatus",
                            "pinHash", "authPassword", "createdAt", "updatedAt")
        VALUES (v_wali_id, v_user, v_negara.nama_wali, v_negara.phone, v_email,
                'ACTIVE', crypt('123456', gen_salt('bf', 10)),
                substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                                         '[^a-zA-Z0-9]', '', 'g'), 1, 16),
                now(), now());
      ELSE
        UPDATE "Wali"
        SET phone = v_negara.phone, "activationStatus" = 'ACTIVE',
            "pinHash" = crypt('123456', gen_salt('bf', 10)),
            "failedLoginAttempts" = 0, "lockedUntil" = NULL, "updatedAt" = now()
        WHERE id = v_wali_id;
      END IF;

      SELECT s.id INTO v_santri FROM "Santri" s
      WHERE s.nis = v_negara.nis AND s."deletedAt" IS NULL LIMIT 1;

      IF v_santri IS NULL THEN
        v_santri := gen_random_uuid()::TEXT;
        INSERT INTO "Santri" (id, nis, name, gender, status, "kelasId",
                              "tahunAjaranId", "waliId", "entryDate",
                              "birthPlace", "createdAt", "updatedAt")
        VALUES (v_santri, v_negara.nis, v_negara.nama_santri, v_negara.gender,
                'AKTIF', (SELECT id FROM "Kelas" WHERE code = v_negara.kelas),
                v_ta_id, v_wali_id, CURRENT_DATE, 'Malang', now(), now());
      ELSE
        UPDATE "Santri" SET "waliId" = v_wali_id,
               "kelasId" = COALESCE("kelasId", (SELECT id FROM "Kelas" WHERE code = v_negara.kelas)),
               "updatedAt" = now()
        WHERE id = v_santri;
      END IF;

      INSERT INTO "SantriWali" (id, "santriId", "waliId", "canAccess",
                                relationship, "isPrimary", "createdAt")
      VALUES (gen_random_uuid()::TEXT, v_santri, v_wali_id, TRUE,
              'AYAH', TRUE, now())
      ON CONFLICT DO NOTHING;
    END;
  END LOOP;

  step := 'wali_dan_santri';
  ok := (SELECT count(*) FROM "Wali" WHERE "activationStatus" = 'ACTIVE') >= 2;
  detail := (SELECT count(*) FROM "Santri" WHERE "deletedAt" IS NULL)
            || ' santri, '
            || (SELECT count(*) FROM "SantriWali") || ' tautan wali';
  RETURN NEXT;

  FOR v_negara IN
    SELECT s.id, s."kelasId", s.name
    FROM "Santri" s WHERE s."deletedAt" IS NULL
  LOOP
    DECLARE
      d INT;
      v_status TEXT;
    BEGIN
      FOR d IN 0..13 LOOP
        CONTINUE WHEN EXTRACT(DOW FROM (CURRENT_DATE - d))::INT = 5;
        IF NOT EXISTS (SELECT 1 FROM "Absensi"
                       WHERE "santriId" = v_negara.id
                         AND date::date = (CURRENT_DATE - d)::date) THEN
          v_status := CASE WHEN (d % 7) = 3 THEN 'SAKIT'
                           WHEN (d % 11) = 5 THEN 'IZIN'
                           ELSE 'HADIR' END;
          INSERT INTO "Absensi" (id, "tahunAjaranId", "santriId", "kelasId",
                                 date, status, "recordedByGuruId",
                                 "createdAt", "updatedAt")
          VALUES (gen_random_uuid()::TEXT, v_ta_id, v_negara.id,
                  v_negara."kelasId", (CURRENT_DATE - d), v_status,
                  (SELECT "guruId" FROM "Jadwal"
                   WHERE "kelasId" = v_negara."kelasId" LIMIT 1),
                  now(), now());
        END IF;
      END LOOP;
    END;

    DECLARE
      mp RECORD;
      n INT := 0;
    BEGIN
      FOR mp IN SELECT id FROM "MataPelajaran" WHERE "deletedAt" IS NULL LOOP
        n := n + 1;
        IF NOT EXISTS (SELECT 1 FROM "Nilai"
                       WHERE "santriId" = v_negara.id AND "mapelId" = mp.id
                         AND type = 'UH') THEN
          INSERT INTO "Nilai" (id, "tahunAjaranId", "semesterId", "santriId",
                               "kelasId", "mapelId", "guruId", type, score,
                               "assessmentDate", "createdAt", "updatedAt")
          VALUES (gen_random_uuid()::TEXT, v_ta_id, v_sem_id, v_negara.id,
                  v_negara."kelasId", mp.id,
                  (SELECT "guruId" FROM "Jadwal"
                   WHERE "kelasId" = v_negara."kelasId" LIMIT 1),
                  'UH', 78 + (n % 15), CURRENT_DATE - 7, now(), now());
        END IF;
      END LOOP;
    END;

    DECLARE
      jt TEXT;
    BEGIN
      SELECT id INTO jt FROM "JenisTagihan" WHERE code = 'SPP' LIMIT 1;
      IF jt IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Tagihan" WHERE "santriId" = v_negara.id
          AND "jenisTagihanId" = jt AND "tahunAjaranId" = v_ta_id
      ) THEN
        INSERT INTO "Tagihan" (id, "tahunAjaranId", "santriId", "kelasId",
                               "jenisTagihanId", amount, "paidAmount",
                               description, "dueDate", status,
                               "createdAt", "updatedAt")
        VALUES (gen_random_uuid()::TEXT, v_ta_id, v_negara.id,
                v_negara."kelasId", jt, 150000, 0, 'SPP bulan ini',
                CURRENT_DATE + 10, 'BELUM_BAYAR', now(), now());
      END IF;
    END;
  END LOOP;

  step := 'data_wali';
  ok := (SELECT count(*) FROM "Absensi") > 0 AND (SELECT count(*) FROM "Nilai") > 0;
  detail := (SELECT count(*) FROM "Absensi") || ' absensi, '
            || (SELECT count(*) FROM "Nilai") || ' nilai, '
            || (SELECT count(*) FROM "Tagihan") || ' tagihan';
  RETURN NEXT;

  step := 'selesai';
  ok := TRUE;
  detail := 'Admin mdta@madrasah.com siap. Wali: 081234567801 / 081234567802 (PIN 123456).';
  RETURN NEXT;

  RETURN;
END;
$$;

REVOKE ALL ON FUNCTION public.seed_all_demo() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000031_wali_activation_rpc.sql
-- ==========================================================================


CREATE OR REPLACE FUNCTION public.wali_check_registration(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali         RECORD;
  v_santri_list  JSONB;
  v_anak         INT;
BEGIN
  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'registered', false,
      'message', 'Nomor ini belum terdaftar. Hubungi admin madrasah untuk '
                 'mendaftarkan nomor WhatsApp Anda.'
    );
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'registered', false,
      'message', 'Akun ini dinonaktifkan. Hubungi admin madrasah.'
    );
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', s.id, 'name', s.name, 'nis', s.nis,
           'kelasName', k.name
         ) ORDER BY s.name), '[]'::jsonb),
         count(*)
    INTO v_santri_list, v_anak
  FROM "SantriWali" sw
  JOIN "Santri" s ON s.id = sw."santriId" AND s."deletedAt" IS NULL
  LEFT JOIN "Kelas" k ON k.id = s."kelasId"
  WHERE sw."waliId" = v_wali.id AND sw."canAccess" = TRUE;

  RETURN jsonb_build_object(
    'registered', TRUE,
    'waliId', v_wali.id,
    'name', v_wali.name,
    'phone', v_wali."phone",
    'status', v_wali."activationStatus",
    'needsPin', (v_wali."pinHash" IS NULL OR v_wali."pinHash" = ''),
    'anak', v_santri_list,
    'jumlahAnak', v_anak,
    'message', format('Nomor terdaftar atas nama %s dengan %s anak.',
                      v_wali.name, v_anak)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.wali_activate(
  p_phone       TEXT,
  p_pin         TEXT,
  p_pin_confirm TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_wali RECORD;
  v_lemah TEXT[] := ARRAY[
    '000000','111111','222222','333333','444444','555555','666666',
    '777777','888888','999999',
    '123456','654321','112233','121212','123123','101010','010101',
    '147258','258369','159357','123321','456654'
  ];
  v_auth_password TEXT;
BEGIN
  IF p_pin IS NULL OR length(trim(p_pin)) <> 6
     OR trim(p_pin) !~ '^[0-9]{6}$' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN harus 6 digit angka.');
  END IF;

  IF trim(p_pin) <> trim(COALESCE(p_pin_confirm, '')) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Konfirmasi PIN tidak sama. Periksa kembali.');
  END IF;

  IF trim(p_pin) = ANY (v_lemah) THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN terlalu mudah ditebak. Gunakan kombinasi lain.');
  END IF;

  SELECT * INTO v_wali
  FROM "Wali"
  WHERE "deletedAt" IS NULL
    AND public.normalize_phone("phone") = public.normalize_phone(p_phone)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Nomor belum terdaftar. Hubungi admin madrasah.');
  END IF;

  IF v_wali."activationStatus" = 'SUSPENDED' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Akun dinonaktifkan. Hubungi admin madrasah.');
  END IF;

  IF v_wali."pinHash" IS NOT NULL AND v_wali."pinHash" <> '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'PIN sudah pernah dibuat. Gunakan "Lupa PIN" untuk '
                 'mengubahnya lewat OTP WhatsApp.');
  END IF;

  v_auth_password := COALESCE(
    NULLIF(v_wali."authPassword", ''),
    substring(regexp_replace(encode(gen_random_bytes(32), 'hex'),
                             '[^a-zA-Z0-9]', '', 'g'), 1, 16)
  );

  UPDATE "Wali"
  SET "pinHash" = crypt(trim(p_pin), gen_salt('bf', 10)),
      "activationStatus" = 'ACTIVE',
      "authPassword" = v_auth_password,
      "failedLoginAttempts" = 0,
      "lockedUntil" = NULL,
      "updatedAt" = now()
  WHERE id = v_wali.id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Aktivasi berhasil. Silakan masuk dengan nomor dan PIN Anda.',
    'name', v_wali.name
  );
END;
$$;

DO $$
BEGIN
  BEGIN
    REVOKE ALL ON FUNCTION public.create_wali_test_account(
      TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
  EXCEPTION WHEN undefined_function THEN
    NULL;
  END;
END $$;

CREATE OR REPLACE FUNCTION public.wali_activation_report()
RETURNS TABLE(
  nama_wali   TEXT,
  phone       TEXT,
  status      TEXT,
  pin_terpasang BOOLEAN,
  jumlah_anak BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    w.name,
    w."phone",
    w."activationStatus",
    (w."pinHash" IS NOT NULL AND w."pinHash" <> ''),
    (SELECT count(*) FROM "SantriWali" sw WHERE sw."waliId" = w.id)
  FROM "Wali" w
  WHERE w."deletedAt" IS NULL
  ORDER BY w.name;
$$;

GRANT EXECUTE ON FUNCTION public.wali_check_registration(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.wali_activate(TEXT, TEXT, TEXT) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.wali_activation_report() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ==========================================================================
-- FILE: 20240101000032_fix_auth_user_provisioning.sql
-- ==========================================================================


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.diagnose_login(p_email TEXT)
RETURNS TABLE(langkah TEXT, ok BOOLEAN, keterangan TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email  TEXT := lower(trim(p_email));
  v_uid    UUID;
  v_user   RECORD;
  v_pass   TEXT;
  v_ident  INT;
  v_conf   TIMESTAMPTZ;
  v_banned TIMESTAMPTZ;
  v_roles  TEXT;
BEGIN
  SELECT au.id, au.encrypted_password, au.email_confirmed_at,
         au.banned_until
    INTO v_uid, v_pass, v_conf, v_banned
  FROM auth.users au
  WHERE lower(au.email) = v_email;

  langkah := '1_auth_users';
  ok := v_uid IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ada, uid=' || v_uid::TEXT
                     ELSE 'TIDAK ADA di auth.users — GoTrue akan menolak login. '
                          'Jalankan provision_login_account().' END;
  RETURN NEXT;
  IF NOT ok THEN RETURN; END IF;

  langkah := '2_password_bcrypt';
  ok := v_pass IS NOT NULL AND v_pass LIKE '$2%';
  keterangan := CASE
    WHEN v_pass IS NULL OR v_pass = '' THEN 'password KOSONG'
    WHEN v_pass NOT LIKE '$2%' THEN 'bukan bcrypt (prefix: '
         || left(v_pass, 4) || ')'
    ELSE 'bcrypt ok' END;
  RETURN NEXT;

  langkah := '3_email_confirmed';
  ok := v_conf IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ya'
                     ELSE 'BELUM — login bisa ditolak bila Confirm email aktif' END;
  RETURN NEXT;

  langkah := '4_tidak_diblokir';
  ok := v_banned IS NULL OR v_banned < now();
  keterangan := CASE WHEN ok THEN 'ok'
                     ELSE 'banned_until = ' || v_banned::TEXT END;
  RETURN NEXT;

  SELECT count(*) INTO v_ident FROM auth.identities WHERE user_id = v_uid;
  langkah := '5_auth_identities';
  ok := v_ident > 0;
  keterangan := CASE WHEN ok THEN v_ident || ' baris'
                     ELSE 'TIDAK ADA — GoTrue tidak bisa menemukan user '
                          'untuk login email/password' END;
  RETURN NEXT;

  SELECT u.* INTO v_user FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

  langkah := '6_user_row';
  ok := v_user.id IS NOT NULL;
  keterangan := CASE WHEN ok THEN 'ada, id=' || v_user.id
                     ELSE 'tidak ada baris "User" (aplikasi tetap bisa login, '
                          'tetapi semua data akan kosong)' END;
  RETURN NEXT;
  IF v_user.id IS NULL THEN RETURN; END IF;

  SELECT string_agg(r.code, ', ' ORDER BY r.code) INTO v_roles
  FROM "UserRole" ur JOIN "Role" r ON r.id = ur."roleId"
  WHERE ur."userId" = v_user.id AND ur."isActive";

  langkah := '7_peran';
  ok := v_roles IS NOT NULL;
  keterangan := COALESCE(v_roles, 'TANPA PERAN — semua layar akan kosong');
  RETURN NEXT;

  RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.provision_login_account(
  p_email    TEXT,
  p_password TEXT,
  p_name     TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, auth_uid UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email TEXT := lower(trim(p_email));
  v_name  TEXT := COALESCE(NULLIF(trim(p_name), ''), split_part(lower(trim(p_email)), '@', 1));
  v_uid   UUID;
  v_hash  TEXT;

  v_cols  TEXT[] := ARRAY[]::TEXT[];
  v_vals  TEXT[] := ARRAY[]::TEXT[];
  v_sql   TEXT;
  c       TEXT;
BEGIN
  IF v_email IS NULL OR position('@' IN v_email) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Email tidak valid.', NULL::UUID;
    RETURN;
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN QUERY SELECT FALSE, 'Password minimal 6 karakter.', NULL::UUID;
    RETURN;
  END IF;

  v_hash := crypt(p_password, gen_salt('bf', 10));

  SELECT au.id INTO v_uid FROM auth.users au WHERE lower(au.email) = v_email;

  IF v_uid IS NOT NULL THEN
    UPDATE auth.users
    SET encrypted_password = v_hash,
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        updated_at = now(),
        banned_until = NULL
    WHERE id = v_uid;
  ELSE
    v_uid := gen_random_uuid();

    v_cols := ARRAY['id','instance_id','aud','role','email',
                    'encrypted_password','email_confirmed_at',
                    'created_at','updated_at',
                    'raw_app_meta_data','raw_user_meta_data'];
    v_vals := ARRAY[
      quote_literal(v_uid::TEXT),
      quote_literal('00000000-0000-0000-0000-000000000000'),
      quote_literal('authenticated'),
      quote_literal('authenticated'),
      quote_literal(v_email),
      quote_literal(v_hash),
      'now()', 'now()', 'now()',
      quote_literal(jsonb_build_object(
        'provider','email','providers',jsonb_build_array('email'))::TEXT),
      quote_literal(jsonb_build_object('name', v_name)::TEXT)
    ];

    FOREACH c IN ARRAY ARRAY[
      'confirmation_token','recovery_token','email_change_token_new',
      'email_change','email_change_token_current','phone_change',
      'phone_change_token','reauth_token'
    ] LOOP
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth' AND table_name = 'users'
          AND column_name = c
      ) THEN
        v_cols := v_cols || c;
        v_vals := v_vals || quote_literal('');
      END IF;
    END LOOP;

    v_sql := format(
      'INSERT INTO auth.users (%s) VALUES (%s)',
      array_to_string(array(SELECT quote_ident(x) FROM unnest(v_cols) x), ', '),
      array_to_string(v_vals, ', ')
    );
    EXECUTE v_sql;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_uid) THEN
    INSERT INTO auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_uid, v_uid::TEXT, 'email',
      jsonb_build_object('sub', v_uid::TEXT, 'email', v_email,
                         'email_verified', TRUE, 'phone_verified', FALSE),
      now(), now(), now()
    );
  ELSE
    UPDATE auth.identities
    SET identity_data = jsonb_build_object(
          'sub', v_uid::TEXT, 'email', v_email,
          'email_verified', TRUE, 'phone_verified', FALSE),
        updated_at = now()
    WHERE user_id = v_uid AND provider = 'email';
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun login %s siap (uid=%s).', v_email, v_uid), v_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_create_staff_account(
  p_email       TEXT,
  p_password    TEXT,
  p_name        TEXT,
  p_roles       TEXT[],
  p_phone       TEXT DEFAULT NULL,
  p_username    TEXT DEFAULT NULL,
  p_guru_nip    TEXT DEFAULT NULL,
  p_specialization TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, user_id TEXT, auth_uid UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_email    TEXT := lower(trim(p_email));
  v_username TEXT;
  v_uid      UUID;
  v_user_id  TEXT;
  v_role     TEXT;
  v_role_id  TEXT;
  v_guru_id  TEXT;
  v_msg      TEXT;
BEGIN
  IF v_email IS NULL OR v_email = '' OR position('@' IN v_email) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Email tidak valid.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RETURN QUERY SELECT FALSE, 'Password minimal 6 karakter.', NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  v_username := COALESCE(NULLIF(trim(p_username), ''), split_part(v_email, '@', 1));

  SELECT pl.auth_uid, pl.message INTO v_uid, v_msg
  FROM public.provision_login_account(v_email, p_password, p_name) pl;

  IF v_uid IS NULL THEN
    RETURN QUERY SELECT FALSE,
      format('Gagal membuat akun login untuk %s: %s', v_email, v_msg),
      NULL::TEXT, NULL::UUID;
    RETURN;
  END IF;

  SELECT u.id INTO v_user_id FROM "User" u
  WHERE u."firebaseUid" = v_uid::TEXT OR lower(u.email) = v_email
  ORDER BY (u."firebaseUid" = v_uid::TEXT) DESC NULLS LAST LIMIT 1;

  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid()::TEXT;
    INSERT INTO "User" (id, email, username, name, phone, "firebaseUid",
                        "isActive", "createdAt", "updatedAt")
    VALUES (v_user_id, v_email, v_username, p_name, p_phone, v_uid::TEXT,
            TRUE, now(), now());
  ELSE
    UPDATE "User"
    SET email = v_email,
        username = COALESCE(NULLIF(username, ''), v_username),
        name = p_name,
        phone = COALESCE(p_phone, phone),
        "firebaseUid" = v_uid::TEXT,
        "isActive" = TRUE,
        "deletedAt" = NULL,
        "updatedAt" = now()
    WHERE id = v_user_id;
  END IF;

  FOREACH v_role IN ARRAY COALESCE(p_roles, ARRAY[]::TEXT[]) LOOP
    SELECT r.id INTO v_role_id FROM "Role" r WHERE r.code = v_role;
    IF v_role_id IS NULL THEN
      RETURN QUERY SELECT FALSE,
        format('Peran "%s" tidak dikenal.', v_role), v_user_id, v_uid;
      RETURN;
    END IF;
    INSERT INTO "UserRole" (id, "userId", "roleId", "isActive", "createdAt")
    VALUES (gen_random_uuid()::TEXT, v_user_id, v_role_id, TRUE, now())
    ON CONFLICT ("userId", "roleId") DO UPDATE SET "isActive" = TRUE;
  END LOOP;

  IF 'GURU' = ANY (COALESCE(p_roles, ARRAY[]::TEXT[])) THEN
    SELECT g.id INTO v_guru_id FROM "Guru" g
    WHERE g."userId" = v_user_id AND g."deletedAt" IS NULL LIMIT 1;

    IF v_guru_id IS NULL THEN
      INSERT INTO "Guru" (id, "userId", name, nip, specialization, status,
                          "joinDate", "createdAt", "updatedAt")
      VALUES (gen_random_uuid()::TEXT, v_user_id, p_name, p_guru_nip,
              p_specialization, 'AKTIF', CURRENT_DATE, now(), now());
    ELSE
      UPDATE "Guru" SET name = p_name,
             nip = COALESCE(p_guru_nip, nip),
             specialization = COALESCE(p_specialization, specialization),
             "updatedAt" = now()
      WHERE id = v_guru_id;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    format('Akun %s siap. Peran: %s.', v_email,
           COALESCE(array_to_string(p_roles, ', '), '-')),
    v_user_id, v_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.repair_demo_logins()
RETURNS TABLE(email TEXT, success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  r RECORD;
  v_uid UUID;
  v_msg TEXT;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('mdta@madrasah.com',      'admin@mdta01'),
      ('kepala@madrasah.com',    'kepala123'),
      ('bendahara@madrasah.com', 'bendahara123'),
      ('guru@madrasah.com',      'guru123'),
      ('guru2@madrasah.com',     'guru123')
    ) AS t(mail, pass)
  LOOP
    SELECT pl.auth_uid, pl.message INTO v_uid, v_msg
    FROM public.provision_login_account(r.mail, r.pass, NULL) pl;

    email := r.mail;
    success := v_uid IS NOT NULL;
    message := v_msg;
    RETURN NEXT;

    IF v_uid IS NOT NULL THEN
      UPDATE "User"
      SET "firebaseUid" = v_uid::TEXT, "isActive" = TRUE,
          "deletedAt" = NULL, "updatedAt" = now()
      WHERE lower(email) = r.mail;
    END IF;
  END LOOP;

  RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.demo_account_status()
RETURNS TABLE(
  email        TEXT,
  ada_auth     BOOLEAN,
  email_conf   BOOLEAN,
  bcrypt       BOOLEAN,
  ada_identity BOOLEAN,
  ada_user_row BOOLEAN,
  peran        TEXT,
  siap_login   BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    d.mail,
    (au.id IS NOT NULL),
    (au.email_confirmed_at IS NOT NULL),
    (au.encrypted_password LIKE '$2%'),
    EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = au.id),
    EXISTS (SELECT 1 FROM "User" u WHERE lower(u.email) = d.mail),
    COALESCE((
      SELECT string_agg(r.code, ', ' ORDER BY r.code)
      FROM "User" u
      JOIN "UserRole" ur ON ur."userId" = u.id AND ur."isActive"
      JOIN "Role" r ON r.id = ur."roleId"
      WHERE lower(u.email) = d.mail
    ), '—'),
    (au.id IS NOT NULL
     AND au.email_confirmed_at IS NOT NULL
     AND au.encrypted_password LIKE '$2%'
     AND EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = au.id)
     AND EXISTS (SELECT 1 FROM "User" u WHERE lower(u.email) = d.mail))
  FROM (VALUES
      ('mdta@madrasah.com'),
      ('kepala@madrasah.com'),
      ('bendahara@madrasah.com'),
      ('guru@madrasah.com'),
      ('guru2@madrasah.com')
  ) AS d(mail)
  LEFT JOIN auth.users au ON lower(au.email) = d.mail
  ORDER BY d.mail;
$$;

REVOKE ALL ON FUNCTION public.diagnose_login(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.provision_login_account(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_create_staff_account(TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.repair_demo_logins() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.demo_account_status() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';


-- ============================================================================
-- BAGIAN AKHIR — DATA DEMO
-- ============================================================================
-- Hapus tanda komentar pada baris di bawah, lalu Run sekali lagi.
-- Baris pertama mengisi data akademik & keuangan + akun demo.
-- Baris kedua memastikan akun login (auth.users) benar-benar terbentuk.
--
-- SELECT * FROM public.seed_all_demo();
--
-- Setelah seed: perbaiki/pastikan akun login bisa dipakai
-- SELECT * FROM public.repair_demo_logins();
--
-- Verifikasi (kolom siap_login harus true untuk semua baris)
-- SELECT * FROM public.demo_account_status();
--
-- Kredensial demo:
--   Admin      mdta@madrasah.com        / admin@mdta01
--   Kepala     kepala@madrasah.com      / kepala123
--   Bendahara  bendahara@madrasah.com   / bendahara123
--   Guru       guru@madrasah.com        / guru123
--   Wali       081234567801             / PIN 123456
-- ============================================================================
