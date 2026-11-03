// ============================================================================
// DashboardScreen — Bottom-tab shell untuk mobile_bendahara
// ============================================================================

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
      setupKepalaRealtime(ref); // same provider, subscribes 4 tabel
    });
  }

  Future<void> _handleLogout() => logoutAndNavigate(context, ref);

  String get _title {
    final i = widget.shell.currentIndex;
    if (i < kBottomNavItems.length) {
      return 'SIM MADIN — ${kBottomNavItems[i].label}';
    }
    return 'SIM MADIN';
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
    final tagihanAsync = ref.watch(tagihanListProvider(TagihanStatus.belumBayar));
    final kasAsync = ref.watch(kasListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(paymentRecentProvider);
        ref.invalidate(tagihanListProvider);
        ref.invalidate(kasListProvider);
        await ref.read(paymentRecentProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _KpiSection(
            paymentsAsync: paymentsAsync,
            tagihanAsync: tagihanAsync,
            kasAsync: kasAsync,
          ),
          const SizedBox(height: AppSpacing.lg),
          _QuickMenuSection(),
          const SizedBox(height: AppSpacing.lg),
          _RecentPaymentsSection(paymentsAsync: paymentsAsync),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({
    required this.paymentsAsync,
    required this.tagihanAsync,
    required this.kasAsync,
  });

  final AsyncValue<List<PaymentModel>> paymentsAsync;
  final AsyncValue<List<TagihanModel>> tagihanAsync;
  final AsyncValue<List<KasModel>> kasAsync;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pemasukanHariIni = paymentsAsync.maybeWhen(
      data: (list) => list
          .where((p) =>
              p.status == PaymentStatus.verified &&
              p.paymentDate.year == now.year &&
              p.paymentDate.month == now.month &&
              p.paymentDate.day == now.day)
          .fold<double>(0, (s, p) => s + p.amount),
      orElse: () => 0,
    );
    final tunggakan = tagihanAsync.maybeWhen(
      data: (list) =>
          list.fold<double>(0, (s, t) => s + tagihanOutstanding(t)),
      orElse: () => 0,
    );
    final tunggakanCount = tagihanAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final pendingVerif = paymentsAsync.maybeWhen(
      data: (list) =>
          list.where((p) => p.status == PaymentStatus.pending).length,
      orElse: () => 0,
    );
    final saldoKas = kasAsync.maybeWhen(
      data: (list) => list.fold<double>(0, (s, k) => s + k.balance),
      orElse: () => 0,
    );

    final isLoading = paymentsAsync.isLoading ||
        tagihanAsync.isLoading ||
        kasAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ringkasan Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              label: 'Pemasukan Hari Ini',
              value: formatRupiah(pemasukanHariIni),
              icon: Icons.trending_up,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            StatCard(
              label: 'Tunggakan',
              value: formatRupiah(tunggakan),
              subtitle: '$tunggakanCount tagihan',
              icon: Icons.warning,
              color: AppColors.danger,
              bgColor: AppColors.dangerLight,
            ),
            StatCard(
              label: 'Perlu Verifikasi',
              value: '$pendingVerif',
              subtitle: 'pembayaran pending',
              icon: Icons.pending_actions,
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
            ),
            StatCard(
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
        const Text(
          'Menu Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
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
    return InkWell(
      onTap: onTap,
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        Row(
          children: [
            const Text(
              'Pembayaran Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/dashboard/pembayaran'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
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
