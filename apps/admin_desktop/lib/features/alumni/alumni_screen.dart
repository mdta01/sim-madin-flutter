// Alumni — read-only list + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class AlumniScreen extends ConsumerWidget {
  const AlumniScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alumniListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Alumni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(alumniListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(alumniListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada alumni', icon: Icons.verified_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('NIS')), DataColumn(label: Text('Lulus')), DataColumn(label: Text('Status')), DataColumn(label: Text('Pekerjaan')), DataColumn(label: Text('Domisili')), DataColumn(label: Text('Actions'))],
              rows: list.map((a) => DataRow(cells: [
                DataCell(Text(a.santriName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(a.santriNis, style: const TextStyle(fontSize: 12))),
                DataCell(Text('${a.tahunLulus}', style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: a.statusKelulusan, color: AppColors.success, bg: AppColors.successLight, compact: true)),
                DataCell(Text(a.pekerjaan, style: const TextStyle(fontSize: 12))),
                DataCell(Text(a.domisiliKota, style: const TextStyle(fontSize: 12))),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteAlumni(ref, a.id); })),
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
