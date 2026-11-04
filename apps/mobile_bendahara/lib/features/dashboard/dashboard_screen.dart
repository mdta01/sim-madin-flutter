// ============================================================================
// DashboardScreen — Bottom-tab shell untuk mobile_bendahara
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
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
      setupBendaharaRealtime(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Outer shell hanya punya body + bottomNav.
    // AppBar & logout ada di masing-masing tab supaya tidak nested AppBar.
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) {
          widget.shell.goBranch(
            i,
            initialLocation: i == widget.shell.currentIndex,
          );
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
// DashboardHomeTab — Beranda (isi dari tab 1)
// ============================================================================
// Menampilkan:
//   1. 4 KPI cards (Pemasukan Hari Ini, Tunggakan, Pending Verif, Saldo Kas)
//   2. Quick menu (Input Pembayaran, Tunggakan, Tagihan, Riwayat, Kas,
//      Transaksi Kas, Honor Guru, Laporan)
//   3. Pembayaran terbaru (5 terakhir)
// ============================================================================

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentRecentProvider);
    // KPI aggregate provider — exact counts/sums tanpa underestimate
    // dari paymentRecentProvider.limit(50).
    final kpiAsync = ref.watch(bendaharaKpiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => logoutAndNavigate(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(paymentRecentProvider);
        ref.invalidate(tagihanListProvider);
        ref.invalidate(kasListProvider);
        ref.invalidate(bendaharaKpiProvider);
        await ref.read(bendaharaKpiProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _KpiSection(
            kpiAsync: kpiAsync,
          ),
          const SizedBox(height: AppSpacing.lg),
          _QuickMenuSection(),
          const SizedBox(height: AppSpacing.lg),
          _RecentPaymentsSection(paymentsAsync: paymentsAsync),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({
    required this.kpiAsync,
  });

  final AsyncValue<BendaharaKpiStats> kpiAsync;

  @override
  Widget build(BuildContext context) {
    final pemasukanHariIni = kpiAsync.maybeWhen(
      data: (k) => k.pemasukanHariIni,
      orElse: () => 0,
    );
    final pendingVerif = kpiAsync.maybeWhen(
      data: (k) => k.pendingVerifCount,
      orElse: () => 0,
    );
    final tunggakan = kpiAsync.maybeWhen(
      data: (k) => k.tunggakan,
      orElse: () => 0,
    );
    final tunggakanCount = kpiAsync.maybeWhen(
      data: (k) => k.tunggakanCount,
      orElse: () => 0,
    );
    final saldoKas = kpiAsync.maybeWhen(
      data: (k) => k.saldoKas,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Ringkasan Hari Ini',
          icon: Icons.dashboard_outlined,
        ),
        if (kpiAsync.isLoading) ...[
          const SizedBox(height: AppSpacing.sm),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ResponsiveGrid(
          phoneColumns: 2,
          tabletColumns: 4,
          desktopColumns: 4,
          childAspectRatio: 1.1,
          children: [
            ModernStatCard(
              label: 'Pemasukan Hari Ini',
              value: formatRupiah(pemasukanHariIni),
              icon: Icons.trending_up,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            ModernStatCard(
              label: 'Tunggakan',
              value: formatRupiah(tunggakan),
              subtitle: tunggakanCount > 0
                  ? '$tunggakanCount tagihan'
                  : null,
              icon: Icons.warning,
              color: AppColors.danger,
              bgColor: AppColors.dangerLight,
            ),
            ModernStatCard(
              label: 'Perlu Verifikasi',
              value: '$pendingVerif',
              subtitle: pendingVerif > 0 ? 'pembayaran pending' : null,
              icon: Icons.pending_actions,
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
            ),
            ModernStatCard(
              label: 'Saldo Kas',
              value: formatRupiah(saldoKas),
              icon: Icons.account_balance,
              color: AppColors.primary,
              bgColor: AppColors.primaryLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Menu Cepat',
          icon: Icons.grid_view_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveGrid(
          phoneColumns: 3,
          tabletColumns: 4,
          desktopColumns: 6,
          childAspectRatio: 1.0,
          children: [
            _MenuTile(
              icon: Icons.add_circle,
              label: 'Input Pembayaran',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => context.push('/dashboard/pembayaran/create'),
            ),
            _MenuTile(
              icon: Icons.receipt_long,
              label: 'Data Tagihan',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: () => context.go('/dashboard/tagihan'),
            ),
            _MenuTile(
              icon: Icons.swap_horiz,
              label: 'Transaksi Kas',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => context.push('/dashboard/kas/transaksi'),
            ),
            _MenuTile(
              icon: Icons.school,
              label: 'Honor Guru',
              color: AppColors.warning,
              bg: AppColors.warningLight,
              onTap: () => context.push('/dashboard/home/honor-guru'),
            ),
            _MenuTile(
              icon: Icons.bar_chart,
              label: 'Laporan Keuangan',
              color: AppColors.info,
              bg: AppColors.infoLight,
              onTap: () => context.push('/dashboard/home/laporan'),
            ),
            _MenuTile(
              icon: Icons.account_balance_wallet,
              label: 'Kas & Rekening',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: () => context.go('/dashboard/kas'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.body3.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecentPaymentsSection extends StatelessWidget {
  const _RecentPaymentsSection({required this.paymentsAsync});

  final AsyncValue<List<PaymentModel>> paymentsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Pembayaran Terbaru',
          icon: Icons.receipt_outlined,
          actionLabel: 'Lihat Semua',
          onAction: () => context.go('/dashboard/pembayaran'),
        ),
        const SizedBox(height: AppSpacing.md),
        paymentsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(friendlyError(err),
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada pembayaran',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }
            final recent = list.take(5).toList();
            return Column(
              children: recent
                  .map((p) => _PaymentMiniCard(
                        payment: p,
                        onTap: () => context
                            .push('/dashboard/pembayaran/${p.id}'),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMiniCard extends StatelessWidget {
  const _PaymentMiniCard({required this.payment, required this.onTap});

  final PaymentModel payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = paymentStatusStyle(payment.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        title: Text(
          payment.santriName ?? 'Santri',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${payment.invoiceNo} • ${formatDateTime(payment.paymentDate)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRupiah(payment.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 4),
            StatusChip(status: payment.status, style: style, compact: true),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
