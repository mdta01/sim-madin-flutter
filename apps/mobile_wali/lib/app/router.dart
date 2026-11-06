// ============================================================================
// SIM MADIN — mobile_wali Router (Phase 5)
// ============================================================================
// Struktur:
//   /splash          → SplashScreen (session check)
//   /login           → LoginScreen (WA + PIN)
//   /forgot-pin      → ForgotPinScreen (3-step OTP flow)
//   /dashboard/home  → DashboardHomeTab (list anak)
//   /dashboard/santri/:id → SantriDetailScreen (6 tabs)
//   /dashboard/chat    → ChatListScreen
//   /dashboard/chat/:roomId → ChatDetailScreen
//   /dashboard/profile → ProfileScreen
//   /dashboard/ujian/:ujianId/santri/:santriId → UjianTakeScreen (fullscreen)
//
// Bottom nav 3 tabs: Beranda / Chat / Profil
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:api_client/api_client.dart';

import '../features/chat/chat_detail_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/forgot_pin/forgot_pin_screen.dart';
import '../features/login/login_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/santri_detail/santri_detail_screen.dart';
import '../features/splash_screen.dart';
import '../features/ujian_take/ujian_take_screen.dart';

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
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/home',
        name: 'home',
        builder: (c, s) => const DashboardHomeTab(),
        routes: [
          GoRoute(
            path: 'santri/:id',
            name: 'santri-detail',
            builder: (c, s) =>
                SantriDetailScreen(santriId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'ujian/:ujianId/take',
                name: 'ujian-take',
                builder: (c, s) => UjianTakeScreen(
                  ujianId: s.pathParameters['ujianId']!,
                  santriId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ]),
    // Tab 2: Chat
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/chat',
        name: 'chat-list',
        builder: (c, s) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':roomId',
            name: 'chat-detail',
            builder: (c, s) =>
                ChatDetailScreen(roomId: s.pathParameters['roomId']!),
          ),
        ],
      ),
    ]),
    // Tab 3: Profil
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/profile',
        name: 'profile',
        builder: (c, s) => const ProfileScreen(),
      ),
    ]),
  ];

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
      GoRoute(
          path: '/forgot-pin',
          name: 'forgot-pin',
          builder: (c, s) => const ForgotPinScreen()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => DashboardShell(shell: shell),
        branches: branches,
      ),
    ],
  );
});

const kBottomNavItems = <_NavItem>[
  _NavItem(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home, location: '/dashboard/home'),
  _NavItem(label: 'Chat', icon: Icons.chat_outlined, activeIcon: Icons.chat, location: '/dashboard/chat'),
  _NavItem(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person, location: '/dashboard/profile'),
];

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.location});
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
}
