// HonorGuru — list + filter + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class HonorGuruScreen extends ConsumerStatefulWidget {
  const HonorGuruScreen({super.key});
  @override
  ConsumerState<HonorGuruScreen> createState() => _HonorGuruScreenState();
}
class _HonorGuruScreenState extends ConsumerState<HonorGuruScreen> {
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(honorGuruListAdminProvider(_status));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Honor Guru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: HonorGuruStatus.draft, child: Text('Draft')), DropdownMenuItem(value: HonorGuruStatus.disetujui, child: Text('Disetujui')), DropdownMenuItem(value: HonorGuruStatus.dibayarkan, child: Text('Dibayarkan'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(honorGuruListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(honorGuruListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada honor guru', icon: Icons.monetization_on_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Guru')), DataColumn(label: Text('Periode')), DataColumn(label: Text('Mengajar')), DataColumn(label: Text('Insentif')), DataColumn(label: Text('Tunjangan')), DataColumn(label: Text('Potongan')), DataColumn(label: Text('Total')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((h) {
                final total = h.totalHonor > 0 ? h.totalHonor : computeTotalHonor(h);
                return DataRow(cells: [
                  DataCell(Text(h.guruName ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  DataCell(Text(h.periodeLabel, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(h.honorMengajar), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(h.insentif), style: const TextStyle(fontSize: 12, color: AppColors.success))),
                  DataCell(Text(formatRupiah(h.tunjangan), style: const TextStyle(fontSize: 12, color: AppColors.success))),
                  DataCell(Text(formatRupiah(h.potongan), style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                  DataCell(Text(formatRupiah(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  DataCell(StatusChip(label: HonorGuruStatus.label(h.status), color: h.status == HonorGuruStatus.dibayarkan ? AppColors.success : h.status == HonorGuruStatus.disetujui ? AppColors.info : AppColors.textMuted, bg: h.status == HonorGuruStatus.dibayarkan ? AppColors.successLight : h.status == HonorGuruStatus.disetujui ? AppColors.infoLight : const Color(0xFFF1F5F9), compact: true)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteHonorGuru(ref, h.id); })),
                ]);
              }).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 20,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
}
