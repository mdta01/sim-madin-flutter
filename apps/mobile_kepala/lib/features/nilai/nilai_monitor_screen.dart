// Nilai monitor — read-only. Filter by mapel.
// Refactored untuk pakai MonitorScaffold (reusable boilerplate).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/monitor_scaffold.dart';

class NilaiMonitorScreen extends ConsumerStatefulWidget {
  const NilaiMonitorScreen({super.key});

  @override
  ConsumerState<NilaiMonitorScreen> createState() =>
      _NilaiMonitorScreenState();
}

class _NilaiMonitorScreenState extends ConsumerState<NilaiMonitorScreen> {
  String? _selectedMapelId; // null = semua mapel

  @override
  Widget build(BuildContext context) {
    final mapelListAsync = ref.watch(mapelListProvider);
    final nilaiAsync = ref.watch(nilaiRecentProvider(_selectedMapelId));

    return MonitorScaffold<NilaiModel>(
      title: 'Monitor Nilai',
      asyncValue: nilaiAsync,
      onRefresh: () async {
        ref.invalidate(nilaiRecentProvider(_selectedMapelId));
        await ref.read(nilaiRecentProvider(_selectedMapelId).future);
      },
      emptyTitle: 'Belum ada nilai',
      emptySubtitle: _selectedMapelId == null
          ? 'Nilai akan muncul setelah guru input.'
          : 'Belum ada nilai untuk mapel ini.',
      filterBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: mapelListAsync.when(
          loading: () => const SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text('Error mapel: ${friendlyError(e)}',
              style: const TextStyle(color: AppColors.danger)),
          data: (mapelList) => DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Mata Pelajaran',
              prefixIcon: Icon(Icons.book),
            ),
            value: _selectedMapelId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua Mapel'),
              ),
              ...mapelList.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.name} (${m.code})'),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedMapelId = v),
          ),
        ),
      ),
      summary: _NilaiSummaryBuilder(asyncValue: nilaiAsync),
      itemBuilder: (context, n) => _NilaiCard(nilai: n),
    );
  }
}

/// Summary card yang otomatis compute stats dari AsyncValue.
class _NilaiSummaryBuilder extends StatelessWidget {
  const _NilaiSummaryBuilder({required this.asyncValue});

  final AsyncValue<List<NilaiModel>> asyncValue;

  @override
  Widget build(BuildContext context) {
    final list = asyncValue.maybeWhen(
      data: (l) => l,
      orElse: () => <NilaiModel>[],
    );
    if (list.isEmpty) return const SizedBox.shrink();

    final avg = list.isEmpty
        ? 0.0
        : list.map((n) => n.score).reduce((a, b) => a + b) / list.length;
    final lulusCount = list.where((n) => isLulus(n.score, n.mapelKkm)).length;
    final lulusPercent = list.isEmpty
        ? 0.0
        : (lulusCount / list.length * 100).roundToDouble();

    return _NilaiStatsRow(
      avg: avg,
      count: list.length,
      lulusPercent: lulusPercent,
    );
  }
}

class _NilaiStatsRow extends StatelessWidget {
  const _NilaiStatsRow({
    required this.avg,
    required this.count,
    required this.lulusPercent,
  });

  final double avg;
  final int count;
  final double lulusPercent;

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
            child: _StatItem(
              label: 'Rata-rata',
              value: avg.toStringAsFixed(1),
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _StatItem(
              label: 'Total Nilai',
              value: '$count',
              color: AppColors.info,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _StatItem(
              label: '% Lulus KKM',
              value: '${lulusPercent.toStringAsFixed(0)}%',
              color: lulusPercent >= 80
                  ? AppColors.success
                  : lulusPercent >= 60
                      ? AppColors.warning
                      : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _NilaiCard extends StatelessWidget {
  const _NilaiCard({required this.nilai});
  final NilaiModel nilai;

  @override
  Widget build(BuildContext context) {
    final lulus = isLulus(nilai.score, nilai.mapelKkm);
    final typeColor = nilai.type == NilaiType.uas
        ? AppColors.danger
        : nilai.type == NilaiType.uts
            ? AppColors.warning
            : AppColors.primary;
    final typeBg = nilai.type == NilaiType.uas
        ? AppColors.dangerLight
        : nilai.type == NilaiType.uts
            ? AppColors.warningLight
            : AppColors.primaryLight;

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
                  Text(nilai.santriName ?? 'Santri',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      '${nilai.mapelName ?? '-'} • ${nilai.kelasName ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(formatDateTime(nilai.assessmentDate),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(nilai.score.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: lulus ? AppColors.success : AppColors.danger)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(nilai.type,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
