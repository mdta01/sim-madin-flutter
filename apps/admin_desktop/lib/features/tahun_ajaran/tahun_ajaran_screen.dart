// TahunAjaran CRUD screen — DataTable + create/edit + activate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class TahunAjaranScreen extends ConsumerWidget {
  const TahunAjaranScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tahunAjaranListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Tahun Ajaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Tambah TA')),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(tahunAjaranListProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 4),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(tahunAjaranListProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada tahun ajaran', icon: Icons.date_range) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Nama')), DataColumn(label: Text('Mulai')), DataColumn(label: Text('Selesai')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((ta) => DataRow(cells: [
                DataCell(Text(ta.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(ta.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(formatDate(ta.startDate), style: const TextStyle(fontSize: 12))),
                DataCell(Text(formatDate(ta.endDate), style: const TextStyle(fontSize: 12))),
                DataCell(ta.isActive ? const StatusChip(label: 'AKTIF', color: AppColors.success, bg: AppColors.successLight, compact: true) : const StatusChip(label: 'Nonaktif', color: AppColors.textMuted, bg: Color(0xFFF1F5F9), compact: true)),
                DataCell(Row(children: [
                  if (!ta.isActive) IconButton(icon: const Icon(Icons.check_circle, size: 18), color: AppColors.success, tooltip: 'Aktifkan', onPressed: () async { try { await adminActivateTahunAjaran(ref, ta.id); _toast(context, '✅ Tahun ajaran diaktifkan'); } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } }),
                  IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(context, ref, ta: ta)),
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
  Future<void> _showDialog(BuildContext context, WidgetRef ref, {TahunAjaranModel? ta}) async {
    final isEdit = ta != null;
    final codeCtrl = TextEditingController(text: ta?.code ?? '');
    final nameCtrl = TextEditingController(text: ta?.name ?? '');
    DateTime? startDate = ta?.startDate;
    DateTime? endDate = ta?.endDate;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text(isEdit ? 'Edit Tahun Ajaran' : 'Tambah Tahun Ajaran'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldLabel(label: 'Code', hint: 'cth: 2025/2026', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Nama', hint: 'cth: Tahun Ajaran 2025/2026', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Mulai', child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setInner(() => startDate = d); }, icon: const Icon(Icons.calendar_today, size: 16), label: Text(startDate != null ? formatDate(startDate) : 'Pilih')))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Selesai', child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setInner(() => endDate = d); }, icon: const Icon(Icons.calendar_today, size: 16), label: Text(endDate != null ? formatDate(endDate) : 'Pilih')))),
        ]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || startDate == null || endDate == null) { _toast(context, 'Semua field wajib diisi', true); return; }
        setInner(() => saving = true);
        try {
          if (isEdit) { await adminUpdateTahunAjaran(ref, taId: ta.id, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), startDate: startDate, endDate: endDate); }
          else { await adminCreateTahunAjaran(ref, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), startDate: startDate!, endDate: endDate!); }
          if (!context.mounted) return; Navigator.of(ctx).pop(); _toast(context, isEdit ? '✅ TA updated' : '✅ TA created');
        } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create'))],
    )));
  }
  void _toast(BuildContext context, String msg, [bool isError = false]) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
