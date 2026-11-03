// Pembayaran — list + filter + verify/reject + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class PembayaranScreen extends ConsumerStatefulWidget {
  const PembayaranScreen({super.key});
  @override
  ConsumerState<PembayaranScreen> createState() => _PembayaranScreenState();
}
class _PembayaranScreenState extends ConsumerState<PembayaranScreen> {
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pembayaranListAdminProvider(_status));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pending')), DropdownMenuItem(value: PaymentStatus.verified, child: Text('Verified')), DropdownMenuItem(value: PaymentStatus.rejected, child: Text('Rejected'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(pembayaranListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(pembayaranListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Tidak ada pembayaran', icon: Icons.payment_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Invoice')), DataColumn(label: Text('Santri')), DataColumn(label: Text('Amount')), DataColumn(label: Text('Metode')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((p) => DataRow(cells: [
                DataCell(Text(p.invoiceNo, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(p.santriName ?? '-', style: const TextStyle(fontSize: 13))),
                DataCell(Text(formatRupiah(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success))),
                DataCell(Text(PaymentMethod.label(p.paymentMethod), style: const TextStyle(fontSize: 12))),
                DataCell(Text(formatDateTime(p.paymentDate), style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: p.status == PaymentStatus.verified ? 'Verified' : p.status == PaymentStatus.pending ? 'Pending' : 'Rejected', color: p.status == PaymentStatus.verified ? AppColors.success : p.status == PaymentStatus.pending ? AppColors.warning : AppColors.danger, bg: p.status == PaymentStatus.verified ? AppColors.successLight : p.status == PaymentStatus.pending ? AppColors.warningLight : AppColors.dangerLight, compact: true)),
                DataCell(Row(children: [
                  if (p.status == PaymentStatus.pending) ...[
                    IconButton(icon: const Icon(Icons.check, size: 18), color: AppColors.success, tooltip: 'Verify', onPressed: () async { await adminVerifyPayment(ref, p.id); }),
                    IconButton(icon: const Icon(Icons.close, size: 18), color: AppColors.danger, tooltip: 'Reject', onPressed: () async { await adminRejectPayment(ref, p.id); }),
                  ],
                  IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeletePayment(ref, p.id); }),
                ])),
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
