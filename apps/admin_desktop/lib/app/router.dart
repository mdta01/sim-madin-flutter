// ============================================================================
// SIM MADIN — admin_desktop Router (Phase 6a)
// ============================================================================
// Desktop pattern: sidebar navigation (bukan bottom tab).
// Phase 6a active routes:
//   /login
//   /dashboard
//   /users
//   /roles
//   /permissions
//   /settings
//
// Phase 6b+ (TODO, placeholder):
//   /santri, /wali, /guru, /kelas, /mapel, /jadwal, /pertemuan,
//   /absensi, /nilai, /tahun-ajaran, /siklus, /tagihan, /pembayaran,
//   /kas, /honor-guru, /tugas, /materi, /ujian, /bank-soal, /rapor,
//   /kompetensi, /pengumuman, /notifikasi, /surat, /perkembangan,
//   /alumni, /chat, /qr, /audit-log
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/guru/guru_screen.dart';
import '../features/jadwal/jadwal_screen.dart';
import '../features/kelas/kelas_screen.dart';
import '../features/login/login_screen.dart';
import '../features/mapel/mapel_screen.dart';
import '../features/permissions/permissions_screen.dart';
import '../features/pertemuan/pertemuan_screen.dart';
import '../features/absensi/absensi_screen.dart';
import '../features/nilai/nilai_screen.dart';
import '../features/materi_admin/materi_screen.dart';
import '../features/tugas_admin/tugas_screen.dart';
import '../features/ujian_admin/ujian_screen.dart';
import '../features/bank_soal/bank_soal_screen.dart';
import '../features/kompetensi/kompetensi_screen.dart';
import '../features/rapor/rapor_screen.dart';
import '../features/perkembangan_admin/perkembangan_screen.dart';
import '../features/roles/roles_screen.dart';
import '../features/santri/santri_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash_screen.dart';
import '../features/tahun_ajaran/tahun_ajaran_screen.dart';
import '../features/users/users_screen.dart';
import '../features/wali/wali_screen.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (c, s) => const SplashScreen()),
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (c, s) => const LoginScreen()),
      ShellRoute(
        builder: (c, s, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (c, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            builder: (c, s) => const UsersScreen(),
          ),
          GoRoute(
            path: '/roles',
            name: 'roles',
            builder: (c, s) => const RolesScreen(),
          ),
          GoRoute(
            path: '/permissions',
            name: 'permissions',
            builder: (c, s) => const PermissionsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (c, s) => const SettingsScreen(),
          ),
          // Phase 6b — master data routes
          GoRoute(path: '/santri', name: 'santri', builder: (c, s) => const SantriScreen()),
          GoRoute(path: '/guru', name: 'guru', builder: (c, s) => const GuruScreen()),
          GoRoute(path: '/wali', name: 'wali', builder: (c, s) => const WaliScreen()),
          GoRoute(path: '/kelas', name: 'kelas', builder: (c, s) => const KelasScreen()),
          GoRoute(path: '/mapel', name: 'mapel', builder: (c, s) => const MapelScreen()),
          GoRoute(path: '/tahun-ajaran', name: 'tahun-ajaran', builder: (c, s) => const TahunAjaranScreen()),
          // Phase 6c — akademik routes
          GoRoute(path: '/jadwal', name: 'jadwal', builder: (c, s) => const JadwalScreen()),
          GoRoute(path: '/pertemuan', name: 'pertemuan', builder: (c, s) => const PertemuanScreen()),
          GoRoute(path: '/absensi', name: 'absensi', builder: (c, s) => const AbsensiScreen()),
          GoRoute(path: '/nilai', name: 'nilai', builder: (c, s) => const NilaiScreen()),
          GoRoute(path: '/materi', name: 'materi', builder: (c, s) => const MateriScreen()),
          GoRoute(path: '/tugas', name: 'tugas', builder: (c, s) => const TugasScreen()),
          GoRoute(path: '/ujian', name: 'ujian', builder: (c, s) => const UjianScreen()),
          GoRoute(path: '/bank-soal', name: 'bank-soal', builder: (c, s) => const BankSoalScreen()),
          GoRoute(path: '/kompetensi', name: 'kompetensi', builder: (c, s) => const KompetensiScreen()),
          GoRoute(path: '/rapor', name: 'rapor', builder: (c, s) => const RaporScreen()),
          GoRoute(path: '/perkembangan', name: 'perkembangan', builder: (c, s) => const PerkembanganScreen()),
          // Phase 6d+ placeholder routes
          ...kPhase6dRoutes.map((path) => GoRoute(path: path, name: path.replaceAll('/', ''), builder: (c, s) => const _ComingSoonScreen())),
        ],
      ),
    ],
  );
});

/// Routes untuk Phase 6d+ (belum diimplement — tampilkan placeholder).
const kPhase6dRoutes = <String>[
  '/siklus',
  '/tagihan',
  '/pembayaran',
  '/kas',
  '/honor-guru',
  '/pengumuman',
  '/notifikasi',
  '/surat',
  '/alumni',
  '/chat',
  '/qr',
  '/audit-log',
];

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Modul ${location.replaceAll('/', '')} — Phase 6b+',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Halaman ini akan diimplementasikan di Phase 6b/c/d.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
