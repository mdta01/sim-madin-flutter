// Tagihan — list + filter + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class TagihanScreen extends ConsumerStatefulWidget {
  const TagihanScreen({super.key});
  @override
  ConsumerState<TagihanScreen> createState() => _TagihanScreenState();
}
class _TagihanScreenState extends ConsumerState<TagihanScreen> {
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tagihanListAdminProvider(_status));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Tagihan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: TagihanStatus.belumBayar, child: Text('Belum Bayar')), DropdownMenuItem(value: TagihanStatus.cicil, child: Text('Cicil')), DropdownMenuItem(value: TagihanStatus.lunas, child: Text('Lunas'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(tagihanListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(tagihanListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Tidak ada tagihan', icon: Icons.receipt_long_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Santri')), DataColumn(label: Text('Jenis')), DataColumn(label: Text('Total')), DataColumn(label: Text('Dibayar')), DataColumn(label: Text('Sisa')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((t) {
                final outstanding = tagihanOutstanding(t);
                return DataRow(cells: [
                  DataCell(Text(t.santriName ?? '-', style: const TextStyle(fontSize: 13))),
                  DataCell(Text(t.jenisTagihanName ?? t.jenisTagihanCode ?? '-', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(t.amount), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(t.paidAmount), style: const TextStyle(fontSize: 12, color: AppColors.success))),
                  DataCell(Text(formatRupiah(outstanding), style: TextStyle(fontSize: 12, color: outstanding > 0 ? AppColors.danger : AppColors.success))),
                  DataCell(StatusChip(label: t.status == TagihanStatus.lunas ? 'Lunas' : t.status == TagihanStatus.cicil ? 'Cicil' : 'Belum', color: t.status == TagihanStatus.lunas ? AppColors.success : t.status == TagihanStatus.cicil ? AppColors.warning : AppColors.danger, bg: t.status == TagihanStatus.lunas ? AppColors.successLight : t.status == TagihanStatus.cicil ? AppColors.warningLight : AppColors.dangerLight, compact: true)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteTagihan(ref, t.id); })),
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
