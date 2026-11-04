// Dashboard (shell + home tab with anak list).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../app/router.dart';
import '../profile/profile_screen.dart' show logoutWaliAndNavigate;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupWaliRealtime(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Outer shell hanya punya body + bottomNav.
    // AppBar & logout ada di masing-masing tab (Beranda/Chat/Profil)
    // supaya tidak terjadi nested AppBar (dua AppBar bertumpuk).
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) {
          widget.shell.goBranch(i,
              initialLocation: i == widget.shell.currentIndex);
        },
        destinations: [
          for (final item in kBottomNavItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryLight,
        height: 64,
      ),
    );
  }
}

// ============================================================================
// DashboardHomeTab — list anak + quick stats
// ============================================================================

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(waliSessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Beranda')),
        body: const Center(child: Text('Sesi tidak ditemukan. Silakan login ulang.')),
      );
    }
    final waliName = session.wali.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SIM Wali — Beranda', style: TextStyle(fontSize: 13)),
            Text("Assalamu'alaikum, $waliName 👋",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => logoutWaliAndNavigate(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(santriAnakProvider);
          ref.invalidate(notifikasiWaliProvider);
          ref.invalidate(chatRoomsWaliProvider);
          await ref.read(santriAnakProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
          // Quick stats row
          _StatsRow(session: session),
          const SizedBox(height: AppSpacing.lg),
          // Section: Anak Saya
          Row(
            children: [
              const Text('Anak Saya',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${session.santriList.length} anak',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (session.santriList.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  Icon(Icons.people, size: 64, color: AppColors.textMuted),
                  SizedBox(height: AppSpacing.md),
                  Text('Belum ada anak terhubung',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                      'Hubungi madrasah untuk menghubungkan akun Anda dengan anak.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...session.santriList.map((s) => _SantriCard(
                  santri: s,
                  onTap: () => context.push(
                      '/dashboard/home/santri/${s.id}'),
                )),
          const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.session});
  final TypedWaliSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notifikasiWaliProvider);
    final chatAsync = ref.watch(chatRoomsWaliProvider);

    final unreadNotif = notifAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
    final chatCount = chatAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Row(
      children: [
        Expanded(
          child: ModernStatCard(
            label: 'Anak',
            value: '${session.santriList.length}',
            icon: Icons.people,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ModernStatCard(
            label: 'Notif',
            value: '$unreadNotif',
            icon: Icons.notifications,
            color: unreadNotif > 0
                ? AppColors.warning
                : AppColors.textMuted,
            bgColor: unreadNotif > 0
                ? AppColors.warningLight
                : const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ModernStatCard(
            label: 'Chat',
            value: '$chatCount',
            icon: Icons.chat,
            color: AppColors.info,
            bgColor: AppColors.infoLight,
          ),
        ),
      ],
    );
  }
}

class _SantriCard extends StatelessWidget {
  const _SantriCard({required this.santri, required this.onTap});
  final SantriModel santri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ModernAvatar(
            name: santri.name,
            photoUrl: santri.photoUrl,
            radius: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(santri.name,
                    style: AppTextStyles.h3),
                Text('NIS: ${santri.nis}',
                    style: AppTextStyles.body3
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  children: [
                    if (santri.kelasName != null)
                      ModernChip(
                        label: santri.kelasName!,
                        color: AppColors.info,
                        bg: AppColors.infoLight,
                        compact: true,
                      ),
                    ModernChip(
                      label: santri.status == SantriStatus.aktif
                          ? 'Aktif'
                          : santri.status,
                      color: santri.status == SantriStatus.aktif
                          ? AppColors.success
                          : AppColors.danger,
                      bg: santri.status == SantriStatus.aktif
                          ? AppColors.successLight
                          : AppColors.dangerLight,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
