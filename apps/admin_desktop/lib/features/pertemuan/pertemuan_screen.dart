// Pertemuan — read-only list + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class PertemuanScreen extends ConsumerWidget {
  const PertemuanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pertemuanListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Pertemuan Kelas',
          icon: Icons.event_outlined,
          subtitle: 'Jadwal pertemuan kelas',
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(pertemuanListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(pertemuanListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada pertemuan', subtitle: 'Belum ada pertemuan terjadwal.', icon: Icons.event_outlined) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Topik')), DataColumn(label: Text('Selesai')), DataColumn(label: Text('Actions'))],
              rows: list.map((p) => DataRow(cells: [
                DataCell(Text('${p.pertemuanKe}', style: AppTextStyles.body3.copyWith(fontWeight: FontWeight.bold))),
                DataCell(Text(formatDate(p.date), style: AppTextStyles.body3)),
                DataCell(Text(p.mapelName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(p.kelasName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(p.guruName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(p.topic ?? '-', style: AppTextStyles.body3),),
                DataCell(Icon(p.isCompleted ? Icons.check_circle : Icons.pending, size: 16, color: p.isCompleted ? AppColors.success : AppColors.warning)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeletePertemuan(ref, p.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
