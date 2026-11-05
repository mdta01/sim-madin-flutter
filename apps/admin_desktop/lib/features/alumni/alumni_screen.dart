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
        AdminScreenHeader(
          title: 'Alumni',
          icon: Icons.school_outlined,
          subtitle: 'Database alumni madrasah',
          actions: [
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(alumniListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(alumniListAdminProvider)),
          data: (list) => list.isEmpty ? EmptyState(title: 'Belum ada alumni', subtitle: 'Data alumni akan muncul di sini setelah santri dinyatakan lulus.', icon: Icons.verified_outlined, onRefresh: () => ref.invalidate(alumniListAdminProvider)) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('NIS')), DataColumn(label: Text('Lulus')), DataColumn(label: Text('Status')), DataColumn(label: Text('Pekerjaan')), DataColumn(label: Text('Domisili')), DataColumn(label: Text('Actions'))],
              rows: list.map((a) => DataRow(cells: [
                DataCell(Text(a.santriName, style: AppTextStyles.label)),
                DataCell(Text(a.santriNis, style: AppTextStyles.body3)),
                DataCell(Text('${a.tahunLulus}', style: AppTextStyles.body3)),
                DataCell(StatusChip(label: a.statusKelulusan, color: AppColors.success, bg: AppColors.successLight, compact: true)),
                DataCell(Text(a.pekerjaan, style: AppTextStyles.body3)),
                DataCell(Text(a.domisiliKota, style: AppTextStyles.body3)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteAlumni(ref, a.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
