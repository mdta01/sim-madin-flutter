// Kelas CRUD screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class KelasScreen extends ConsumerWidget {
  const KelasScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kelasListProvider);
    final guruAsync = ref.watch(guruListAdminProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Daftar Kelas',
          icon: Icons.class_outlined,
          subtitle: 'Kelola kelas & wali kelas',
          actions: [
            FilledButton.icon(onPressed: () => _showDialog(context, ref, guruAsync), icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Kelas')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(kelasListProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(kelasListProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada kelas', subtitle: 'Tambahkan kelas pertama Anda dengan tombol di atas.', icon: Icons.class_outlined, onRefresh: null) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
            columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Nama')), DataColumn(label: Text('Level')), DataColumn(label: Text('Kapasitas')), DataColumn(label: Text('Wali Kelas')), DataColumn(label: Text('Aktif')), DataColumn(label: Text('Actions'))],
            rows: list.map((k) => DataRow(cells: [
              DataCell(Text(k.code, style: AppTextStyles.body3.copyWith(fontFamily: AppFonts.mono))),
              DataCell(Text(k.name, style: AppTextStyles.label)),
              DataCell(Text(k.level, style: AppTextStyles.body3)),
              DataCell(Text('${k.capacity}', style: AppTextStyles.body3)),
              DataCell(Text(k.waliKelasName ?? '-', style: AppTextStyles.body3)),
              DataCell(Icon(k.isActive ? Icons.check_circle : Icons.cancel, size: 16, color: k.isActive ? AppColors.success : AppColors.danger)),
              DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(context, ref, guruAsync, kelas: k)), IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Kelas', message: 'Yakin hapus "${k.name}"?', destructive: true)) { try { await adminSoftDeleteKelas(ref, k.id); _toast(context, '✅ Kelas dihapus'); } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } } })])),
            ])).toList(),
            headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
          ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Future<void> _showDialog(BuildContext context, WidgetRef ref, AsyncValue<List<GuruModel>> guruAsync, {KelasModel? kelas}) async {
    final isEdit = kelas != null;
    final codeCtrl = TextEditingController(text: kelas?.code ?? '');
    final nameCtrl = TextEditingController(text: kelas?.name ?? '');
    final levelCtrl = TextEditingController(text: kelas?.level ?? '');
    final descCtrl = TextEditingController(text: kelas?.description ?? '');
    final capCtrl = TextEditingController(text: kelas != null ? '${kelas.capacity}' : '30');
    final sortCtrl = TextEditingController(text: kelas != null ? '${kelas.sortOrder}' : '0');
    String? waliKelasId = kelas?.waliKelasId;
    bool isActive = kelas?.isActive ?? true;
    bool saving = false;
    final guruList = guruAsync.maybeWhen(data: (l) => l, orElse: () => []);
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text(isEdit ? 'Edit Kelas' : 'Tambah Kelas'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: FormFieldLabel(label: 'Code', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Level', child: TextField(controller: levelCtrl, decoration: const InputDecoration(hintText: 'MDA-1, MDI-1', border: OutlineInputBorder(), isDense: true))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'Kapasitas', child: TextField(controller: capCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Sort Order', child: TextField(controller: sortCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number)))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Wali Kelas', child: DropdownButtonFormField<String>(value: waliKelasId, hint: const Text('Pilih Guru'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: guruList.map((g) => DropdownMenuItem<String>(value: g.id, child: Text(g.name))).toList(), onChanged: (v) => setInner(() => waliKelasId = v))),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Deskripsi (opsional)', child: TextField(controller: descCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
        const SizedBox(height: 8),
        SwitchListTile(title: const Text('Aktif'), value: isActive, onChanged: (v) => setInner(() => isActive = v), activeColor: AppColors.primary, dense: true),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) { _toast(context, 'Code dan Name wajib diisi', true); return; }
        setInner(() => saving = true);
        try {
          if (isEdit) { await adminUpdateKelas(ref, kelasId: kelas.id, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), level: levelCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), capacity: int.tryParse(capCtrl.text) ?? 30, sortOrder: int.tryParse(sortCtrl.text) ?? 0, isActive: isActive, waliKelasId: waliKelasId); }
          else { await adminCreateKelas(ref, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), level: levelCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), capacity: int.tryParse(capCtrl.text) ?? 30, sortOrder: int.tryParse(sortCtrl.text) ?? 0, waliKelasId: waliKelasId); }
          if (!context.mounted) return; Navigator.of(ctx).pop(); _toast(context, isEdit ? '✅ Kelas updated' : '✅ Kelas created');
        } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create'))],
    )));
  }
  void _toast(BuildContext context, String msg, [bool isError = false]) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
