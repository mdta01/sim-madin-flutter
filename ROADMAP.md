# SIM MADIN Flutter — Migration Roadmap

> Versi live: lihat file `docs/PHASES.md` untuk checklist per-fase.
> Versi analitis: lihat `download/MIGRATION-ANALYSIS.md` di repo lama.

## Ringkasan Tujuan

| Sebelum (TypeScript) | Sesudah (Dart) |
|---|---|
| Next.js API (115 admin + 19 wali routes) | Serverpod endpoints (auto-generate client) |
| React Native 0.74 + Hermes (mobile) | Flutter (mobile) |
| React Web (admin web) | Flutter Desktop (Windows/macOS/Linux) |
| Prisma ORM | Serverpod ORM |
| Supabase Auth (admin/guru/bendahara/kepala) | Serverpod Auth |
| Custom JWT WA+PIN (wali) | Serverpod custom auth module |
| Supabase Postgres | **Sama** (tetap Supabase) |
| Supabase Realtime | **Sama** (tetap Supabase Realtime) |

## Estimasi Per Fase

| Fase | Fokus | Durasi | Output |
|------|------|--------|--------|
| 1 | Foundation | 1-2 minggu | Monorepo + shared packages + backend skeleton |
| 2 | mobile_kepala | 2-3 minggu | 9 screens read-only |
| 3 | mobile_bendahara | 3-4 minggu | 8 screens keuangan + PDF |
| 4 | mobile_guru | 3-4 minggu | 13 screens akademik |
| 5 | mobile_wali | 4-6 minggu | Multi-anak + ujian online + WA auth |
| 6 | admin_desktop | 8-12 minggu | 34 views desktop |
| 7 | Production | 1-2 minggu | Migration, deploy, training |

## Fase Detail

### Phase 1 — Foundation (2 minggu)

#### Tujuan
- Setup monorepo (Melos + pubspec workspace)
- Buat 5 skeleton apps + 3 packages + 1 backend
- Implementasi auth + 1 endpoint contoh per app
- CI/CD GitHub Actions

