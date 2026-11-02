# SIM MADIN Flutter — Phase Checklist

> Live tracking progress per fase. ROADMAP.md berisi estimasi + spesifikasi;
> file ini berisi checklist real-time (update setiap commit).

## Status Terakhir

- **Tanggal update**: 2026-11-02
- **Fase aktif**: Phase 2 (mobile_kepala) — **in progress**
- **Branch**: `main`
- **Commit terakhir Phase 2**: TBD

---

## Phase 1 — Foundation ✅ (DONE)

### Monorepo & Tooling
- [x] Repo `sim-madin-flutter` di GitHub
- [x] `melos.yaml` dengan scripts (bootstrap, gen, build:*)
- [x] `.gitignore` untuk Dart/Flutter/Serverpod
- [x] `README.md` dengan stack & quick start
- [x] `ROADMAP.md`
- [x] `analysis_options.yaml` + `very_good_analysis`

### Shared Package (`packages/shared`)
- [x] `lib/constants.dart` — 34 menu items, 60 permission strings, Roles, JenisTagihan, UjianStatus, OtpConfig, kBlacklistedPins
- [x] `lib/theme.dart` — AppColors (Islamic green #0D7A4F + gold #D4A017), StatusStyles, AppFonts, AppRadius, AppSpacing, appThemeLight
- [x] `lib/utils.dart` — 18 helper (formatRupiah, formatDate, formatDateTime, normalizeWhatsApp, getInitials, fisherYatesShuffle, dll)
- [x] `lib/models/` (Phase 2 — 10 model plain Dart):
  - [x] `user.dart` — UserModel, RoleModel
  - [x] `tahun_ajaran.dart` — TahunAjaranModel, SemesterModel
  - [x] `kelas.dart` — KelasModel
  - [x] `mata_pelajaran.dart` — MataPelajaranModel, MapelCategory
  - [x] `santri.dart` — SantriModel, SantriStatus, SantriGender
  - [x] `guru.dart` — GuruModel, GuruStatus
  - [x] `absensi.dart` — AbsensiModel, AbsensiStatus
  - [x] `nilai.dart` — NilaiModel, NilaiType, isLulus()
  - [x] `tagihan.dart` — TagihanModel, JenisTagihanModel, TagihanStatus, tagihanOutstanding()
  - [x] `payment.dart` — PaymentModel, PaymentMethod, PaymentStatus
  - [x] `kas.dart` — KasModel, TransaksiKasModel, KasType, TransaksiKasType, TransaksiKasCategory
  - [x] `honor_guru.dart` — HonorGuruModel, HonorGuruStatus, computeTotalHonor()
- [x] `lib/shared.dart` barrel export semua
- [ ] `lib/types.dart` — Permissions folded into `constants.dart` as `List<String>` (sudah memadai untuk Phase 2; revisit sebagai enum saat Phase 6 admin desktop)

### Supabase Client Package (`packages/supabase_client`)
- [x] `supabaseClientProvider` singleton + override pattern
- [x] `initSupabase()` — Supabase.initialize
- [x] `subscribeToTable()` — **Phase 2 fix**: `PostgresChangeFilter` parser (eq, neq, lt, lte, gt, gte, in)
- [x] `RealtimePayload` wrapper (eventType, newRecord, oldRecord, errors)
- [x] `authStateProvider` StreamProvider
- [x] `currentAdminUid(WidgetRef)` helper

### API Client Package (`packages/api_client`)
- [x] Dio + auth interceptor + 401 auto-logout
- [x] AuthStorage (flutter_secure_storage) — admin token + wali session
- [x] `authTokenProvider` FutureProvider
- [x] `currentUserProvider` FutureProvider (sealed AuthUser → AdminUser | WaliUser)
- [x] **Phase 2**: `query_providers.dart` — Riverpod FutureProviders per tabel:
  - [x] `kelasListProvider`, `mapelListProvider`, `tahunAjaranActiveProvider`, `semesterActiveProvider`, `jenisTagihanListProvider` (reference data)
  - [x] `santriListProvider`, `absensiRecentProvider.family<DateTime?>`, `nilaiRecentProvider.family<String?>` (mapel filter)
  - [x] `tagihanListProvider.family<String?>` (status filter), `paymentRecentProvider`
  - [x] `honorGuruListProvider.family<String?>` (status filter)
  - [x] `transaksiKasByPeriodProvider.family<({DateTime start, DateTime end})>`, `kasListProvider`
  - [x] `_realtimeRefreshTick` StateProvider + `setupKepalaRealtime()` + `invalidateAllQueries()`
- [ ] Serverpod-generated client (deferred ke Phase 3+)

### Backend (Serverpod)
- [x] Serverpod scaffold (sim_madin_server_server + sim_madin_server_client)
- [x] Serverpod internal migration (definition.sql)
- [ ] `serverpod.yaml` config (Supabase connection)
- [ ] Migrations dari Prisma schema (53 model)
- [ ] Endpoints: `AuthAdmin` (login email/pass)
- [ ] Endpoints: `AuthWali` (login WA+PIN, request OTP, verify OTP)
- [ ] Generated client code (saat ini hanya `Greeting`)

### Apps (5 skeleton)
- [x] `apps/admin_desktop` — Flutter desktop
- [x] `apps/mobile_wali` — Flutter mobile
- [x] `apps/mobile_guru` — Flutter mobile
- [x] `apps/mobile_bendahara` — Flutter mobile
- [x] `apps/mobile_kepala` — **Phase 2 fully implemented**

### CI/CD
- [x] `ci.yml` — analyze + format + test on push/PR
- [x] `build-mobile-apk.yml` — 4 APK matrix (wali/guru/bendahara/kepala)
- [x] `build-desktop.yml` — Windows/macOS/Linux binaries
- [ ] `backend-deploy.yml` — deploy Serverpod

---

## Phase 2 — mobile_kepala 🔄 (IN PROGRESS)

### Architecture decisions
- **Auth**: Supabase Auth langsung (login sudah jalan dari Phase 1).
- **Queries**: Supabase SDK langsung via Riverpod FutureProvider.
  Next.js API endpoints (yang dipakai TS app) tidak ada lagi di Flutter repo.
- **Realtime**: 4 tabel subs (Santri, Payment, Tagihan, HonorGuru) —
  bump `_realtimeRefreshTick` untuk auto-refresh semua providers.
- **Charts**: CustomPaint (line chart 7-day income trend).
  fl_chart dideklarasikan di pubspec untuk chart kompleks Phase 3+.
- **Navigation**: `StatefulShellRoute.indexedStack` go_router,
  5 bottom tabs (Beranda / Santri / Akademik / Keuangan / Profil).

### Screens (9 total)
- [x] Login (Phase 1, tetap dipakai)
- [x] Dashboard Home Tab — 6 KPI cards + tagihan distribution + income trend chart + absensi today + quick menu
- [x] Santri list (Tab 2) — search by name/NIS, tap for detail dialog
- [x] Absensi monitor — filter tanggal, summary 4 status, list
- [x] Nilai monitor — filter mapel, statistik rata-rata + % lulus KKM, list
- [x] Tagihan monitor — filter status, summary outstanding card, list
- [x] Pembayaran monitor — summary verified income card, list
- [x] Honor Guru monitor — filter status, summary total honor card, list dengan 5 komponen
- [x] Laporan Keuangan monitor — filter month, saldo kas + pemasukan vs pengeluaran, list transaksi
- [x] Profile screen (Tab 5) — user info + refresh + about + logout dengan konfirmasi

### Navigation
- [x] `StatefulShellRoute.indexedStack` dengan 5 branches
- [x] Nested routes di tab Akademik: `/dashboard/akademik/absensi|nilai|honor-guru`
- [x] Nested routes di tab Keuangan: `/dashboard/keuangan/tagihan|pembayaran|laporan`
- [x] BottomNavigationBar dengan Islamic green indicator

### Riverpod providers
- [x] AsyncValue pattern di semua monitor screens
- [x] FutureProvider.family untuk filter (tanggal, mapel, status)
- [x] `_realtimeRefreshTick` StateProvider global increment

### Realtime subscription
- [x] Fix `subscribeToTable` filter parser (`PostgresChangeFilter`)
- [x] `setupKepalaRealtime(ref)` — subscribe 4 tabel
- [x] Auto-refresh providers saat realtime event

### UI polish
- [x] Islamic green/gold theme konsisten
- [x] StatCard reusable widget
- [x] StatusChip reusable widget dengan helper per status type
- [x] EmptyState, ErrorView, LoadingSkeleton widgets
- [x] Pull-to-refresh di semua list screens

### Out of scope Phase 2 (akan di-phase 3+)
- [ ] Edit/create mutations (read-only di Phase 2)
- [ ] Filter by Tahun Ajaran / Semester (default: ambil yang isActive)
- [ ] PDF export (slip, kwitansi)
- [ ] Skeleton shimmer animation (saat ini: static grey blocks)
- [ ] Push notification (FCM)
- [ ] Offline cache (Hive / Isar)

### Verification
- [ ] `melos bootstrap` sukses (tidak ada conflict custom_lint)
- [ ] `dart analyze lib/` clean
- [ ] `flutter build apk --release` sukses di CI
- [ ] Manual test login → dashboard → semua 9 screens

---

## Phase 3 — mobile_bendahara (TODO, 3-4 minggu)

### Screens (8)
- [ ] Login (reuse dari Phase 1)
- [ ] Dashboard (statistik keuangan hari ini)
- [ ] Pembayaran list + detail + create + verify
- [ ] Tagihan list + generate tunggakan
- [ ] Kas list + transaksi CRUD
- [ ] Honor guru list + generate + slip PDF
- [ ] Laporan keuangan (chart + filter periode)
- [ ] Profile (reuse)

### Komponen kritis
- [ ] PDF generation (slip pembayaran, kwitansi)
- [ ] Bulk transaction dengan rollback
- [ ] Compute-on-read untuk auto-tagihan

---

## Phase 4 — mobile_guru (TODO, 3-4 minggu)

13 screens akademik CRUD + ujian management. Lihat ROADMAP.md.

---

## Phase 5 — mobile_wali (TODO, 4-6 minggu)

6 screens + WA+PIN auth + ujian online + anti-cheat. Lihat ROADMAP.md.

---

## Phase 6 — admin_desktop (TODO, 8-12 minggu)

34 views port dari React web. Lihat ROADMAP.md.

---

## Phase 7 — Production (TODO, 1-2 minggu)

- [ ] Migrate Supabase schema
- [ ] Backup data existing
- [ ] Deploy Serverpod production
- [ ] Setup domain + SSL
- [ ] Setup FCM
- [ ] User training
- [ ] Rollout bertahap (1 → 5 → 20 madrasah)

---

## How to update checklist

Setelah commit Phase 2, tandai item di atas dengan `[x]`. Kalau ada bug fix
yang spesifik per fase, tambahkan subsection "Bug fixes" di bawah fase masing-masing.

Untuk Phase 3+, pindahkan `[ ]` ke `[x]` saat mulai dikerjakan.
