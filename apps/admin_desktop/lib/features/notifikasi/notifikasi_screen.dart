// Notifikasi — read-only list + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifikasiListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(notifikasiListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(notifikasiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada notifikasi', icon: Icons.notifications_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Wali')), DataColumn(label: Text('Title')), DataColumn(label: Text('Type')), DataColumn(label: Text('Priority')), DataColumn(label: Text('Read')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Actions'))],
              rows: list.map((n) => DataRow(cells: [
                DataCell(Text(n.waliName, style: const TextStyle(fontSize: 12))),
                DataCell(Text(n.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(StatusChip(label: n.type, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(StatusChip(label: n.priority, color: n.priority == 'URGENT' ? AppColors.danger : n.priority == 'PENTING' ? AppColors.warning : AppColors.textMuted, bg: n.priority == 'URGENT' ? AppColors.dangerLight : n.priority == 'PENTING' ? AppColors.warningLight : const Color(0xFFF1F5F9), compact: true)),
                DataCell(Icon(n.isRead ? Icons.check_circle : Icons.circle_outlined, size: 16, color: n.isRead ? AppColors.success : AppColors.warning)),
                DataCell(Text(formatDateTime(n.createdAt), style: const TextStyle(fontSize: 12))),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteNotifikasi(ref, n.id); })),
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
