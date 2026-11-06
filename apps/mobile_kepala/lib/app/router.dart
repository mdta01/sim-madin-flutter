// ============================================================================
// SIM MADIN — mobile_kepala Router (Phase 2)
// ============================================================================
// Struktur:
//   /splash       → SplashScreen (session check)
//   /login        → LoginScreen
//   /dashboard    → DashboardScreen (bottom tab shell)
//     ├── Beranda (/dashboard/home)
//     ├── Santri   (/dashboard/santri)
//     ├── Akademik (/dashboard/akademik)
//     ├── Keuangan (/dashboard/keuangan)
//     └── Profil   (/dashboard/profile)
//
//   Nested routes (di bawah tab Akademik/Keuangan) untuk monitor screens:
//     /dashboard/akademik/absensi
//     /dashboard/akademik/nilai
//     /dashboard/akademik/honor-guru
//     /dashboard/keuangan/tagihan
//     /dashboard/keuangan/pembayaran
//     /dashboard/keuangan/laporan
//
// Bottom tab pakai StatefulNavigationShell dari go_router.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import '../features/absensi/absensi_monitor_screen.dart';
import '../features/akademik_hub/akademik_hub_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/honor_guru/honor_guru_monitor_screen.dart';
import '../features/keuangan_hub/keuangan_hub_screen.dart';
import '../features/laporan_keuangan/laporan_keuangan_monitor_screen.dart';
import '../features/login/login_screen.dart';
import '../features/nilai/nilai_monitor_screen.dart';
import '../features/pembayaran/pembayaran_monitor_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/santri/santri_list_screen.dart';
import '../features/splash_screen.dart';
import '../features/tagihan/tagihan_monitor_screen.dart';

/// Wrapper agar DashboardScreen bisa pakai StatefulNavigationShell child.
/// DashboardScreen adalah ShellRoute — body-nya ganti per tab.
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(shell: shell);
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Navigation branch untuk bottom tab — 5 cabang.
  final branches = <StatefulShellBranch>[
    // Tab 1: Beranda
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/home',
          name: 'home',
          builder: (context, state) => const DashboardHomeTab(),
        ),
      ],
    ),
    // Tab 2: Santri
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/santri',
          name: 'santri-list',
          builder: (context, state) => const SantriListScreen(),
        ),
      ],
    ),
    // Tab 3: Akademik (hub + nested monitor screens)
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/akademik',
          name: 'akademik-hub',
          builder: (context, state) => const AkademikHubScreen(),
          routes: [
            GoRoute(
              path: 'absensi',
              name: 'absensi-monitor',
              builder: (context, state) => const AbsensiMonitorScreen(),
            ),
            GoRoute(
              path: 'nilai',
              name: 'nilai-monitor',
              builder: (context, state) => const NilaiMonitorScreen(),
            ),
            GoRoute(
              path: 'honor-guru',
              name: 'honor-guru-monitor',
              builder: (context, state) => const HonorGuruMonitorScreen(),
            ),
          ],
        ),
      ],
    ),
    // Tab 4: Keuangan (hub + nested monitor screens)
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/keuangan',
          name: 'keuangan-hub',
          builder: (context, state) => const KeuanganHubScreen(),
          routes: [
            GoRoute(
              path: 'tagihan',
              name: 'tagihan-monitor',
              builder: (context, state) => const TagihanMonitorScreen(),
            ),
            GoRoute(
              path: 'pembayaran',
              name: 'pembayaran-monitor',
              builder: (context, state) => const PembayaranMonitorScreen(),
            ),
            GoRoute(
              path: 'laporan',
              name: 'laporan-keuangan-monitor',
              builder: (context, state) =>
                  const LaporanKeuanganMonitorScreen(),
            ),
          ],
        ),
      ],
    ),
    // Tab 5: Profil
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ];

  return GoRouter(
    initialLocation: '/splash',

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => DashboardShell(shell: shell),
        branches: branches,
      ),
    ],
  );
});

/// List konfigurasi bottom tab — dipakai DashboardScreen untuk render
/// BottomNavigationBar. Index sesuai urutan branches di atas.
const kBottomNavItems = <_NavItem>[
  _NavItem(
    label: 'Beranda',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    location: '/dashboard/home',
  ),
  _NavItem(
    label: 'Santri',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    location: '/dashboard/santri',
  ),
  _NavItem(
    label: 'Akademik',
    icon: Icons.school_outlined,
    activeIcon: Icons.school,
    location: '/dashboard/akademik',
  ),
  _NavItem(
    label: 'Keuangan',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    location: '/dashboard/keuangan',
  ),
  _NavItem(
    label: 'Profil',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    location: '/dashboard/profile',
  ),
];

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
}

/// Warna utama bottom nav — dipakai DashboardScreen + tab hub screens.
Color get kNavActiveColor => AppColors.primary;
Color get kNavInactiveColor => AppColors.textMuted;
