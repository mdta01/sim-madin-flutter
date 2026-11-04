// Pembayaran list — read-only monitor (Tab 2 di bottom nav).
// Tap card untuk detail + verify/reject/cetak.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class PembayaranListScreen extends ConsumerStatefulWidget {
  const PembayaranListScreen({super.key});

  @override
  ConsumerState<PembayaranListScreen> createState() =>
      _PembayaranListScreenState();
}

class _PembayaranListScreenState extends ConsumerState<PembayaranListScreen> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(paymentRecentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Input Pembayaran',
            onPressed: () => context.push('/dashboard/pembayaran/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                prefixIcon: Icon(Icons.filter_list),
              ),
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Semua')),
                DropdownMenuItem(
                    value: PaymentStatus.pending, child: Text('Pending')),
                DropdownMenuItem(
                    value: PaymentStatus.verified, child: Text('Verified')),
                DropdownMenuItem(
                    value: PaymentStatus.rejected, child: Text('Rejected')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
            ),
          ),
          Expanded(
            child: asyncValue.when(
              loading: () => const ModernLoadingSkeleton(),
              error: (err, _) => ModernErrorView(
                message: friendlyError(err),
                onRetry: () => ref.invalidate(paymentRecentProvider),
              ),
              data: (list) {
                final filtered = _statusFilter == 'ALL'
                    ? list
                    : list.where((p) => p.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return ModernEmptyState(
                    title: 'Belum ada pembayaran',
                    subtitle: _statusFilter == 'ALL'
                        ? 'Tap tombol + untuk input pembayaran baru.'
                        : 'Tidak ada pembayaran dengan status ini.',
                    icon: Icons.payment_outlined,
                    actionLabel: 'Refresh',
                    onAction: () => ref.invalidate(paymentRecentProvider),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(paymentRecentProvider);
                    await ref.read(paymentRecentProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return _PembayaranCard(payment: p);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PembayaranCard extends StatelessWidget {
  const _PembayaranCard({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final style = paymentStatusStyle(payment.status);
    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () => context.push('/dashboard/pembayaran/${payment.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.santriName ?? 'Santri',
                  style: AppTextStyles.h4.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.invoiceNo,
                  style: AppTextStyles.body3
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDateTime(payment.paymentDate)} • ${PaymentMethod.label(payment.paymentMethod)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(payment.amount),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip(status: payment.status, style: style, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
