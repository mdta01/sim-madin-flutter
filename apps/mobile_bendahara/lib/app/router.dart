// ============================================================================
// SIM MADIN — mobile_bendahara Router (Phase 3)
// ============================================================================
// Struktur:
//   /splash       → SplashScreen (session check)
//   /login        → LoginScreen
//   /dashboard    → DashboardScreen (bottom tab shell)
//     ├── Beranda   (/dashboard/home)
//     ├── Pembayaran (/dashboard/pembayaran) + nested: create, detail
//     ├── Tagihan   (/dashboard/tagihan)
//     ├── Kas       (/dashboard/kas) + nested: transaksi
//     └── Profil    (/dashboard/profile)
//
// Nested routes:
//   /dashboard/pembayaran/create  → form input pembayaran baru
//   /dashboard/pembayaran/:id     → detail pembayaran + verify/reject/cetak
//   /dashboard/kas/transaksi      → list + form transaksi kas
//   /dashboard/laporan            → laporan keuangan (akses dari home tab)
//   /dashboard/honor-guru        → honor guru (akses dari home tab)
//
// Bottom tab pakai StatefulNavigationShell dari go_router.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/honor_guru/honor_guru_screen.dart';
import '../features/kas/kas_list_screen.dart';
import '../features/kas/transaksi_kas_screen.dart';
import '../features/laporan_keuangan/laporan_keuangan_screen.dart';
import '../features/login/login_screen.dart';
import '../features/pembayaran/pembayaran_create_screen.dart';
import '../features/pembayaran/pembayaran_detail_screen.dart';
import '../features/pembayaran/pembayaran_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash_screen.dart';
import '../features/tagihan/tagihan_list_screen.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(shell: shell);
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final branches = <StatefulShellBranch>[
    // Tab 1: Beranda
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/home',
          name: 'home',
          builder: (context, state) => const DashboardHomeTab(),
          routes: [
            GoRoute(
              path: 'laporan',
              name: 'laporan-keuangan',
              builder: (context, state) =>
                  const LaporanKeuanganScreen(),
            ),
            GoRoute(
              path: 'honor-guru',
              name: 'honor-guru',
              builder: (context, state) => const HonorGuruScreen(),
            ),
          ],
        ),
      ],
    ),
    // Tab 2: Pembayaran
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/pembayaran',
          name: 'pembayaran-list',
          builder: (context, state) => const PembayaranListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'pembayaran-create',
              builder: (context, state) => const PembayaranCreateScreen(),
            ),
            GoRoute(
              path: ':id',
              name: 'pembayaran-detail',
              builder: (context, state) => PembayaranDetailScreen(
                paymentId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    ),
    // Tab 3: Tagihan
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/tagihan',
          name: 'tagihan-list',
          builder: (context, state) => const TagihanListScreen(),
        ),
      ],
    ),
    // Tab 4: Kas
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/dashboard/kas',
          name: 'kas-list',
          builder: (context, state) => const KasListScreen(),
          routes: [
            GoRoute(
              path: 'transaksi',
              name: 'transaksi-kas',
              builder: (context, state) => const TransaksiKasScreen(),
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

    redirect: (context, state) {
      final isLoggedIn = ref.read(supabaseClientProvider).auth.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-pin';
      final isProtectedRoute = state.matchedLocation.startsWith('/dashboard') ||
          state.matchedLocation.startsWith('/admin');

      // Not logged in + trying to access protected route → redirect to /login
      if (!isLoggedIn && isProtectedRoute) {
        return '/login';
      }
      // Logged in + trying to access /login → redirect to /dashboard/home (or /admin)
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/dashboard/home';
      }
      // All other cases — no redirect
      return null;
    },
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

const kBottomNavItems = <_NavItem>[
  _NavItem(
    label: 'Beranda',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    location: '/dashboard/home',
  ),
  _NavItem(
    label: 'Pembayaran',
    icon: Icons.payment_outlined,
    activeIcon: Icons.payment,
    location: '/dashboard/pembayaran',
  ),
  _NavItem(
    label: 'Tagihan',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    location: '/dashboard/tagihan',
  ),
  _NavItem(
    label: 'Kas',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    location: '/dashboard/kas',
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

Color get kNavActiveColor => AppColors.primary;
Color get kNavInactiveColor => AppColors.textMuted;
