// Absensi — read-only list with filter + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class AbsensiScreen extends ConsumerStatefulWidget {
  const AbsensiScreen({super.key});
  @override
  ConsumerState<AbsensiScreen> createState() => _AbsensiScreenState();
}
class _AbsensiScreenState extends ConsumerState<AbsensiScreen> {
  String? _kelasId;
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(absensiListAdminProvider(AbsensiFilterParams(kelasId: _kelasId, status: _status)));
    final kelasAsync = ref.watch(kelasListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Absensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SizedBox(width: 200, child: kelasAsync.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (list) => DropdownButtonFormField<String>(value: _kelasId, hint: const Text('Semua Kelas'), decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('Semua Kelas')), ...list.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name)))], onChanged: (v) => setState(() => _kelasId = v)))),
          const SizedBox(width: 8),
          SizedBox(width: 150, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: AbsensiStatus.hadir, child: Text('Hadir')), DropdownMenuItem(value: AbsensiStatus.sakit, child: Text('Sakit')), DropdownMenuItem(value: AbsensiStatus.izin, child: Text('Izin')), DropdownMenuItem(value: AbsensiStatus.alfa, child: Text('Alfa'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(absensiListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(absensiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Tidak ada data absensi', icon: Icons.check_circle_outline) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Santri')), DataColumn(label: Text('NIS')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((a) => DataRow(cells: [
                DataCell(Text(formatDate(a.date), style: const TextStyle(fontSize: 12))),
                DataCell(Text(a.santriName ?? '-', style: const TextStyle(fontSize: 13))),
                DataCell(Text(a.santriNis ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(a.kelasName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: a.status, color: a.status == AbsensiStatus.hadir ? AppColors.success : a.status == AbsensiStatus.alfa ? AppColors.danger : AppColors.warning, bg: a.status == AbsensiStatus.hadir ? AppColors.successLight : a.status == AbsensiStatus.alfa ? AppColors.dangerLight : AppColors.warningLight, compact: true)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteAbsensi(ref, a.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
