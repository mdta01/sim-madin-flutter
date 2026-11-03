// AuditLog — read-only list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Audit Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(auditLogListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(auditLogListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada audit log', icon: Icons.history) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Action')), DataColumn(label: Text('Entity')), DataColumn(label: Text('Entity ID')), DataColumn(label: Text('Details')), DataColumn(label: Text('User ID')), DataColumn(label: Text('Tanggal'))],
              rows: list.map((l) => DataRow(cells: [
                DataCell(StatusChip(label: l.action, color: l.action == 'CREATE' ? AppColors.success : l.action == 'UPDATE' ? AppColors.warning : l.action == 'DELETE' ? AppColors.danger : AppColors.info, bg: l.action == 'CREATE' ? AppColors.successLight : l.action == 'UPDATE' ? AppColors.warningLight : l.action == 'DELETE' ? AppColors.dangerLight : AppColors.infoLight, compact: true)),
                DataCell(Text(l.entity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(l.entityId ?? '-', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                DataCell(Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3), child: Text(l.details ?? '-', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis))),
                DataCell(Text(l.userId?.substring(0, 8) ?? '-', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted))),
                DataCell(Text(formatDateTime(l.createdAt), style: const TextStyle(fontSize: 12))),
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