#### Checklist
- [x] Buat repo `sim-madin-flutter` di GitHub
- [x] Setup struktur folder monorepo
- [x] `melos.yaml` dengan scripts (bootstrap, gen, build:*)
- [x] `.gitignore` untuk Dart/Flutter/Serverpod
- [x] `README.md` dengan stack & quick start
- [x] `ROADMAP.md` (file ini)
- [ ] `packages/shared` — port dari TS:
  - [ ] `lib/constants.dart` (Colors, DAYS, STATUS_STYLES, 34 menu sidebar items)
  - [ ] `lib/theme.dart` (Islamic green #0D7A4F + gold #D4A017)
  - [ ] `lib/models/` (48 model: Santri, Wali, Guru, Kelas, Mapel, Absensi, Nilai, Tagihan, Pembayaran, Jadwal, Pertemuan, Rapor, Ujian, BankSoal, Tugas, Pengumpulan, Materi, Kompetensi, TahunAjaran, Siklus, Kas, HonorGuru, Notifikasi, Chat, Surat, Perkembangan, AuditLog, Users, Roles, Permissions, etc.)
  - [ ] `lib/utils.dart` (formatRupiah, formatDate, normalizeWhatsApp, dll)
  - [ ] `lib/types.dart` (Permission codes, 60 enum)
- [ ] `packages/supabase_client` — wrapper config (URL, anon key, schema, realtime helper)
- [ ] `packages/api_client` — Serverpod client wrapper + Riverpod providers
- [ ] Backend Serverpod skeleton:
  - [ ] `serverpod.yaml` config (Supabase connection)
  - [ ] Migrations dari Prisma schema
  - [ ] Endpoints: `AuthAdmin` (login email/pass), `AuthWali` (login WA+PIN, request OTP, verify OTP)
  - [ ] Generated client code
- [ ] Skeleton 5 apps:
  - [ ] `apps/admin_desktop` — Flutter desktop, login page (admin email/pass)
  - [ ] `apps/mobile_wali` — Flutter mobile, login page (WA+PIN)
  - [ ] `apps/mobile_guru` — Flutter mobile, login page (email+pass)
  - [ ] `apps/mobile_bendahara` — Flutter mobile, login page (email+pass)
  - [ ] `apps/mobile_kepala` — Flutter mobile, login page (email+pass)
- [ ] CI/CD: GitHub Actions
  - [ ] `.github/workflows/build-mobile-apk.yml` (4 APK via flutter build apk)
  - [ ] `.github/workflows/build-desktop.yml` (Windows/macOS/Linux binaries)
  - [ ] `.github/workflows/backend-deploy.yml` (deploy Serverpod)

### Phase 2 — mobile_kepala (2-3 minggu)

#### Tujuan
Implementasi mobile paling sederhana (read-only dashboard + monitor views) sebagai proof-of-concept arsitektur.

#### Screens (dari App.tsx mobile-kepala saat ini)
1. Login (Supabase Auth)
2. Dashboard (chart keuangan & akademik)
3. Santri list (read-only)
4. Absensi monitor
5. Nilai monitor
6. Tagihan monitor
7. Pembayaran monitor
8. Honor guru monitor
9. Laporan keuangan monitor

#### Deliverables
- Riverpod providers (async, future, family)
- Realtime subscription ke 4 tabel
- Navigation: bottom tab + nested routes via go_router
- Theme Islamic green/gold

### Phase 3 — mobile_bendahara (3-4 minggu)

#### Tujuan
Implementasi keuangan CRUD + PDF viewer untuk slip pembayaran.

#### Screens (8 dari App.tsx mobile-bendahara)
1. Login (Supabase Auth)
2. Dashboard (statistik keuangan hari ini)
3. Pembayaran list + detail + create + verify
4. Tagihan list + generate tunggakan
5. Kas list + transaksi CRUD
6. Honor guru list + generate + slip PDF
7. Laporan keuangan (chart + filter periode)
8. Profile

#### Komponen kritis
- PDF generation (slip pembayaran, kwitansi)
- Bulk transaction dengan rollback
- Compute-on-read untuk auto-tagihan

### Phase 4 — mobile_guru (3-4 minggu)

#### Tujuan
Implementasi akademik CRUD + ujian management.

#### Screens (13 dari App.tsx mobile-guru)
1. Login
2. Dashboard (kelas yang diajar)
3. Santri list (per kelas)
4. Absensi input (per pertemuan)
5. Nilai input (per mapel per kelas)
6. Materi list + create + upload file
7. Tugas list + create + pengumpulan + grade
8. Pertemuan list + generate from jadwal + auto-complete
9. Ujian list + create + soal + peserta
10. Perkembangan santri (akhlak/quran/kitab/pembinaan/catatan-wali)
11. Chat dengan wali
12. Jadwal mengajar
13. Profile

#### Komponen kritis
- DateTimePicker untuk pertemuan
- File upload (materi, tugas, pengumpulan)
- Realtime subscription (chat, pengumuman)
- Auto-complete pertemuan (compute-on-read)

### Phase 5 — mobile_wali (4-6 minggu)

#### Tujuan
Implementasi mobile paling kompleks: multi-anak, ujian online, WA+PIN auth.

#### Screens (4 + 2 modal dari App.tsx mobile-wali)
1. Login (WA + PIN)
2. Forgot PIN (OTP via WhatsApp)
3. Dashboard (list anak)
4. Santri detail (6 tab: Profil, Akademik, Ujian, Keuangan, Notif, Info)
5. Ujian take screen (timer + Fisher-Yates shuffle + anti-cheat + recovery)
6. Chat dengan guru

#### Komponen kritis
- WhatsApp OTP request + verify (rate-limited 5/jam)
- bcrypt PIN verification
- Auto-lock 5x salah PIN (15 menit lockout)
- Blacklist 50 PIN lemah (123456, 000000, dll)
- JWT verify client-side (Hermes-compatible decode tanpa WebCrypto — tidak relevan di Flutter, pakai crypto package native)
- Realtime: 21 subscriptions per wali (1 notif + 5 santri × 4 tabel)
- Ujian: Fisher-Yates shuffle soal + shuffle option order, persist per santri
- Anti-cheat: deteksi app background/tab switch

### Phase 6 — admin_desktop (8-12 minggu)

#### Tujuan
Port 34 views dari React web ke Flutter Desktop.

#### Views (34 menu sidebar)
1. Dashboard (chart keuangan & akademik)
2. Santri (CRUD + import + photo + kartu PDF)
3. Wali (CRUD + OTP invite + reset PIN)
4. Guru (CRUD + stats + kartu PDF)
5. Kelas (CRUD + tahun ajaran)
6. Mapel (CRUD + kompetensi)
7. Jadwal (CRUD + generate pertemuan)
8. Pertemuan (CRUD + auto-complete + nilai + absensi)
9. Absensi (CRUD + bulk + filter periode)
10. Nilai (CRUD + bulk grade + filter)
11. Tahun ajaran (CRUD + activate)
12. Siklus (overview + auto-tagihan + kenaikan kelas + payment-verify)
13. Tagihan (CRUD + jenis-tagihan + generate bulk)
14. Pembayaran (CRUD + verify + kwitansi PDF)
15. Kas (CRUD + transaksi + laporan)
16. Honor guru (CRUD + slip PDF)
17. Tugas (CRUD + pengumpulan + bulk grade)
18. Materi (CRUD + upload)
19. Ujian (CRUD + soal + peserta + kartu PDF + leger)
20. Bank soal (CRUD)
21. Rapor (generate + catatan + mapel + PDF)
22. Kompetensi (CRUD)
23. Pengumuman (CRUD + send notif)
24. Notifikasi (CRUD + send + mark-all-read)
25. Surat (CRUD + PDF + jenis)
26. Perkembangan (akhlak/quran/kitab/pembinaan/catatan-wali)
27. Alumni (CRUD + surat-lulus + sertifikat)
28. Chat (rooms + messages)
29. QR (santri/guru + scan-log)
30. Audit log (read-only)
31. Users (CRUD + roles + permissions)
32. Roles (CRUD + permissions matrix)
33. Permissions (matrix editor)
34. Settings (CRUD global settings)

#### Komponen kritis
- Data table dengan sort, filter, pagination, bulk action
- Form builder dengan validation
- File upload (photo santri, materi, tugas, pengumpulan)
- PDF viewer & generator (rapor, kwitansi, slip, kartu, surat)
- Chart (line, bar, pie, area) untuk dashboard
- Permission matrix (60 codes: 15 modul × 4 action)
- Audit log viewer dengan filter
- Soft delete (paranoid mode)

### Phase 7 — Production (1-2 minggu)

#### Tujuan
Migrasi data, deploy, training.

#### Checklist
- [ ] Migrate Supabase schema (drop enum type, convert ke string + CHECK constraint)
- [ ] Backup data existing (snapshots per tabel)
- [ ] Deploy Serverpod production (Railway / Render / self-hosted VPS)
- [ ] Setup domain + SSL
- [ ] Setup FCM untuk push notifikasi mobile
- [ ] User training: admin, wali, guru, bendahara, kepala
- [ ] Rollout bertahap (1 madrasah pilot → 5 → 20 → semua)

## Risks & Mitigations

1. **Serverpod ORM maturity** — belum sebanyak Prisma. Mitigasi: pakai raw SQL untuk query kompleks.
2. **Supabase Realtime di Flutter** — kurang mature dibanding JS SDK. Mitigasi: pakai `supabase_flutter` official + fallback polling.
3. **Desktop Flutter untuk 34 admin views** — belum banyak contoh. Mitigasi: port per view, mulai dari paling sederhana (Users CRUD).
4. **Data migration dari PascalCase ke camelCase** — Postgres case-sensitive. Mitigasi: tetap pakai PascalCase di Serverpod, supabase_flutter handle case-insensitive mapping.
5. **Ujian online di Flutter** — timer & Fisher-Yates port langsung dari TS logic, harus verify behavior sama.

## Pendekatan Eksekusi

- **Backend first** — Serverpod + auth + 1 endpoint contoh, supaya semua app bisa login dari hari 1.
- **Mobile apps paling simple dulu** — kepala → bendahara → guru → wali (urutan naik kompleksitas).
- **Admin desktop terakhir** — karena 34 views butuh waktu lama, dan mobile lebih urgent (admin web existing masih jalan).
- **Continuous integration dari hari 1** — GitHub Actions wajib untuk build APK & desktop setiap commit, supaya tidak ada surprise di akhir.

## Updated Estimate

| Komponen | Estimasi |
|---|---|
| Phase 1 (Foundation) | 1-2 minggu |
| Phase 2 (kepala) | 2-3 minggu |
| Phase 3 (bendahara) | 3-4 minggu |
| Phase 4 (guru) | 3-4 minggu |
| Phase 5 (wali) | 4-6 minggu |
| Phase 6 (admin desktop) | 8-12 minggu |
| Phase 7 (production) | 1-2 minggu |
| **Total** | **22-33 minggu** (5-8 bulan) |

Bisa dipercepat dengan paralelisasi: Phase 2-5 bisa paralel kalau ada multiple developer. Phase 6 baru mulai setelah Phase 5 selesai karena butuh shared components yang dibangun di phase 2-5.
