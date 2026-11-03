// Mapel CRUD screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class MapelScreen extends ConsumerWidget {
  const MapelScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mapelListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Mata Pelajaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Tambah Mapel')),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(mapelListProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(mapelListProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada mapel', icon: Icons.book_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Nama')), DataColumn(label: Text('Kategori')), DataColumn(label: Text('KKM')), DataColumn(label: Text('Durasi')), DataColumn(label: Text('Aktif')), DataColumn(label: Text('Actions'))],
              rows: list.map((m) => DataRow(cells: [
                DataCell(Text(m.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(StatusChip(label: m.category, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(m.kkm.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                DataCell(Text('${m.durationMnt} mnt', style: const TextStyle(fontSize: 12))),
                DataCell(Icon(m.isActive ? Icons.check_circle : Icons.cancel, size: 16, color: m.isActive ? AppColors.success : AppColors.danger)),
                DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(context, ref, mapel: m)), IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Mapel', message: 'Yakin hapus "${m.name}"?', destructive: true)) { try { await adminSoftDeleteMapel(ref, m.id); _toast(context, '✅ Mapel dihapus'); } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } } })])),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Future<void> _showDialog(BuildContext context, WidgetRef ref, {MataPelajaranModel? mapel}) async {
    final isEdit = mapel != null;
    final codeCtrl = TextEditingController(text: mapel?.code ?? '');
    final nameCtrl = TextEditingController(text: mapel?.name ?? '');
    final descCtrl = TextEditingController(text: mapel?.description ?? '');
    final kkmCtrl = TextEditingController(text: mapel != null ? mapel.kkm.toStringAsFixed(0) : '70');
    final durCtrl = TextEditingController(text: mapel != null ? '${mapel.durationMnt}' : '90');
    final sortCtrl = TextEditingController(text: mapel != null ? '${mapel.sortOrder}' : '0');
    String category = mapel?.category ?? MapelCategory.diniyah;
    bool isActive = mapel?.isActive ?? true;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text(isEdit ? 'Edit Mapel' : 'Tambah Mapel'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: FormFieldLabel(label: 'Code', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Kategori', child: DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: MapelCategory.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setInner(() => category = v!))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'KKM', child: TextField(controller: kkmCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Durasi (mnt)', child: TextField(controller: durCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number)))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Deskripsi (opsional)', child: TextField(controller: descCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'Sort Order', child: TextField(controller: sortCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number))), const SizedBox(width: 8), Expanded(child: SwitchListTile(title: const Text('Aktif'), value: isActive, onChanged: (v) => setInner(() => isActive = v), activeColor: AppColors.primary, dense: true))]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) { _toast(context, 'Code dan Name wajib diisi', true); return; }
        setInner(() => saving = true);
        try {
          if (isEdit) { await adminUpdateMapel(ref, mapelId: mapel.id, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), category: category, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), kkm: double.tryParse(kkmCtrl.text) ?? 70, durationMnt: int.tryParse(durCtrl.text) ?? 90, sortOrder: int.tryParse(sortCtrl.text) ?? 0, isActive: isActive); }
          else { await adminCreateMapel(ref, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), category: category, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), kkm: double.tryParse(kkmCtrl.text) ?? 70, durationMnt: int.tryParse(durCtrl.text) ?? 90, sortOrder: int.tryParse(sortCtrl.text) ?? 0); }
          if (!context.mounted) return; Navigator.of(ctx).pop(); _toast(context, isEdit ? '✅ Mapel updated' : '✅ Mapel created');
        } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create'))],
    )));
  }
  void _toast(BuildContext context, String msg, [bool isError = false]) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
