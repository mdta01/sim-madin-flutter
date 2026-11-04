// Dashboard admin — KPI cards + recent activity + quick stats.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.dashboard, color: AppColors.white, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Dashboard Admin',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white)),
                      Text(
                          'Selamat datang di SIM MADIN Admin Desktop — Phase 6a',
                          style:
                              TextStyle(color: AppColors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // KPI cards
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(adminDashboardStatsProvider)),
            data: (stats) => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 3.5,
              children: [
                StatCard(
                  label: 'Total Santri Aktif',
                  value: '${stats.totalSantri}',
                  icon: Icons.people,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                  subtitle: 'Santri terdaftar',
                ),
                StatCard(
                  label: 'Total Guru Aktif',
                  value: '${stats.totalGuru}',
                  icon: Icons.school,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  subtitle: 'Guru mengajar',
                ),
                StatCard(
                  label: 'Total Kelas',
                  value: '${stats.totalKelas}',
                  icon: Icons.class_,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                  subtitle: 'Kelas aktif',
                ),
                StatCard(
                  label: 'Pemasukan Bulan Ini',
                  value: formatRupiah(stats.totalIncomeThisMonth),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                  subtitle: '${stats.totalPayments} transaksi verified',
                ),
                StatCard(
                  label: 'Total Tunggakan',
                  value: formatRupiah(stats.totalOutstanding),
                  icon: Icons.warning,
                  color: AppColors.danger,
                  bgColor: AppColors.dangerLight,
                  subtitle: 'Tagihan belum lunas',
                ),
                StatCard(
                  label: 'Quick Actions',
                  value: 'Kelola',
                  icon: Icons.admin_panel_settings,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                  subtitle: 'Users • Roles • Settings',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Quick access tiles
          const Text('Quick Access',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.5,
            children: [
              _QuickTile(
                label: 'Users',
                icon: Icons.manage_accounts,
                color: AppColors.primary,
                bg: AppColors.primaryLight,
                onTap: () => context.go('/users'),
              ),
              _QuickTile(
                label: 'Roles',
                icon: Icons.admin_panel_settings,
                color: AppColors.info,
                bg: AppColors.infoLight,
                onTap: () => context.go('/roles'),
              ),
              _QuickTile(
                label: 'Permissions',
                icon: Icons.lock,
                color: AppColors.warning,
                bg: AppColors.warningLight,
                onTap: () => context.go('/permissions'),
              ),
              _QuickTile(
                label: 'Settings',
                icon: Icons.settings,
                color: AppColors.textMuted,
                bg: const Color(0xFFF1F5F9),
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Phase 6a status info
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: AppSpacing.sm),
                    Text('Phase 6a — Active Modules',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info)),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Modul yang sudah aktif di Phase 6a:\n'
                  '• Dashboard (KPI + stats)\n'
                  '• Users (CRUD + role assignment)\n'
                  '• Roles (CRUD + permission matrix)\n'
                  '• Permissions (matrix editor — 60 codes)\n'
                  '• Settings (key-value pairs CRUD)\n\n'
                  'Modul lainnya (Santri, Wali, Guru, Kelas, Absensi, Nilai, '
                  'Tagihan, Pembayaran, Kas, Honor Guru, Materi, Tugas, '
                  'Pertemuan, Ujian, Bank Soal, Rapor, Kompetensi, '
                  'Pengumuman, Notifikasi, Surat, Perkembangan, Alumni, '
                  'Chat, QR, Audit Log) akan diimplementasikan di Phase 6b/c/d.',
                  style: TextStyle(fontSize: 13, color: AppColors.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
