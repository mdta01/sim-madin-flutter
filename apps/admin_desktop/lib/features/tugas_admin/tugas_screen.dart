// Tugas — read-only list + delete (soft).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class TugasScreen extends ConsumerWidget {
  const TugasScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tugasListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Tugas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(tugasListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(tugasListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada tugas', icon: Icons.assignment_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Judul')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Tenggat')), DataColumn(label: Text('Published')), DataColumn(label: Text('Actions'))],
              rows: list.map((t) => DataRow(cells: [
                DataCell(Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(t.mapelName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(t.kelasName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(t.guruName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(t.dueDate != null ? formatDate(t.dueDate) : '-', style: TextStyle(fontSize: 12, color: t.dueDate != null && t.dueDate!.isBefore(DateTime.now()) ? AppColors.danger : AppColors.textMuted))),
                DataCell(Icon(t.isPublished ? Icons.check_circle : Icons.drafts, size: 16, color: t.isPublished ? AppColors.success : AppColors.textMuted)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteTugas(ref, t.id); })),
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
