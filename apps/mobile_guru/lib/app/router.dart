// ============================================================================
// SIM MADIN — mobile_guru Router (Phase 4)
// ============================================================================
// 5 bottom tabs:
//   Beranda (/dashboard/home) → Dashboard + quick menu
//   Santri (/dashboard/santri) → list santri per kelas
//   Akademik (/dashboard/akademik) → hub: absensi, nilai, materi, tugas, pertemuan
//   Ujian (/dashboard/ujian) → hub: ujian, bank soal
//   Profil (/dashboard/profile)
//
// Nested routes:
//   /dashboard/akademik/absensi
//   /dashboard/akademik/absensi/create
//   /dashboard/akademik/nilai
//   /dashboard/akademik/materi
//   /dashboard/akademik/materi/create
//   /dashboard/akademik/tugas
//   /dashboard/akademik/tugas/:id (detail + pengumpulan + grade)
//   /dashboard/akademik/pertemuan
//   /dashboard/akademik/perkembangan
//   /dashboard/akademik/perkembangan/create
//   /dashboard/akademik/jadwal
//   /dashboard/akademik/pengumuman
//   /dashboard/akademik/chat
//   /dashboard/akademik/chat/:roomId
//   /dashboard/ujian/list
//   /dashboard/ujian/:id (detail + soal + peserta + nilai)
//   /dashboard/ujian/create
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/absensi/absensi_input_screen.dart';
import '../features/akademik_hub/akademik_hub_screen.dart';
import '../features/chat/chat_detail_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/jadwal/jadwal_list_screen.dart';
import '../features/login/login_screen.dart';
import '../features/materi/materi_create_screen.dart';
import '../features/materi/materi_list_screen.dart';
import '../features/nilai/nilai_input_screen.dart';
import '../features/pengumuman/pengumuman_list_screen.dart';
import '../features/perkembangan/perkembangan_screen.dart';
import '../features/pertemuan/pertemuan_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/santri/santri_list_screen.dart';
import '../features/splash_screen.dart';
import '../features/tugas/tugas_create_screen.dart';
import '../features/tugas/tugas_detail_screen.dart';
import '../features/tugas/tugas_list_screen.dart';
import '../features/ujian/bank_soal_create_screen.dart';
import '../features/ujian/bank_soal_list_screen.dart';
import '../features/ujian/ujian_create_screen.dart';
import '../features/ujian/ujian_detail_screen.dart';
import '../features/ujian/ujian_list_screen.dart';
import '../features/ujian_hub/ujian_hub_screen.dart';

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
      ),
    ]),
    // Tab 2: Santri
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/santri',
        name: 'santri-list',
        builder: (c, s) => const SantriListScreen(),
      ),
    ]),
    // Tab 3: Akademik hub + nested
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/akademik',
        name: 'akademik-hub',
        builder: (c, s) => const AkademikHubScreen(),
        routes: [
          GoRoute(
            path: 'absensi',
            name: 'absensi-input',
            builder: (c, s) => const AbsensiInputScreen(),
          ),
          GoRoute(
            path: 'nilai',
            name: 'nilai-input',
            builder: (c, s) => const NilaiInputScreen(),
          ),
          GoRoute(
            path: 'materi',
            name: 'materi-list',
            builder: (c, s) => const MateriListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'materi-create',
                builder: (c, s) => const MateriCreateScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'tugas',
            name: 'tugas-list',
            builder: (c, s) => const TugasListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'tugas-create',
                builder: (c, s) => const TugasCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'tugas-detail',
                builder: (c, s) =>
                    TugasDetailScreen(tugasId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'pertemuan',
            name: 'pertemuan-list',
            builder: (c, s) => const PertemuanListScreen(),
          ),
          GoRoute(
            path: 'perkembangan',
            name: 'perkembangan',
            builder: (c, s) => const PerkembanganScreen(),
          ),
          GoRoute(
            path: 'jadwal',
            name: 'jadwal-list',
            builder: (c, s) => const JadwalListScreen(),
          ),
          GoRoute(
            path: 'pengumuman',
            name: 'pengumuman-list',
            builder: (c, s) => const PengumumanListScreen(),
          ),
          GoRoute(
            path: 'chat',
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
        ],
      ),
    ]),
    // Tab 4: Ujian hub + nested
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard/ujian',
        name: 'ujian-hub',
        builder: (c, s) => const UjianHubScreen(),
        routes: [
          GoRoute(
            path: 'list',
            name: 'ujian-list',
            builder: (c, s) => const UjianListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'ujian-create',
                builder: (c, s) => const UjianCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'ujian-detail',
                builder: (c, s) =>
                    UjianDetailScreen(ujianId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'bank-soal',
            name: 'bank-soal-list',
            builder: (c, s) => const BankSoalListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'bank-soal-create',
                builder: (c, s) => const BankSoalCreateScreen(),
              ),
            ],
          ),
        ],
      ),
    ]),
    // Tab 5: Profil
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
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => DashboardShell(shell: shell),
        branches: branches,
      ),
    ],
  );
});

const kBottomNavItems = <_NavItem>[
  _NavItem(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home, location: '/dashboard/home'),
  _NavItem(label: 'Santri', icon: Icons.people_outline, activeIcon: Icons.people, location: '/dashboard/santri'),
  _NavItem(label: 'Akademik', icon: Icons.school_outlined, activeIcon: Icons.school, location: '/dashboard/akademik'),
  _NavItem(label: 'Ujian', icon: Icons.quiz_outlined, activeIcon: Icons.quiz, location: '/dashboard/ujian'),
  _NavItem(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person, location: '/dashboard/profile'),
];

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.location});
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
}
