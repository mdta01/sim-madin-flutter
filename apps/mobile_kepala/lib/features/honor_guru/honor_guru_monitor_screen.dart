// Honor Guru monitor — read-only. Filter by status.
// Menampilkan: total honor + breakdown per status + list honor records.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_views.dart';
import '../../widgets/status_chip.dart';

class HonorGuruMonitorScreen extends ConsumerStatefulWidget {
  const HonorGuruMonitorScreen({super.key});

  @override
  ConsumerState<HonorGuruMonitorScreen> createState() =>
      _HonorGuruMonitorScreenState();
}

class _HonorGuruMonitorScreenState extends ConsumerState<HonorGuruMonitorScreen> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(honorGuruListProvider(_statusFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Monitor Honor Guru')),
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
                    value: HonorGuruStatus.draft, child: Text('Draft')),
                DropdownMenuItem(
                    value: HonorGuruStatus.disetujui, child: Text('Disetujui')),
                DropdownMenuItem(
                    value: HonorGuruStatus.dibayarkan,
                    child: Text('Dibayarkan')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
            ),
          ),
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(honorGuruListProvider(_statusFilter)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada honor guru',
                    subtitle: _statusFilter == 'ALL'
                        ? 'Honor akan muncul setelah di-generate.'
                        : 'Tidak ada honor dengan status ini.',
                    onRefresh: () => ref
                        .invalidate(honorGuruListProvider(_statusFilter)),
                  );
                }

                // Compute summary
                final totalHonor = list.fold<double>(
                    0, (s, h) => s + (h.totalHonor > 0 ? h.totalHonor : computeTotalHonor(h)));
                final totalPaid = list
                    .where((h) => h.status == HonorGuruStatus.dibayarkan)
                    .fold<double>(0,
                        (s, h) => s + (h.totalHonor > 0 ? h.totalHonor : computeTotalHonor(h)));
                final totalPending = list
                    .where((h) => h.status != HonorGuruStatus.dibayarkan)
                    .fold<double>(0,
                        (s, h) => s + (h.totalHonor > 0 ? h.totalHonor : computeTotalHonor(h)));

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(honorGuruListProvider(_statusFilter));
                    await ref
                        .read(honorGuruListProvider(_statusFilter).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _HonorSummaryCard(
                        totalHonor: totalHonor,
                        totalPaid: totalPaid,
                        totalPending: totalPending,
                        count: list.length,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...list.map((h) => _HonorCard(honor: h)),
                    ],
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

class _HonorSummaryCard extends StatelessWidget {
  const _HonorSummaryCard({
    required this.totalHonor,
    required this.totalPaid,
    required this.totalPending,
    required this.count,
  });

  final double totalHonor;
  final double totalPaid;
  final double totalPending;
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
          const Text(
            'Total Honor',
            style: TextStyle(fontSize: 12, color: AppColors.white),
          ),
          Text(
            formatRupiah(totalHonor),
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
                child: _Item(
                    label: 'Sudah Dibayar', value: formatRupiah(totalPaid)),
              ),
              Expanded(
                child: _Item(
                    label: 'Belum Dibayar', value: formatRupiah(totalPending)),
              ),
              Expanded(child: _Item(label: 'Jumlah', value: '$count')),
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.white),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HonorCard extends StatelessWidget {
  const _HonorCard({required this.honor});

  final HonorGuruModel honor;

  @override
  Widget build(BuildContext context) {
    final style = honorGuruStatusStyle(honor.status);
    final total = honor.totalHonor > 0
        ? honor.totalHonor
        : computeTotalHonor(honor);

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
                  child: Text(
                    honor.guruName ?? 'Guru',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                StatusChip(status: honor.status, style: style, compact: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${honor.periodeLabel} • ${honor.guruSpecialization ?? 'Guru'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Component(
                        label: 'Mengajar', value: formatRupiah(honor.honorMengajar)),
                  ),
                  Expanded(
                    child: _Component(
                        label: 'Insentif', value: formatRupiah(honor.insentif)),
                  ),
                  Expanded(
                    child: _Component(
                        label: 'Tunjangan', value: formatRupiah(honor.tunjangan)),
                  ),
                  Expanded(
                    child: _Component(
                        label: 'Potongan',
                        value: '-${formatRupiah(honor.potongan)}',
                        isNegative: true),
                  ),
                  Expanded(
                    child: _Component(
                      label: 'Total',
                      value: formatRupiah(total),
                      bold: true,
                    ),
                  ),
                ],
              ),
            ),
            if (honor.catatan != null && honor.catatan!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: ${honor.catatan}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Component extends StatelessWidget {
  const _Component({
    required this.label,
    required this.value,
    this.bold = false,
    this.isNegative = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: isNegative
                ? AppColors.danger
                : bold
                    ? AppColors.primary
                    : AppColors.text,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
