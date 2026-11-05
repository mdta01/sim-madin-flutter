// Dashboard admin — KPI cards + recent activity + quick stats (modern UI).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

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
          // Welcome banner (modern gradient)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.dashboard, color: AppColors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard Admin',
                          style: AppTextStyles.h2.copyWith(color: AppColors.white)),
                      const SizedBox(height: 4),
                      Text('Selamat datang di SIM MADIN Admin Desktop',
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // KPI cards (modern)
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (e, _) => ModernErrorView(
                message: friendlyError(e),
                onRetry: () =>
                    ref.invalidate(adminDashboardStatsProvider)),
            data: (stats) => ResponsiveGrid(
              phoneColumns: 2,
              tabletColumns: 3,
              desktopColumns: 3,
              childAspectRatio: 3.0,
              children: [
                ModernStatCard(
                  label: 'Total Santri Aktif',
                  value: '${stats.totalSantri}',
                  icon: Icons.people,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                  subtitle: 'Santri terdaftar',
                ),
                ModernStatCard(
                  label: 'Total Guru Aktif',
                  value: '${stats.totalGuru}',
                  icon: Icons.school,
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  subtitle: 'Guru mengajar',
                ),
                ModernStatCard(
                  label: 'Total Kelas',
                  value: '${stats.totalKelas}',
                  icon: Icons.class_,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                  subtitle: 'Kelas aktif',
                ),
                ModernStatCard(
                  label: 'Pemasukan Bulan Ini',
                  value: formatRupiah(stats.totalIncomeThisMonth),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                  subtitle: '${stats.totalPayments} transaksi verified',
                ),
                ModernStatCard(
                  label: 'Total Tunggakan',
                  value: formatRupiah(stats.totalOutstanding),
                  icon: Icons.warning,
                  color: AppColors.danger,
                  bgColor: AppColors.dangerLight,
                  subtitle: 'Tagihan belum lunas',
                ),
                ModernStatCard(
                  label: 'Quick Actions',
                  value: 'Kelola',
                  icon: Icons.admin_panel_settings,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                  subtitle: 'Users • Roles • Settings',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Quick access tiles (modern)
          const SectionHeader(title: 'Quick Access', icon: Icons.grid_view_outlined),
          const SizedBox(height: AppSpacing.md),
          ResponsiveGrid(
            phoneColumns: 2,
            tabletColumns: 4,
            desktopColumns: 4,
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
          // System status info (modern)
          ModernCard(
            backgroundColor: AppColors.infoLight,
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Status Sistem',
                        style: AppTextStyles.h4.copyWith(color: AppColors.info)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Semua modul admin sudah aktif:\n'
                  '• Master Data (Santri, Wali, Guru, Kelas, Mapel)\n'
                  '• Akademik (Jadwal, Absensi, Nilai, Ujian, Bank Soal)\n'
                  '• Keuangan (Tagihan, Pembayaran, Kas, Honor Guru)\n'
                  '• Komunikasi (Notifikasi, Pengumuman, Surat, Chat)\n'
                  '• Administrasi (Users, Roles, Permissions, Settings)\n'
                  '• Monitoring (Dashboard, Audit Log, Alumni)',
                  style: AppTextStyles.body2.copyWith(color: AppColors.info),
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
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTextStyles.h4),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
