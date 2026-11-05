// Pembayaran monitor — read-only. Recent payments + verify status breakdown.
// Refactored untuk pakai MonitorScaffold (reusable boilerplate).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/monitor_scaffold.dart';
import '../../widgets/status_chip.dart';

class PembayaranMonitorScreen extends ConsumerWidget {
  const PembayaranMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(paymentRecentProvider);

    return MonitorScaffold<PaymentModel>(
      title: 'Monitor Pembayaran',
      asyncValue: asyncValue,
      onRefresh: () async {
        ref.invalidate(paymentRecentProvider);
        await ref.read(paymentRecentProvider.future);
      },
      emptyTitle: 'Belum ada pembayaran',
      emptySubtitle: 'Pembayaran akan muncul setelah diinput oleh bendahara.',
      summary: _PembayaranSummaryBuilder(asyncValue: asyncValue),
      itemBuilder: (context, p) => _PembayaranCard(payment: p),
    );
  }
}

/// Summary card yang otomatis compute stats dari AsyncValue.
/// Di-render sebagai item pertama di ListView (via MonitorScaffold.summary).
class _PembayaranSummaryBuilder extends StatelessWidget {
  const _PembayaranSummaryBuilder({required this.asyncValue});

  final AsyncValue<List<PaymentModel>> asyncValue;

  @override
  Widget build(BuildContext context) {
    final list = asyncValue.maybeWhen(
      data: (l) => l,
      orElse: () => <PaymentModel>[],
    );
    if (list.isEmpty) return const SizedBox.shrink();

    final verifiedIncome = list
        .where((p) => p.status == PaymentStatus.verified)
        .fold<double>(0, (s, p) => s + p.amount);
    final pendingCount =
        list.where((p) => p.status == PaymentStatus.pending).length;
    final verifiedCount =
        list.where((p) => p.status == PaymentStatus.verified).length;

    return _PembayaranSummaryCard(
      verifiedIncome: verifiedIncome,
      verifiedCount: verifiedCount,
      pendingCount: pendingCount,
      totalCount: list.length,
    );
  }
}

class _PembayaranSummaryCard extends StatelessWidget {
  const _PembayaranSummaryCard({
    required this.verifiedIncome,
    required this.verifiedCount,
    required this.pendingCount,
    required this.totalCount,
  });

  final double verifiedIncome;
  final int verifiedCount;
  final int pendingCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pemasukan Terverifikasi',
            style: TextStyle(fontSize: 12, color: AppColors.white),
          ),
          Text(
            formatRupiah(verifiedIncome),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Item(label: 'Terverifikasi', value: '$verifiedCount'),
              ),
              Expanded(
                child: _Item(label: 'Pending', value: '$pendingCount'),
              ),
              Expanded(
                child: _Item(label: 'Total', value: '$totalCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.white)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white)),
      ],
    );
  }
}

class _PembayaranCard extends StatelessWidget {
  const _PembayaranCard({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final style = paymentStatusStyle(payment.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.santriName ?? 'Santri',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(payment.invoiceNo,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                      '${formatDateTime(payment.paymentDate)} • ${PaymentMethod.label(payment.paymentMethod)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRupiah(payment.amount),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                const SizedBox(height: 4),
                StatusChip(status: payment.status, style: style, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
