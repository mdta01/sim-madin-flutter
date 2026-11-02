// DashboardScreen — Bottom-tab shell untuk mobile_guru.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:api_client/api_client.dart';

import '../../app/router.dart';
import '../../widgets/feedback_widgets.dart';
import '../profile/profile_screen.dart' show logoutAndNavigate;

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

  Future<void> _handleLogout() => logoutAndNavigate(context, ref);

  String get _title {
    final i = widget.shell.currentIndex;
    return i < kBottomNavItems.length
        ? 'SIM MADIN — ${kBottomNavItems[i].label}'
        : 'SIM MADIN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
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
// DashboardHomeTab — Beranda (Tab 1)
// ============================================================================

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(guruStatsProvider);
    final jadwalAsync = ref.watch(jadwalHariIniProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(guruStatsProvider);
        ref.invalidate(jadwalHariIniProvider);
        await ref.read(guruStatsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // KPI stats
          statsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (e, _) => Text('Stats error: $e',
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  label: 'Jadwal Hari Ini',
                  value: '${stats.jadwalTodayCount}',
                  icon: Icons.calendar_today,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                ),
                StatCard(
                  label: 'Pertemuan Hari Ini',
                  value: '${stats.pertemuanTodayCount}',
                  icon: Icons.event_available,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
                StatCard(
                  label: 'Materi Saya',
                  value: '${stats.materiCount}',
                  icon: Icons.folder_open,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                ),
                StatCard(
                  label: 'Tugas Aktif',
                  value: '${stats.tugasActiveCount}',
                  icon: Icons.assignment,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Quick menu
          const Text('Menu Cepat',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.0,
            children: [
              _menuTile(context, 'Absensi', Icons.check_circle_outline,
                  AppColors.success, AppColors.successLight, '/dashboard/akademik/absensi'),
              _menuTile(context, 'Nilai', Icons.star_outline,
                  AppColors.primary, AppColors.primaryLight, '/dashboard/akademik/nilai'),
              _menuTile(context, 'Materi', Icons.book_outlined, AppColors.info,
                  AppColors.infoLight, '/dashboard/akademik/materi'),
              _menuTile(context, 'Tugas', Icons.assignment_outlined,
                  AppColors.success, AppColors.successLight, '/dashboard/akademik/tugas'),
              _menuTile(context, 'Pertemuan', Icons.event_outlined,
                  AppColors.primary, AppColors.primaryLight, '/dashboard/akademik/pertemuan'),
              _menuTile(context, 'Perkembangan', Icons.trending_up,
                  AppColors.success, AppColors.successLight, '/dashboard/akademik/perkembangan'),
              _menuTile(context, 'Ujian', Icons.quiz_outlined, AppColors.danger,
                  AppColors.dangerLight, '/dashboard/ujian/list'),
              _menuTile(context, 'Chat Wali', Icons.chat_outlined,
                  const Color(0xFF7C3AED), const Color(0xFFEDE9FE), '/dashboard/akademik/chat'),
              _menuTile(context, 'Jadwal', Icons.calendar_month_outlined,
                  AppColors.info, AppColors.infoLight, '/dashboard/akademik/jadwal'),
              _menuTile(context, 'Pengumuman', Icons.campaign_outlined,
                  AppColors.warning, AppColors.warningLight, '/dashboard/akademik/pengumuman'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Today's schedule
          Row(
            children: [
              const Text('Jadwal Hari Ini',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                  onPressed: () => context.push('/dashboard/akademik/jadwal'),
                  child: const Text('Lihat Semua')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          jadwalAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            data: (list) {
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: Text('Tidak ada jadwal hari ini 🎉',
                        style: TextStyle(color: AppColors.success)),
                  ),
                );
              }
              return Column(
                children: list.map((j) => _JadwalCard(jadwal: j)).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, String label, IconData icon,
      Color color, Color bg, String location) {
    return InkWell(
      onTap: () => context.push(location),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  const _JadwalCard({required this.jadwal});
  final JadwalModel jadwal;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Text(jadwal.startTime,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  Text(jadwal.endTime,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jadwal.mapelName ?? 'Mapel',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(jadwal.kelasName ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 20),
              color: AppColors.success,
              tooltip: 'Input Absensi',
              onPressed: () => context.push('/dashboard/akademik/absensi'),
            ),
          ],
        ),
      ),
    );
  }
}
