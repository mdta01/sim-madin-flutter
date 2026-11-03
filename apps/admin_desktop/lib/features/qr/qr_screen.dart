// QR — read-only list of scans.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class QRScreen extends ConsumerWidget {
  const QRScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(qrScanListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('QR Scan Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(qrScanListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(qrScanListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada QR scan', icon: Icons.qr_code) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('QR Type')), DataColumn(label: Text('Scan Type')), DataColumn(label: Text('Result')), DataColumn(label: Text('Message')), DataColumn(label: Text('Tanggal'))],
              rows: list.map((q) => DataRow(cells: [
                DataCell(StatusChip(label: q.qrType, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(q.scanType, style: const TextStyle(fontSize: 12))),
                DataCell(StatusChip(label: q.result, color: q.result == 'SUCCESS' ? AppColors.success : AppColors.danger, bg: q.result == 'SUCCESS' ? AppColors.successLight : AppColors.dangerLight, compact: true)),
                DataCell(Text(q.message ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(formatDateTime(q.createdAt), style: const TextStyle(fontSize: 12))),
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
