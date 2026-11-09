-- ============================================================================
-- SIM MADIN — Rekonsiliasi skema (dibuat otomatis)
-- ============================================================================
-- Dibuat oleh tool/gen_schema_reconcile.py — JANGAN diedit manual.
--
-- LATAR BELAKANG
--   Baseline memakai CREATE TABLE IF NOT EXISTS. Bila tabel sudah ada dari
--   skema versi lama, perintah itu tidak melakukan apa pun, sehingga kolom
--   baru TIDAK PERNAH ditambahkan. Gejalanya:
--
--       ERROR: 42703: column "isPublished" does not exist
--
--   Migrasi ini menambahkan setiap kolom yang belum ada pada tabel yang sudah
--   ada. Kolom yang sudah terpasang dilewati sepenuhnya oleh IF NOT EXISTS,
--   sehingga tipe, default, dan constraint yang ada tidak berubah.
--
--   Hanya MENAMBAH kolom. Tidak ada DROP maupun ALTER TYPE.
--   Idempotent: aman dijalankan berulang.
-- ============================================================================

-- CATATAN PENYESUAIAN
--   * Absensi."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Absensi."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Absensi."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Absensi."date" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Absensi."status" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Absensi."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AkhlakPenilaian."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AkhlakPenilaian."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AkhlakPenilaian."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AkhlakPenilaian."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Alumni."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Alumni."tahunLulus" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Alumni."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Announcement."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Announcement."content" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Announcement."audience" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Announcement."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AuditLog."action" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * AuditLog."module" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."question" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * BankSoal."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."periode" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."catatan" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * CatatanWaliKelas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * ChatMessage."chatRoomId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * ChatMessage."senderType" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * ChatMessage."message" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * ChatRoom."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * ChatRoom."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Guru."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Guru."gender" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Guru."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."kitabName" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HafalanKitab."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."guruId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."periode" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."periodeLabel" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * HonorGuru."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."guruId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."dayOfWeek" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."startTime" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."endTime" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Jadwal."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * JenisTagihan."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * JenisTagihan."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * JenisTagihan."defaultAmount" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * JenisTagihan."category" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * JenisTagihan."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kas."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kas."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kas."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kelas."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kelas."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kelas."level" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kelas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kompetensi."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kompetensi."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kompetensi."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kompetensi."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Kompetensi."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * MataPelajaran."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * MataPelajaran."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * MataPelajaran."category" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * MataPelajaran."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Materi."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Materi."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Materi."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Materi."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Materi."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."score" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Nilai."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Notifikasi."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Notifikasi."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Notifikasi."message" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Payment."invoiceNo" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Payment."amount" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Payment."paymentMethod" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Payment."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."description" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pembinaan."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PengumpulanTugas."tugasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PengumpulanTugas."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PengumpulanTugas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PerkembanganQuran."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PerkembanganQuran."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PerkembanganQuran."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PerkembanganQuran."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PerkembanganQuran."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Permission."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Permission."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Permission."module" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."pertemuanKe" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."date" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Pertemuan."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PhoneChangeLog."waliId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * PhoneChangeLog."newPhone" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * QRScan."qrType" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * QRScan."entityId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * QRScan."scanType" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Rapor."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Rapor."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Rapor."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Rapor."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Rapor."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporCatatan."raporId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporCatatan."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporMapel."raporId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporMapel."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporMapel."nilaiAkhir" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RaporMapel."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Role."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Role."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Role."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RolePermission."roleId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * RolePermission."permissionId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Santri."nis" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Santri."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Santri."gender" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Santri."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SantriWali."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SantriWali."waliId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SantriWali."relationship" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."startDate" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."endDate" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Semester."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Surat."nomorSurat" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Surat."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Surat."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Surat."content" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Surat."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SystemSetting."key" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SystemSetting."value" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * SystemSetting."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tagihan."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tagihan."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tagihan."jenisTagihanId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tagihan."amount" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tagihan."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TahunAjaran."code" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TahunAjaran."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TahunAjaran."startDate" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TahunAjaran."endDate" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TahunAjaran."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."kasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."category" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."amount" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."description" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * TransaksiKas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."dueDate" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Tugas."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."tahunAjaranId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."semesterId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."mapelId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."kelasId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."title" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."startTime" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."endTime" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Ujian."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianJawaban."sesiId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianJawaban."ujianSoalId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianJawaban."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianJawaban."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianNilai."ujianId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianNilai."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianNilai."score" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianNilai."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianPeserta."ujianId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianPeserta."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSesi."ujianId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSesi."santriId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSesi."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSoal."ujianId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSoal."bankSoalId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UjianSoal."urutan" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * User."email" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * User."username" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * User."passwordHash" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * User."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * User."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UserRole."userId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * UserRole."roleId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Wali."name" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * Wali."updatedAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliActivation."waliId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliActivation."token" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliActivation."otpCode" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliActivation."type" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliActivation."expiresAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliPinReset."waliId" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliPinReset."otpHash" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal
--   * WaliPinReset."expiresAt" aslinya NOT NULL tanpa DEFAULT; ditambahkan sebagai nullable agar baris lama tidak gagal

