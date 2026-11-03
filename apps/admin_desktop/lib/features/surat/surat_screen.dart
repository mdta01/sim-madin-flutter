// Surat — read-only list + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class SuratScreen extends ConsumerWidget {
  const SuratScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suratListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Surat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(suratListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(suratListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada surat', icon: Icons.mail_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('No. Surat')), DataColumn(label: Text('Judul')), DataColumn(label: Text('Type')), DataColumn(label: Text('Santri')), DataColumn(label: Text('Status')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Actions'))],
              rows: list.map((s) => DataRow(cells: [
                DataCell(Text(s.nomorSurat, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(s.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(StatusChip(label: s.type, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(s.santriName, style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: s.status, color: s.status == 'SIGNED' ? AppColors.success : AppColors.warning, bg: s.status == 'SIGNED' ? AppColors.successLight : AppColors.warningLight, compact: true)),
                DataCell(Text(s.tanggalSurat != null ? formatDate(s.tanggalSurat) : '-', style: const TextStyle(fontSize: 12))),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteSurat(ref, s.id); })),
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
