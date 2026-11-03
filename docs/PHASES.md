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

## Phase 3 — mobile_bendahara ✅ (DONE)

### Architecture decisions
- **Auth**: Supabase Auth (Phase 1 still works).
- **Queries**: reuses Phase 2 `query_providers.dart` (payment, tagihan, kas,
  honorGuru, transaksiKas providers).
- **Mutations**: new `mutation_providers.dart` — pure functions wrapping
  Supabase insert/update + invalidate dependent read providers.
- **PDF generation**: LOCAL on-device via `pdf` + `printing` packages
  (offline-capable, more reliable than TS app's network URL approach).
- **Kas balance update**: client-side read-modify-write with race-condition
  note. Phase 6+ should use Postgres function with SELECT FOR UPDATE.
- **Bottom nav**: 5 tabs (Beranda/Pembayaran/Tagihan/Kas/Profil) +
  nested routes for create/detail/transaksi/laporan/honor-guru.
- **Tagihan generate**: out of scope (admin desktop Phase 6 generates).
- **Honor Guru generate**: bulk function provided for future use, but
  mobile_bendahara only views/approves/pays existing honor records.

### Foundation (packages/api_client/lib/mutation_providers.dart)
- `tagihanBySantriProvider.family<String>` — for pembayaran form
- `createPembayaran()` — insert + invalidate 3 read providers
- `verifyPembayaran(id, kasId?)` — PENDING→VERIFIED
- `rejectPembayaran(id)` — PENDING→REJECTED
- `createTransaksiKas()` — insert + update kas balance (delta ±amount)
- `updateHonorGuruStatus(id, newStatus, {kasId})` — change status; if
  DIBAYARKAN, deduct from kas balance
- `laporanKeuanganProvider.family<({int month, int year})>` —
  compute-on-read aggregate (pemasukan/pengeluaran/per-kategori/list)
- `generateHonorGuruBulk()` — bulk insert (for future admin use)
- `paymentByIdProvider.family<String>` — single fetch with joins
- `_realtimeRefreshTick` renamed to public `realtimeRefreshTick` so
  mutation_providers.dart can access it.

### PDF Service (apps/mobile_bendahara/lib/services/pdf_service.dart)
- `shareKwitansiPembayaran(payment)` — A5 portrait, Islamic green header,
  amount box, status chip, signature footer.
- `shareSlipHonorGuru(honor)` — A4 portrait, header info box, honor
  breakdown table, total box, optional catatan.
- `shareLaporanKeuangan(laporan)` — A4 multi-page, 3 summary boxes,
  per-kategori tables, detail transaksi table.
- Uses `PdfColor.fromInt(0xFF0D7A4F)` Islamic green theme.
- `pw.StatelessWidget` pattern for reusable header/info/table helpers.

### Shared widgets (apps/mobile_bendahara/lib/widgets/)
- `feedback_widgets.dart` — EmptyState, ErrorView, LoadingSkeleton,
  StatCard, StatusChip + status helper functions.
- `amount_input.dart` — AmountInput with Rp prefix, auto-separator
  ribuan, digits-only input.
- `confirm_dialog.dart` — showConfirmDialog() with destructive option.

### Screens (apps/mobile_bendahara/lib/features/)
1. ✅ Login (Phase 1, redirect to /dashboard/home)
2. ✅ Dashboard Home Tab — 4 KPI (Pemasukan Hari Ini, Tunggakan, Perlu
   Verifikasi, Saldo Kas) + quick menu grid + recent payments list
3. ✅ Pembayaran list (Tab 2) — filter by status, status chip, + button
4. ✅ Pembayaran create — 5-step form (santri → tagihan optional →
   nominal → metode → catatan) + offer cetak kwitansi PDF after submit
5. ✅ Pembayaran detail — full info + actions (Verify with kas picker,
   Reject with confirm, Cetak Kwitansi PDF)
6. ✅ Tagihan list (Tab 3) — filter pills (Semua/Belum/Cicil/Lunas),
   summary card, 4-cell breakdown per card
7. ✅ Kas list (Tab 4) — total saldo + per-kas card
8. ✅ Transaksi Kas — stats row + saldo periode + list + bottom sheet
   form (type toggle, kas picker, AmountInput, description)
9. ✅ Honor Guru — filter status, 4-komponen breakdown + total,
   actions (Setujui/Bayar with kas picker/Cetak Slip PDF)
10. ✅ Laporan Keuangan — month filter, saldo summary, bar comparison,
    per-kategori breakdown, detail transaksi list, export PDF
11. ✅ Profile (Tab 5) — user info, refresh, about, logout with confirm,
    realtime status

### Verification
- [x] CI analyze success
- [x] Build Mobile APK — mobile_bendahara success (commit caf739f)
- [x] Build Mobile APK — all 4 mobile apps success
- [ ] Manual test login → dashboard → all 10 screens
- [ ] Test PDF generation (kwitansi, slip honor, laporan)

### Bug fixes applied during Phase 3
- caf739f: 4 compile fixes:
  1. `_realtimeRefreshTick` private → `realtimeRefreshTick` public
     (mutation_providers.dart couldn't access it).
  2. dashboard_screen.dart: missing import for widgets/feedback_widgets.dart.
  3. Icons.cash (deprecated) → Icons.payments.
  4. `pw.FontWeight.w500` (not supported in pdf package) →
     `pw.FontWeight.normal`.

### Out of scope Phase 3 (Phase 6+ admin desktop)
- [ ] Generate tagihan bulk (compute-on-read auto-tagihan)
- [ ] Generate honor guru bulk (function exists, no UI yet)
- [ ] CRUD Kas (create/edit/delete kas) — currently read-only

---

## Phase 4 — mobile_guru ✅ (DONE)

### Architecture decisions
- Reuse Phase 1-3 patterns (Supabase Auth, query/mutation providers pattern,
  feedback_widgets, StatefulShellRoute).
- Realtime auto-refresh via realtimeRefreshTick for Jadwal/Materi/Tugas/
  Pertemuan/Ujian/Perkembangan/Chat tables.
- Bottom nav: 5 tabs (Beranda/Santri/Akademik/Ujian/Profil) + nested
  routes for all akademik + ujian screens.
- Akademik + Ujian hubs: grid menus to keep main bottom nav simple.
- Bulk input pattern (Absensi + Nilai): upsert with onConflict constraint
  so re-submit on same date/kelas updates instead of duplicating.
- Chat: simple realtime-ish refresh via realtimeRefreshTick (proper
  Supabase Realtime subscription can be added later if needed).
- Ujian: create + list + detail with 3 tabs (Info/Soal/Peserta) +
  publish button. Bank soal management + peserta assignment deferred to
  Phase 6 admin desktop (helper functions addUjianSoal +
  addUjianPesertaBulk exist in mutation_providers_guru.dart).

### Foundation
- 7 new model files (jadwal, materi, tugas, pertemuan, ujian,
  perkembangan, komunikasi) with denormalized relation fields.
- query_providers_guru.dart — 16 FutureProvider + family for guru data:
  jadwalGuruProvider, jadwalHariIniProvider, santriByKelasProvider,
  absensiByKelasDateProvider, materiGuruProvider, tugasGuruProvider,
  pengumpulanByTugasProvider, pertemuanGuruProvider, ujianGuruProvider,
  ujianByIdProvider, ujianSoalByUjianProvider, ujianPesertaByUjianProvider,
  ujianNilaiByUjianProvider, bankSoalGuruProvider, perkembanganQuranProvider,
  hafalanKitabProvider, akhlakPenilaianProvider, pembinaanProvider,
  pengumumanListProvider, chatRoomsGuruProvider, chatMessagesProvider,
  guruStatsProvider + invalidateGuruQueries() helper.
- mutation_providers_guru.dart — 14 mutation functions:
  bulkCreateAbsensi, bulkCreateNilai, createMateri, deleteMateri,
  createTugas, deleteTugas, gradePengumpulanTugas, createPertemuan,
  completePertemuan, createUjian, publishUjian, createBankSoal,
  addUjianSoal, addUjianPesertaBulk, createPerkembanganQuran,
  createHafalanKitab, createAkhlakPenilaian, createPembinaan,
  createChatRoom, sendChatMessage.

### Screens (13 total)
1. ✅ Login (Phase 1, redirect to /dashboard/home)
2. ✅ Dashboard Home Tab — 4 KPI (Jadwal/Pertemuan/Materi/Tugas) + 10
   quick menu + jadwal hari ini list
3. ✅ Santri list (Tab 2) — filter by kelas + search
4. ✅ Absensi input — bulk per kelas + tanggal, popup menu status
5. ✅ Nilai input — bulk per kelas + mapel + type, ScoreInput with
   passing/failing color
6. ✅ Materi list + create (title, desc, mapel, kelas, type, URL,
   pertemuan, publish toggle)
7. ✅ Tugas list + detail (list pengumpulan + grade per santri)
8. ✅ Pertemuan list + create from jadwal (auto-increment pertemuanKe)
9. ✅ Ujian list + create + detail (3 tabs: Info/Soal/Peserta) + publish
10. ✅ Perkembangan santri — 4 tabs (Quran/Kitab/Akhlak/Pembinaan)
11. ✅ Chat list + chat detail (message bubbles, send)
12. ✅ Jadwal list grouped by day
13. ✅ Pengumuman list (read-only) with priority badges
+ Profile (Tab 5) — user info, refresh, about, logout with confirm,
  realtime status info

### Bug fixes applied during Phase 4
- bbde45f: 5 compile fixes (UjianStatus/SoalType duplicate, ref.listen
  nullable, StatCard import, FormField clash with Flutter built-in,
  nilai_input_screen syntax error).
- a77786d: 4 more fixes (ujian.dart orphan braces, UjianStatus.label
  missing, Flexible builder param wrong, family providers invalidated
  without arg).
- b0e26d4: import fix — removed `show` clauses in mutation_providers_guru
  that hid all guru query providers from ref.invalidate calls.

### Verification
- [x] CI analyze success
- [x] Build Mobile APK — mobile_guru success (commit b0e26d4)
- [x] Build Mobile APK — all 4 mobile apps success
- [ ] Manual test login + all 13 screens
- [ ] Test bulk input absensi/nilai (with kelas/mapel selectors)
- [ ] Test materi create + ujian create + chat send

### Out of scope Phase 4 (Phase 6+ admin desktop)
- [ ] Bank Soal management UI (function exists, no UI)
- [ ] UjianPeserta bulk assign UI (function exists, no UI)
- [ ] File upload for materi/tugas (file_picker dep declared but UI
  not implemented; current implementation uses URL eksternal)
- [ ] Ujian online take screen for santri (Phase 5 mobile_wali territory)

---

## Phase 5 — mobile_wali ✅ (DONE)

### Architecture decisions
- Auth: WA+PIN custom (bukan Supabase Auth). Pakai secure storage untuk
  persistence + pseudo-token (Phase 5 dev — production butuh JWT proper).
- OTP: di-generate random 6 digit, disimpan di Wali.otpCode + otpExpiresAt
  (5 menit). Dev mode: return OTP ke client supaya bisa test tanpa WA
  gateway. Production: kirim via Fonnte/Twilio WA Business API.
- PIN verification: Phase 5 plain text compare (DEV). Production: bcrypt
  server-side via Postgres RPC function.
- Auto-lock: 5x salah PIN → lock 15 menit (lockedUntil).
- Blacklist: 50 PIN lemah (000000, 111111, 123456, dll) tidak bisa dipakai.
- Bottom nav 3 tabs: Beranda / Chat / Profil.
- Santri Detail: 6 tabs (Profil, Akademik, Ujian, Keuangan, Notif, Info).
- Ujian Take: Fisher-Yates shuffle soal order (persist per santri via
  UjianSesi.soalOrder), recovery (resume sesi yang belum finished),
  anti-cheat (WidgetsBindingObserver detect app background → 3x
  violation auto-submit), timer countdown, soal navigator.
- Realtime auto-refresh via realtimeRefreshTick untuk Notifikasi, Chat,
  Tagihan, Payment tables.

### Foundation
- WaliModel (komunikasi.dart) ditambah 9 auth fields: pinHash, otpCode,
  otpExpiresAt, otpAttempts, otpRequestCount, otpRequestResetAt,
  failedLoginAttempts, lockedUntil, lastLoginAt.
- query_providers_wali.dart — 12 FutureProvider + family + invalidateWaliQueries.
- mutation_providers_wali.dart — 8 mutation functions:
  loginWali, requestOtp (rate-limited 5/jam), verifyOtp (max 5 attempts),
  setNewPin (validate blacklist), markNotifikasiRead,
  sendChatMessageAsWali, startUjianSesi (resume + Fisher-Yates shuffle),
  submitUjianJawaban (auto-correct PG + compute score 0-100).
- api_client.dart: tambah getWaliToken/getWaliData/getWaliSantriList
  methods (skip JWT verify untuk Phase 5 dev).

### Shared widgets
- feedback_widgets.dart — EmptyState, ErrorView, LoadingSkeleton, StatusChip.
- anti_cheat_mixin.dart — AntiCheatMixin untuk WidgetsBindingObserver.
  Tracks violation count, calls onWarning (1st & 2nd violation) +
  onCheatDetected (3rd violation auto-submit).

### Screens (8 total)
1. Login (WA + PIN) — phone + PIN 6-digit input, show/hide PIN, demo info.
2. Forgot PIN — 3-step flow (request OTP → verify OTP → set new PIN).
   Dev mode: tampilkan OTP langsung ke user supaya bisa test tanpa WA.
3. Dashboard Home (Tab 1) — quick stats + list anak dengan avatar, NIS,
   kelas badge, status badge.
4. Santri Detail — header card + 6 tabs:
   - Profil: detail info santri (nama, NIS, TTL, alamat, wali, dll)
   - Akademik: absensi summary (4 status counts) + nilai recent (10)
   - Ujian: list ujian yang diikuti anak
   - Keuangan: total tunggakan + tagihan (5 recent) + payment history (10)
   - Notif: notifikasi wali (mark as read on tap)
   - Info: pengumuman (audience ALL atau WALI) dengan priority badges
5. Ujian Take — full feature:
   - Timer countdown (auto-submit on time-up)
   - Fisher-Yates shuffle soal order (persist via UjianSesi.soalOrder)
   - Recovery: kalau ada sesi yang belum finished, resume + restore answers
   - Anti-cheat: 3x app background → auto-submit
   - PopScope: confirm exit (progres jawaban tetap tersimpan)
   - Soal navigator grid (jump to specific soal, indicator answered/current)
   - Support 3 tipe soal: PG, ISIAN, ESSAY, PRAKTIK
   - Result screen: score 0-100 + lulus/tidak (KKM 70)
6. Chat list — list chat rooms dengan guru.
7. Chat detail — message bubbles + send.
8. Profile (Tab 3) — info wali + refresh + about + ubah PIN + logout.

### Bug fixes applied during Phase 5
- 1e02924: 4 compile fixes (authStorageProvider undefined via show clause,
  normalizeWhatsApp nullable return, num vs double type mismatch).
- 68921aa: import api_client.dart for authStorageProvider (Dart handles
  circular imports for top-level declarations gracefully).

### Verification
- [x] CI analyze success
- [x] Build Mobile APK — mobile_wali success (commit 68921aa)
- [x] Build Mobile APK — all 4 mobile apps success
- [ ] Manual test login WA+PIN (need to seed Wali record with PIN first)
- [ ] Test OTP flow (request → verify → set new PIN)
- [ ] Test ujian take (need ujian + soal + peserta data di DB)
- [ ] Test anti-cheat (background app 3x during ujian)

### Out of scope Phase 5 (Phase 7 production)
- [ ] WA OTP send via Fonnte/Twilio (Phase 5 dev returns OTP to client)
- [ ] bcrypt PIN verify server-side via Postgres RPC function
- [ ] JWT proper dengan HS256 signature (Phase 5 pakai pseudo-token)
- [ ] Realtime subscription untuk Notifikasi + Chat (Phase 5 pakai polling
  via realtimeRefreshTick — 21 subscriptions per wali belum di-setup)
- [ ] RLS workaround: wali login pakai custom auth (bukan Supabase Auth)
  jadi auth.uid() null → RLS policies wali_read return 0 rows. Perlu
  setup: link Wali.userId ke Supabase Auth user (admin desktop Phase 6
  bisa handle), atau pakai service_role untuk wali queries (not recommended).

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