-- 633 perintah ALTER TABLE

-- Absensi
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "date" timestamp(3) with time zone;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "status" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "note" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "recordedByGuruId" text;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Absensi" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- AkhlakPenilaian
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "adabGuru" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "adabOrangTua" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "adabTeman" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "kedisiplinan" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "kebersihan" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "tanggungJawab" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "rataRata" double precision DEFAULT 0;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "predikat" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "periode" text;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "periodeDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "AkhlakPenilaian" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Alumni
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "tahunLulus" integer;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "tahunAjaranLulusId" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "statusKelulusan" text DEFAULT 'LULUS';
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "nilaiAkhir" double precision;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "predikatAkhir" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "syaratNilaiLengkap" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "syaratAbsensiCukup" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "syaratTagihanLunas" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "syaratUjianAkhir" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "syaratLainnya" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "suratKeteranganLulus" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "sertifikat" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "piagam" boolean DEFAULT false;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "beritaAcaraId" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "pendidikanLanjutan" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "pekerjaan" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "telepon" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "email" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "domisiliKota" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "domisiliAlamat" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "aktivitasAlumni" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "tanggalLulus" timestamp(3) with time zone;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "createdById" text;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Alumni" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Announcement
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "content" text;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "audience" text;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "priority" text DEFAULT 'NORMAL';
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "publishedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "expiresAt" timestamp(3) with time zone;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "createdById" text;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "filePath" TEXT;
ALTER TABLE "Announcement" ADD COLUMN IF NOT EXISTS "fileUrl" TEXT;

-- AuditLog
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "userId" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "action" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "module" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "entityId" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "entityType" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "changes" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "ip" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "userAgent" text;
ALTER TABLE "AuditLog" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- BankSoal
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "question" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "options" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "correctAnswer" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "answerKey" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "bobot" double precision DEFAULT 1;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "difficulty" text DEFAULT 'SEDANG';
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "kompetensiId" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "tags" text;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "BankSoal" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- CatatanWaliKelas
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "waliKelasId" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "periode" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "periodeDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "rekomendasi" text;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "CatatanWaliKelas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- ChatMessage
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "chatRoomId" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "senderType" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "senderWaliId" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "senderGuruId" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "senderUserId" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "message" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "attachments" text;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "isRead" boolean DEFAULT false;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "readAt" timestamp(3) with time zone;
ALTER TABLE "ChatMessage" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- ChatRoom
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "lastMessageAt" timestamp(3) with time zone;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "lastMessage" text;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "ChatRoom" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Guru
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "userId" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "nip" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "nuptk" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "gender" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "birthPlace" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "birthDate" timestamp(3) with time zone;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "address" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "phone" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "email" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "photoUrl" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "joinDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "specialization" text;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'AKTIF';
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Guru" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;

