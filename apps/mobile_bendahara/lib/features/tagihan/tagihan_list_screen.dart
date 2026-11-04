// Tagihan list — read-only monitor with filter (Tab 3 di bottom nav).
// Bendahara tidak generate tagihan (admin desktop Phase 6 yang handle).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class TagihanListScreen extends ConsumerStatefulWidget {
  const TagihanListScreen({super.key});

  @override
  ConsumerState<TagihanListScreen> createState() =>
      _TagihanListScreenState();
}

class _TagihanListScreenState extends ConsumerState<TagihanListScreen> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(tagihanListProvider(_statusFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Data Tagihan')),
      body: Column(
        children: [
          // Filter pills
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Semua',
                    active: _statusFilter == 'ALL',
                    onTap: () => setState(() => _statusFilter = 'ALL'),
                  ),
                  _FilterPill(
                    label: 'Belum Bayar',
                    active: _statusFilter == TagihanStatus.belumBayar,
                    onTap: () => setState(() =>
                        _statusFilter = TagihanStatus.belumBayar),
                  ),
                  _FilterPill(
                    label: 'Cicil',
                    active: _statusFilter == TagihanStatus.cicil,
                    onTap: () => setState(
                        () => _statusFilter = TagihanStatus.cicil),
                  ),
                  _FilterPill(
                    label: 'Lunas',
                    active: _statusFilter == TagihanStatus.lunas,
                    onTap: () => setState(
                        () => _statusFilter = TagihanStatus.lunas),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(),
              error: (err, _) => ErrorView(
                message: friendlyError(err),
                onRetry: () =>
                    ref.invalidate(tagihanListProvider(_statusFilter)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada tagihan',
                    subtitle: _statusFilter == 'ALL'
                        ? 'Tagihan di-generate oleh admin desktop.'
                        : 'Tidak ada tagihan dengan status ini.',
                    icon: Icons.receipt_long_outlined,
                    onRefresh: () => ref
                        .invalidate(tagihanListProvider(_statusFilter)),
                  );
                }

                final totalOutstanding = list
                    .where((t) => t.status != TagihanStatus.lunas)
                    .fold<double>(
                        0, (s, t) => s + tagihanOutstanding(t));
                final totalTagihan =
                    list.fold<double>(0, (s, t) => s + t.amount);

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(tagihanListProvider(_statusFilter));
                    await ref.read(
                        tagihanListProvider(_statusFilter).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _SummaryCard(
                        totalOutstanding: totalOutstanding,
                        totalTagihan: totalTagihan,
                        count: list.length,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...list.map((t) => _TagihanCard(
                            tagihan: t,
                            onTap: () => _showTagihanDetail(context, t),
                          )),
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

  /// Bottom sheet detail tagihan — tampilkan info lengkap + riwayat pembayaran.
  void _showTagihanDetail(BuildContext context, TagihanModel t) {
    final style = tagihanStatusStyle(t.status);
    final outstanding = tagihanOutstanding(t);
    final progressPct = t.amount > 0
        ? ((t.paidAmount / t.amount) * 100).clamp(0, 100).toDouble()
        : 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.jenisTagihanName ?? t.jenisTagihanCode ?? 'Tagihan',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(t.santriName ?? 'Santri',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text(
                'NIS: ${t.santriNis ?? '-'} • ${t.kelasName ?? '-'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            if (t.description != null && t.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(t.description!,
                  style: const TextStyle(fontSize: 12)),
            ],
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _DetailCell(
                      label: 'Total Tagihan',
                      value: formatRupiah(t.amount)),
                ),
                Expanded(
                  child: _DetailCell(
                      label: 'Sudah Dibayar',
                      value: formatRupiah(t.paidAmount),
                      color: AppColors.success),
                ),
                Expanded(
                  child: _DetailCell(
                      label: 'Sisa',
                      value: formatRupiah(outstanding),
                      color: outstanding > 0
                          ? AppColors.danger
                          : AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPct / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: progressPct >= 100
                    ? AppColors.success
                    : progressPct > 0
                        ? AppColors.warning
                        : AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${progressPct.toStringAsFixed(1)}% terbayar',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text('Status: ',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                StatusChip(status: t.status, style: style, compact: true),
              ],
            ),
            if (t.dueDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                      'Jatuh tempo: ${formatDate(t.dueDate)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: t.dueDate!.isBefore(DateTime.now()) &&
                                  t.status != TagihanStatus.lunas
                              ? AppColors.danger
                              : AppColors.textMuted)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                    'Dibuat: ${formatDateTime(t.createdAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.text)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          color: active ? AppColors.primary : AppColors.text,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalOutstanding,
    required this.totalTagihan,
    required this.count,
  });

  final double totalOutstanding;
  final double totalTagihan;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.danger, Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Tunggakan',
            style: TextStyle(fontSize: 12, color: AppColors.white),
          ),
          Text(
            formatRupiah(totalOutstanding),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Item(
                    label: 'Total Tagihan',
                    value: formatRupiah(totalTagihan)),
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
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.white)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white)),
      ],
    );
  }
}

class _TagihanCard extends StatelessWidget {
  const _TagihanCard({required this.tagihan, this.onTap});

  final TagihanModel tagihan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = tagihanStatusStyle(tagihan.status);
    final outstanding = tagihanOutstanding(tagihan);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tagihan.santriName ?? 'Santri',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                ),
                StatusChip(
                    status: tagihan.status, style: style, compact: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${tagihan.jenisTagihanName ?? tagihan.jenisTagihanCode ?? 'Tagihan'} • ${tagihan.santriNis ?? '-'} • ${tagihan.kelasName ?? '-'}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            if (tagihan.description != null) ...[
              const SizedBox(height: 2),
              Text(
                tagihan.description!,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _AmountCell(
                      label: 'Total',
                      value: formatRupiah(tagihan.amount)),
                ),
                Expanded(
                  child: _AmountCell(
                      label: 'Dibayar',
                      value: formatRupiah(tagihan.paidAmount),
                      color: AppColors.success),
                ),
                Expanded(
                  child: _AmountCell(
                      label: 'Sisa',
                      value: formatRupiah(outstanding),
                      color: outstanding > 0
                          ? AppColors.danger
                          : AppColors.success),
                ),
                if (tagihan.dueDate != null)
                  Expanded(
                    child: _AmountCell(
                        label: 'Tempo',
                        value: formatDate(tagihan.dueDate)),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.text)),
      ],
    );
  }
}
