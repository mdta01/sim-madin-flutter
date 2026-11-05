// Nilai — read-only list with filter + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class NilaiScreen extends ConsumerStatefulWidget {
  const NilaiScreen({super.key});
  @override
  ConsumerState<NilaiScreen> createState() => _NilaiScreenState();
}
class _NilaiScreenState extends ConsumerState<NilaiScreen> {
  String? _kelasId, _mapelId, _type = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(nilaiListAdminProvider(NilaiFilterParams(kelasId: _kelasId, mapelId: _mapelId, type: _type)));
    final kelasAsync = ref.watch(kelasListProvider);
    final mapelAsync = ref.watch(mapelListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Nilai Santri',
          icon: Icons.grade_outlined,
          subtitle: 'Input & rekap nilai',
          actions: [
            SizedBox(width: 180, child: kelasAsync.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (list) => DropdownButtonFormField<String>(value: _kelasId, hint: const Text('Semua Kelas'), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('Semua Kelas')), ...list.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name)))], onChanged: (v) => setState(() => _kelasId = v)))),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 180, child: mapelAsync.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (list) => DropdownButtonFormField<String>(value: _mapelId, hint: const Text('Semua Mapel'), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('Semua Mapel')), ...list.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))], onChanged: (v) => setState(() => _mapelId = v)))),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: 120, child: DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: NilaiType.harian, child: Text('Harian')), DropdownMenuItem(value: NilaiType.uts, child: Text('UTS')), DropdownMenuItem(value: NilaiType.uas, child: Text('UAS'))], onChanged: (v) => setState(() => _type = v ?? 'ALL'))),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(nilaiListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(nilaiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Tidak ada nilai', subtitle: 'Belum ada data nilai tersimpan. Coba ubah filter atau refresh.', icon: Icons.star_outline) : ModernDataTableContainer(
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Santri')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Type')), DataColumn(label: Text('Nilai')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Actions'))],
              rows: list.map((n) {
                final lulus = isLulus(n.score, n.mapelKkm);
                return DataRow(cells: [
                  DataCell(Text(n.santriName ?? '-', style: AppTextStyles.label)),
                  DataCell(Text(n.mapelName ?? '-', style: AppTextStyles.body3)),
                  DataCell(Text(n.kelasName ?? '-', style: AppTextStyles.body3)),
                  DataCell(StatusChip(label: n.type, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                  DataCell(Text(n.score.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: lulus ? AppColors.success : AppColors.danger))),
                  DataCell(Text(formatDate(n.assessmentDate), style: AppTextStyles.body3)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteNilai(ref, n.id); })),
                ]);
              }).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
