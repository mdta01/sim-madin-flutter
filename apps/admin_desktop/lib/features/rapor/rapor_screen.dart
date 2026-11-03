// Rapor — read-only list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class RaporScreen extends ConsumerWidget {
  const RaporScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(raporListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Rapor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(raporListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(raporListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada rapor', subtitle: 'Rapor di-generate oleh guru/wali kelas', icon: Icons.description_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Santri')), DataColumn(label: Text('NIS')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('TA')), DataColumn(label: Text('Semester')), DataColumn(label: Text('Published')), DataColumn(label: Text('Tanggal'))],
              rows: list.map((r) => DataRow(cells: [
                DataCell(Text(r.santriName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(r.santriNis, style: const TextStyle(fontSize: 12))),
                DataCell(Text(r.kelasName, style: const TextStyle(fontSize: 12))),
                DataCell(Text(r.tahunAjaranCode, style: const TextStyle(fontSize: 12))),
                DataCell(Text(r.semesterName, style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: r.published ? 'Published' : 'Draft', color: r.published ? AppColors.success : AppColors.warning, bg: r.published ? AppColors.successLight : AppColors.warningLight, compact: true)),
                DataCell(Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12))),
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
