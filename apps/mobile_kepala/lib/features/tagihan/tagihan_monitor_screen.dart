// Tagihan monitor — read-only. Filter by status.
// Refactored untuk pakai MonitorScaffold (reusable boilerplate).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/monitor_scaffold.dart';
import '../../widgets/status_chip.dart';

class TagihanMonitorScreen extends ConsumerStatefulWidget {
  const TagihanMonitorScreen({super.key});

  @override
  ConsumerState<TagihanMonitorScreen> createState() =>
      _TagihanMonitorScreenState();
}

class _TagihanMonitorScreenState extends ConsumerState<TagihanMonitorScreen> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(tagihanListProvider(_statusFilter));

    return MonitorScaffold<TagihanModel>(
      title: 'Monitor Tagihan',
      asyncValue: asyncValue,
      onRefresh: () async {
        ref.invalidate(tagihanListProvider(_statusFilter));
        await ref.read(tagihanListProvider(_statusFilter).future);
      },
      emptyTitle: 'Belum ada tagihan',
      emptySubtitle: _statusFilter == 'ALL'
          ? 'Tagihan akan muncul setelah di-generate.'
          : 'Tidak ada tagihan dengan status ini.',
      filterBar: Padding(
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
                value: TagihanStatus.belumBayar, child: Text('Belum Bayar')),
            DropdownMenuItem(value: TagihanStatus.cicil, child: Text('Cicil')),
            DropdownMenuItem(value: TagihanStatus.lunas, child: Text('Lunas')),
          ],
          onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
        ),
      ),
      summary: _TagihanSummaryBuilder(asyncValue: asyncValue),
      itemBuilder: (context, t) => _TagihanCard(tagihan: t),
    );
  }
}

/// Summary card yang otomatis compute stats dari AsyncValue.
class _TagihanSummaryBuilder extends StatelessWidget {
  const _TagihanSummaryBuilder({required this.asyncValue});

  final AsyncValue<List<TagihanModel>> asyncValue;

  @override
  Widget build(BuildContext context) {
    final list = asyncValue.maybeWhen(
      data: (l) => l,
      orElse: () => <TagihanModel>[],
    );
    if (list.isEmpty) return const SizedBox.shrink();

    final totalOutstanding = list
        .where((t) => t.status != TagihanStatus.lunas)
        .fold<double>(0, (s, t) => s + tagihanOutstanding(t));
    final totalTagihan =
        list.fold<double>(0, (s, t) => s + t.amount);
    final totalPaid =
        list.fold<double>(0, (s, t) => s + t.paidAmount);

    return _TagihanSummaryCard(
      totalOutstanding: totalOutstanding,
      totalTagihan: totalTagihan,
      totalPaid: totalPaid,
      count: list.length,
    );
  }
}

class _TagihanSummaryCard extends StatelessWidget {
  const _TagihanSummaryCard({
    required this.totalOutstanding,
    required this.totalTagihan,
    required this.totalPaid,
    required this.count,
  });

  final double totalOutstanding;
  final double totalTagihan;
  final double totalPaid;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Tunggakan',
              style: TextStyle(fontSize: 12, color: AppColors.white)),
          Text(formatRupiah(totalOutstanding),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _SummaryItem(
                      label: 'Total Tagihan', value: formatRupiah(totalTagihan))),
              Expanded(
                  child: _SummaryItem(
                      label: 'Sudah Dibayar', value: formatRupiah(totalPaid))),
              Expanded(
                  child: _SummaryItem(label: 'Jumlah', value: '$count')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
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
                color: AppColors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _TagihanCard extends StatelessWidget {
  const _TagihanCard({required this.tagihan});
  final TagihanModel tagihan;

  @override
  Widget build(BuildContext context) {
    final style = tagihanStatusStyle(tagihan.status);
    final outstanding = tagihanOutstanding(tagihan);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tagihan.santriName ?? 'Santri',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                StatusChip(status: tagihan.status, style: style, compact: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${tagihan.jenisTagihanName ?? tagihan.jenisTagihanCode ?? 'Tagihan'} • ${tagihan.santriNis ?? '-'} • ${tagihan.kelasName ?? '-'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            if (tagihan.description != null) ...[
              const SizedBox(height: 2),
              Text(tagihan.description!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      Text(formatRupiah(tagihan.amount),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dibayar',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      Text(formatRupiah(tagihan.paidAmount),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sisa',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      Text(formatRupiah(outstanding),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: outstanding > 0
                                  ? AppColors.danger
                                  : AppColors.success)),
                    ],
                  ),
                ),
                if (tagihan.dueDate != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jatuh Tempo',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        Text(formatDate(tagihan.dueDate),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