-- HafalanKitab
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "kitabName" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "halaman" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'PROGRESS';
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "target" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "pertemuanDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "HafalanKitab" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- HonorGuru
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "periode" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "periodeLabel" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "honorMengajar" double precision DEFAULT 0;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "insentif" double precision DEFAULT 0;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "tunjangan" double precision DEFAULT 0;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "potongan" double precision DEFAULT 0;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "totalHonor" double precision DEFAULT 0;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'DRAFT';
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "paidAt" timestamp(3) with time zone;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "kasId" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "HonorGuru" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Jadwal
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "dayOfWeek" integer;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "startTime" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "endTime" text;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Jadwal" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- JenisTagihan
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "defaultAmount" integer;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "category" text;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "JenisTagihan" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Kas
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "accountNumber" text;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "bankName" text;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "balance" double precision DEFAULT 0;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Kas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Kelas
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "level" text;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "capacity" integer DEFAULT 30;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "sortOrder" integer DEFAULT 0;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "Kelas" ADD COLUMN IF NOT EXISTS "waliKelasId" text;

-- Kompetensi
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "category" text DEFAULT 'UMUM';
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "sortOrder" integer DEFAULT 0;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Kompetensi" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- MataPelajaran
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "category" text;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "kkm" double precision DEFAULT 70;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "durationMnt" integer DEFAULT 90;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "sortOrder" integer DEFAULT 0;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "MataPelajaran" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;

-- Materi
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "type" text DEFAULT 'DOKUMEN';
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "fileUrl" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "externalUrl" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "pertemuan" integer;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "sortOrder" integer DEFAULT 0;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "publishedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "createdById" text;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "Materi" ADD COLUMN IF NOT EXISTS "filePath" TEXT;

-- Nilai
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "kompetensiId" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "notes" text;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "assessmentDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Nilai" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Notifikasi
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "message" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "priority" text DEFAULT 'NORMAL';
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "isRead" boolean DEFAULT false;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "readAt" timestamp(3) with time zone;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "entityType" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "entityId" text;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "isEmailSent" boolean DEFAULT false;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "isPushSent" boolean DEFAULT false;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Notifikasi" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ;

-- Payment
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "invoiceNo" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "tagihanId" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "amount" double precision;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "paymentMethod" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "paymentDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'VERIFIED';
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "note" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "proofUrl" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "recordedById" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "kasId" text;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Pembinaan
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "category" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "severity" text DEFAULT 'RINGAN';
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "tindakan" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'OPEN';
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "resolvedAt" timestamp(3) with time zone;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "resolvedById" text;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Pembinaan" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- PengumpulanTugas
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "tugasId" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "fileUrl" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "textAnswer" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "submittedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'SUBMITTED';
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "feedback" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "gradedAt" timestamp(3) with time zone;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "gradedById" text;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "PengumpulanTugas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- PerkembanganQuran
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "surah" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "juz" integer;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "ayatFrom" integer;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "ayatTo" integer;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'PROGRESS';
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "target" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "pertemuanDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "PerkembanganQuran" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Permission
ALTER TABLE "Permission" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Permission" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Permission" ADD COLUMN IF NOT EXISTS "module" text;
ALTER TABLE "Permission" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Permission" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- Pertemuan
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "pertemuanKe" integer;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "date" timestamp(3) with time zone;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "topic" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "isCompleted" boolean DEFAULT false;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Pertemuan" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- PhoneChangeLog
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "oldPhone" text;
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "newPhone" text;
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "changedById" text;
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "changedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "PhoneChangeLog" ADD COLUMN IF NOT EXISTS "reason" text;

