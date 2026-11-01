# SIM MADIN — Flutter Monorepo

> **Status**: 🚧 Active development — Phase 1 (Foundation)
> Migrasi dari proyek [sim-madin (TypeScript/Next.js/React Native)](https://github.com/mdta01/sim-madin)
> ke stack **Flutter (Dart) end-to-end**: 1 backend Serverpod + 5 frontend apps.

---

## 📦 Stack

| Layer | Tech | Keterangan |
|------|------|-----------|
| **Backend** | [Serverpod](https://serverpod.dev) + Dart | ORM built-in, generate client code, auth, realtime, file upload |
| **Database** | [Supabase](https://supabase.com) (Postgres) | Schema migrasi dari Prisma (48 tabel) |
| **Auth (admin/guru/bendahara/kepala)** | Serverpod Auth (email+password) | Single auth source, role-based access |
| **Auth (wali)** | WhatsApp + PIN (custom) | OTP rate-limited, bcrypt PIN, JWT |
| **Realtime** | Supabase Realtime (WebSocket) | Tabel: Notifikasi, Nilai, Absensi, Tagihan |
| **State management** | [Riverpod](https://riverpod.dev) 2.x | Code-generated providers |
| **Routing** | [go_router](https://pub.dev/packages/go_router) | Declarative, deep-linkable |
| **HTTP client** | [Dio](https://pub.dev/packages/dio) + Supabase SDK | Dio untuk Serverpod REST, Supabase untuk Realtime |
| **Serialization** | [Freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable) | Immutable models, copyWith, union types |
| **Storage** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | Token & session di Android Keystore / Keychain |
| **Monorepo** | [Melos](https://melos.invertase.dev) | Workspace, scripts, version sync |

## 📂 Struktur Monorepo

```
sim-madin-flutter/
├── apps/                          # Frontend apps
│   ├── admin_desktop/             # Desktop admin (Windows/macOS/Linux)
│   ├── mobile_wali/               # Wali Santri (Android/iOS)
│   ├── mobile_guru/               # Guru (Android/iOS)
│   ├── mobile_bendahara/          # Bendahara (Android/iOS)
│   └── mobile_kepala/             # Kepala Madrasah (Android/iOS)
│
├── packages/                      # Shared Dart packages
│   ├── shared/                    # Models, theme, constants, utils
│   ├── supabase_client/           # Supabase client wrapper (shared config)
│   └── api_client/                # Serverpod client wrapper + Riverpod providers
│
├── backend/
│   └── sim_madin_server/          # Serverpod server (Dart)
│
├── docs/                          # Documentation
├── melos.yaml                     # Melos workspace config
└── pubspec.yaml                   # Root workspace pubspec
```

## 🎯 Tujuan Migrasi

1. **Stack konsisten end-to-end (Dart)** — frontend & backend pakai bahasa yang sama, sharing models & types langsung tanpa codegen cross-language.
2. **Admin di desktop** — bukan web lagi. Flutter desktop (Windows/macOS/Linux) untuk admin madrasah yang lebih nyaman di laptop.
3. **Mobile apps lebih ringan** — Flutter lebih efficient dari React Native di Android 8 (no Hermes, no WebCrypto crash).
4. **Tetap pakai Supabase** sebagai database Postgres (supaya tidak perlu migrate data, hanya port schema).

## 🚧 Roadmap

### ✅ Phase 1 — Foundation (in progress)
- [x] Setup monorepo (Melos + pubspec workspace)
- [x] Struktur folder 5 apps + 3 packages + 1 backend
- [ ] `packages/shared` — port constants, theme, types, utils dari TS ke Dart
- [ ] `packages/supabase_client` — wrapper config (URL, anon key, schema, realtime)
- [ ] Backend Serverpod skeleton + auth (admin email/pass + wali WA+PIN)
- [ ] Skeleton 5 apps (login page + dashboard kosong)
- [ ] CI/CD: GitHub Actions build APK & desktop binaries

### 🚧 Phase 2 — Mobile apps MVP (paling sederhana dulu)
- [ ] `mobile_kepala` — login, dashboard, 7 monitor read-only (read paling simple)
- [ ] `mobile_bendahara` — login, keuangan CRUD (pembayaran, tagihan, kas, honor)
- [ ] `mobile_guru` — login, akademik CRUD (absensi, nilai, materi, tugas, pertemuan, ujian)

### 🚧 Phase 3 — Mobile paling kompleks
- [ ] `mobile_wali` — login WA+PIN, multi-anak dashboard, 6 tab per santri, ujian online (timer + Fisher-Yates shuffle + recovery)

### 🚧 Phase 4 — Desktop admin
- [ ] `admin_desktop` — port 34 views dari React ke Flutter Desktop (santri, wali, guru, kelas, absensi, nilai, tagihan, pembayaran, jadwal, pertemuan, rapor, ujian, bank-soal, tugas, materi, kompetensi, tahun-ajaran, siklus, kas, honor-guru, notifikasi, pengumuman, surat, perkembangan, alumni, audit-log, users, roles, permissions, settings, profile, dashboard, dashboard-kepala, chat, qr)

### 🚧 Phase 5 — Production readiness
- [ ] Migration script dari Prisma schema → Serverpod migrations
- [ ] Backup data existing (Supabase)
- [ ] Performance testing & optimization
- [ ] Deployment docs (self-hosted Serverpod + Vercel/Railway/Render)
- [ ] User training & rollout

**Estimasi total**: 24-35 minggu (6-9 bulan) — paralel execution per app.

## 🚀 Quick Start

### Prasyarat

- Flutter 3.27+ ([install](https://docs.flutter.dev/get-started/install))
- Dart 3.6+ (bundled dengan Flutter)
- [Melos](https://melos.invertase.dev) (`dart pub global activate melos`)
- [Serverpod CLI](https://docs.serverpod.dev) (`dart pub global activate serverpod_cli`)
- Supabase project (`ooglxextkliuhpequwme.supabase.co` — pakai existing)

### Setup

```bash
# Clone
git clone https://github.com/mdta01/sim-madin-flutter.git
cd sim-madin-flutter

# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Generate code (freezed, json, riverpod)
melos run gen

# Run backend (development mode)
cd backend/sim_madin_server
dart main.dart --apply-migrations

# Run app (mobile_wali sebagai contoh)
cd apps/mobile_wali
flutter run
```

### Build

```bash
# Build APK
melos run build:apk:wali

# Build Windows desktop
melos run build:windows

# Build macOS desktop
melos run build:macos

# Build Linux desktop
melos run build:linux
```

## 🔗 Sumber Asli

- Repo lama: https://github.com/mdta01/sim-madin (TypeScript/Next.js/React Native)
- Analisis migrasi: lihat `docs/MIGRATION-ANALYSIS.md` (1.128 baris, 81 KB — schema, 34 view, 136 API endpoint, 4 mobile apps screen-by-screen)
- Web admin existing (production): https://sim-madin.vercel.app

## 📋 Lisensi

Private project untuk Madrasah Diniyah Terpadu.
