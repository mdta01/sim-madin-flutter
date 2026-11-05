// Materi — read-only list + delete (soft).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class MateriScreen extends ConsumerWidget {
  const MateriScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materiListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Materi Pelajaran',
          icon: Icons.menu_book_outlined,
          subtitle: 'Kelola materi & dokumen',
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(materiListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(materiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada materi', subtitle: 'Belum ada materi tersedia.', icon: Icons.book_outlined) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Judul')), DataColumn(label: Text('Type')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Published')), DataColumn(label: Text('Actions'))],
              rows: list.map((m) => DataRow(cells: [
                DataCell(Text(m.title, style: AppTextStyles.label)),
                DataCell(StatusChip(label: MateriType.label(m.type), color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(m.mapelName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(m.kelasName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(m.guruName ?? '-', style: AppTextStyles.body3)),
                DataCell(Icon(m.isPublished ? Icons.check_circle : Icons.drafts, size: 16, color: m.isPublished ? AppColors.success : AppColors.textMuted)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteMateri(ref, m.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