-- QRScan
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "qrType" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "entityId" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "scanType" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "scannedById" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "deviceInfo" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "location" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "result" text DEFAULT 'SUCCESS';
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "message" text;
ALTER TABLE "QRScan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- Rapor
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "notes" text;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "absensiHadir" integer DEFAULT 0;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "absensiSakit" integer DEFAULT 0;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "absensiIzin" integer DEFAULT 0;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "absensiAlfa" integer DEFAULT 0;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "published" boolean DEFAULT false;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "publishedAt" timestamp(3) with time zone;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Rapor" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- RaporCatatan
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "raporId" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "catatanWaliKelas" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "prestasi" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "akhlak" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "kehadiran" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "saran" text;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "RaporCatatan" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- RaporMapel
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "raporId" text;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "nilaiAkhir" double precision;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "predikat" text;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "deskripsi" text;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "kkm" double precision DEFAULT 70;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "isTuntas" boolean DEFAULT false;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "RaporMapel" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Role
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "sortOrder" integer DEFAULT 0;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "isSystem" boolean DEFAULT false;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Role" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- RolePermission
ALTER TABLE "RolePermission" ADD COLUMN IF NOT EXISTS "roleId" text;
ALTER TABLE "RolePermission" ADD COLUMN IF NOT EXISTS "permissionId" text;
ALTER TABLE "RolePermission" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- Santri
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "nis" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "nisn" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "gender" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "birthPlace" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "birthDate" timestamp(3) with time zone;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "address" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "phone" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "photoUrl" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "entryDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'AKTIF';
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "userId" text;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Santri" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;

-- SantriWali
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "relationship" text;
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "isPrimary" boolean DEFAULT false;
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "canAccess" boolean DEFAULT true;
ALTER TABLE "SantriWali" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- Semester
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "startDate" timestamp(3) with time zone;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "endDate" timestamp(3) with time zone;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT false;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Semester" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Surat
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "nomorSurat" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "content" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "periodeMulai" timestamp(3) with time zone;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "periodeSelesai" timestamp(3) with time zone;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "tempat" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "tanggalSurat" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'DRAFT';
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "signedBy" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "signedAt" timestamp(3) with time zone;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "createdById" text;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "filePath" TEXT;
ALTER TABLE "Surat" ADD COLUMN IF NOT EXISTS "fileUrl" TEXT;

-- SystemSetting
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "key" text;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "value" text;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "type" text DEFAULT 'STRING';
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "updatedBy" text;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "description" TEXT;
ALTER TABLE "SystemSetting" ADD COLUMN IF NOT EXISTS "isPublic" BOOLEAN DEFAULT false;

-- Tagihan
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "jenisTagihanId" text;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "amount" double precision;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "paidAmount" double precision DEFAULT 0;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "dueDate" timestamp(3) with time zone;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'BELUM_BAYAR';
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Tagihan" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- TahunAjaran
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "code" text;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "startDate" timestamp(3) with time zone;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "endDate" timestamp(3) with time zone;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT false;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "TahunAjaran" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- TransaksiKas
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "kasId" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "category" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "amount" double precision;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "reference" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "paymentId" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "honorGuruId" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "transaksiDate" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "recordedById" text;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "TransaksiKas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- Tugas
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "materiId" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "type" text DEFAULT 'INDIVIDU';
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "fileUrl" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "maxScore" double precision DEFAULT 100;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "dueDate" timestamp(3) with time zone;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT true;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "publishedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "createdById" text;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "Tugas" ADD COLUMN IF NOT EXISTS "filePath" TEXT;

-- Ujian
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "tahunAjaranId" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "semesterId" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "mapelId" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "kelasId" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "guruId" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "title" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "description" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "startTime" timestamp(3) with time zone;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "endTime" timestamp(3) with time zone;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "durationMnt" integer DEFAULT 90;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "ruang" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "pengawas" text;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "isPublished" boolean DEFAULT false;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "maxScore" double precision DEFAULT 100;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "passingScore" double precision;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "filePath" TEXT;
ALTER TABLE "Ujian" ADD COLUMN IF NOT EXISTS "fileUrl" TEXT;

