// Absensi monitor — read-only. Filter by tanggal (default hari ini).
// Diakses dari Dashboard quick menu atau dari tab Akademik.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_views.dart';
import '../../widgets/status_chip.dart';

class AbsensiMonitorScreen extends ConsumerStatefulWidget {
  const AbsensiMonitorScreen({super.key});

  @override
  ConsumerState<AbsensiMonitorScreen> createState() =>
      _AbsensiMonitorScreenState();
}

class _AbsensiMonitorScreenState extends ConsumerState<AbsensiMonitorScreen> {
  DateTime? _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(absensiRecentProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monitor Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pilih Tanggal',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Semua Tanggal',
            onPressed: () => setState(() => _selectedDate = null),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(absensiRecentProvider(_selectedDate)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: _selectedDate == null
                  ? 'Belum ada data absensi'
                  : 'Tidak ada absensi di tanggal ini',
              subtitle: _selectedDate == null
                  ? 'Absensi akan muncul setelah guru input.'
                  : formatDate(_selectedDate!),
              onRefresh: () =>
                  ref.invalidate(absensiRecentProvider(_selectedDate)),
            );
          }

          // Summary cards: count by status.
          final hadir = list.where((a) => a.status == AbsensiStatus.hadir).length;
          final sakit = list.where((a) => a.status == AbsensiStatus.sakit).length;
          final izin = list.where((a) => a.status == AbsensiStatus.izin).length;
          final alfa = list.where((a) => a.status == AbsensiStatus.alfa).length;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(absensiRecentProvider(_selectedDate));
              await ref.read(absensiRecentProvider(_selectedDate).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Tanggal: ${formatDate(_selectedDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                _AbsensiSummaryRow(hadir: hadir, sakit: sakit, izin: izin, alfa: alfa),
                const SizedBox(height: AppSpacing.md),
                ...list.map((a) => _AbsensiCard(absensi: a)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AbsensiSummaryRow extends StatelessWidget {
  const _AbsensiSummaryRow({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alfa,
  });

  final int hadir;
  final int sakit;
  final int izin;
  final int alfa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusCount(
              label: 'Hadir',
              count: hadir,
              color: AppColors.success,
              bg: AppColors.successLight,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StatusCount(
              label: 'Sakit',
              count: sakit,
              color: AppColors.warning,
              bg: AppColors.warningLight,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StatusCount(
              label: 'Izin',
              count: izin,
              color: AppColors.info,
              bg: AppColors.infoLight,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StatusCount(
              label: 'Alfa',
              count: alfa,
              color: AppColors.danger,
              bg: AppColors.dangerLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  final String label;
  final int count;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsensiCard extends StatelessWidget {
  const _AbsensiCard({required this.absensi});

  final AbsensiModel absensi;

  @override
  Widget build(BuildContext context) {
    final style = absensiStatusStyle(absensi.status);
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
                  Text(
                    absensi.santriName ?? 'Santri',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${absensi.kelasName ?? '-'} • ${formatDate(absensi.date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (absensi.note != null && absensi.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Catatan: ${absensi.note}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusChip(status: absensi.status, style: style),
          ],
        ),
      ),
    );
  }
}
