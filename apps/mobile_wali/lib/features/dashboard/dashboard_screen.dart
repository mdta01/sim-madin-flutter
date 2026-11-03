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
      setupKepalaRealtime(ref);
    });
  }

  Future<void> _handleLogout() => logoutWaliAndNavigate(context, ref);

  String get _title {
    final i = widget.shell.currentIndex;
    return i < kBottomNavItems.length
        ? 'SIM Wali — ${kBottomNavItems[i].label}'
        : 'SIM Wali';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(waliSessionProvider);
    final waliName = session?.wali.name ?? 'Wali';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: const TextStyle(fontSize: 13)),
            Text("Assalamu'alaikum, $waliName 👋",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
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
      return const Center(child: Text('Sesi tidak ditemukan'));
    }

    return RefreshIndicator(
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
          child: _StatCard(
            label: 'Anak',
            value: '${session.santriList.length}',
            icon: Icons.people,
            color: AppColors.primary,
            bg: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatCard(
            label: 'Notif',
            value: '$unreadNotif',
            icon: Icons.notifications,
            color: unreadNotif > 0
                ? AppColors.warning
                : AppColors.textMuted,
            bg: unreadNotif > 0
                ? AppColors.warningLight
                : const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatCard(
            label: 'Chat',
            value: '$chatCount',
            icon: Icons.chat,
            color: AppColors.info,
            bg: AppColors.infoLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SantriCard extends StatelessWidget {
  const _SantriCard({required this.santri, required this.onTap});
  final SantriModel santri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                backgroundImage: santri.photoUrl != null
                    ? NetworkImage(santri.photoUrl!)
                    : null,
                child: santri.photoUrl == null
                    ? Text(santri.initials,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(santri.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('NIS: ${santri.nis}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (santri.kelasName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.infoLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(santri.kelasName!,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.info)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: santri.status == SantriStatus.aktif
                                ? AppColors.successLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(santri.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: santri.status == SantriStatus.aktif
                                      ? AppColors.success
                                      : AppColors.danger)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