-- UjianJawaban
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "sesiId" text;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "ujianSoalId" text;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "answer" text;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "optionOrder" text;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "isCorrect" boolean;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "isAutoCorrected" boolean DEFAULT false;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "UjianJawaban" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- UjianNilai
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "ujianId" text;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "scoreUts" double precision;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "scoreUas" double precision;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "scorePraktik" double precision;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "notes" text;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "gradedById" text;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "gradedAt" timestamp(3) with time zone;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "isAutoCorrect" boolean DEFAULT false;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "UjianNilai" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- UjianPeserta
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "ujianId" text;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "ruang" text;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "pengawas" text;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "isHadir" boolean DEFAULT true;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "catatan" text;
ALTER TABLE "UjianPeserta" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- UjianSesi
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "ujianId" text;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "santriId" text;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "startTime" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "endTime" timestamp(3) with time zone;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "durationUsed" integer;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "score" double precision;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'NOT_STARTED';
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "soalOrder" text;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "isAutoCorrected" boolean DEFAULT false;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "UjianSesi" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;

-- UjianSoal
ALTER TABLE "UjianSoal" ADD COLUMN IF NOT EXISTS "ujianId" text;
ALTER TABLE "UjianSoal" ADD COLUMN IF NOT EXISTS "bankSoalId" text;
ALTER TABLE "UjianSoal" ADD COLUMN IF NOT EXISTS "urutan" integer;
ALTER TABLE "UjianSoal" ADD COLUMN IF NOT EXISTS "bobot" double precision DEFAULT 1;
ALTER TABLE "UjianSoal" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- User
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "email" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "username" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "passwordHash" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "phone" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "avatarUrl" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "firebaseUid" text;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastLoginAt" timestamp(3) with time zone;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- UserRole
ALTER TABLE "UserRole" ADD COLUMN IF NOT EXISTS "userId" text;
ALTER TABLE "UserRole" ADD COLUMN IF NOT EXISTS "roleId" text;
ALTER TABLE "UserRole" ADD COLUMN IF NOT EXISTS "isActive" boolean DEFAULT true;
ALTER TABLE "UserRole" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- Wali
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "userId" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "name" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "nik" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "phone" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "email" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "occupation" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "address" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "relationship" text DEFAULT 'WALI';
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "activationStatus" text DEFAULT 'PENDING';
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "pinHash" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "otpCode" text;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "otpExpiresAt" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "otpAttempts" integer DEFAULT 0;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "otpRequestCount" integer DEFAULT 0;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "otpRequestResetAt" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "failedLoginAttempts" integer DEFAULT 0;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "lockedUntil" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "lastLoginAt" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "updatedAt" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "deletedAt" timestamp(3) with time zone;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "photoUrl" TEXT;
ALTER TABLE "Wali" ADD COLUMN IF NOT EXISTS "authPassword" TEXT;

-- WaliActivation
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "waliId" text;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "token" text;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "otpCode" text;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "type" text;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "expiresAt" timestamp(3) with time zone;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "usedAt" timestamp(3) with time zone;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "attempts" integer DEFAULT 0;
ALTER TABLE "WaliActivation" ADD COLUMN IF NOT EXISTS "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP;

-- WaliPinReset
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "waliId" TEXT;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "otpHash" TEXT;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "expiresAt" TIMESTAMPTZ;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "attempts" INTEGER DEFAULT 0;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "consumedAt" TIMESTAMPTZ;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "resetTokenHash" TEXT;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "resetTokenExpiresAt" TIMESTAMPTZ;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "requestedIp" TEXT;
ALTER TABLE "WaliPinReset" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT now();

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- Setelah menjalankan ini, coba ulang:
--   SELECT * FROM public.seed_all_demo();
--   SELECT * FROM public.repair_demo_logins();
--   SELECT * FROM public.demo_account_status();
-- ============================================================================
