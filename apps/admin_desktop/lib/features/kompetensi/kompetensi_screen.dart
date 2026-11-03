// Kompetensi — list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class KompetensiScreen extends ConsumerStatefulWidget {
  const KompetensiScreen({super.key});
  @override
  ConsumerState<KompetensiScreen> createState() => _KompetensiScreenState();
}
class _KompetensiScreenState extends ConsumerState<KompetensiScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(kompetensiListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Kompetensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('Tambah')),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(kompetensiListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(kompetensiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada kompetensi', icon: Icons.workspace_premium_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Nama')), DataColumn(label: Text('Kategori')), DataColumn(label: Text('Sort')), DataColumn(label: Text('Active')), DataColumn(label: Text('Actions'))],
              rows: list.map((k) => DataRow(cells: [
                DataCell(Text(k.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(k.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(StatusChip(label: k.category, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text('${k.sortOrder}', style: const TextStyle(fontSize: 12))),
                DataCell(Icon(k.isActive ? Icons.check_circle : Icons.cancel, size: 16, color: k.isActive ? AppColors.success : AppColors.danger)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteKompetensi(ref, k.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Future<void> _showCreateDialog(BuildContext context) async {
    final mapelList = await ref.read(mapelListProvider.future);
    final taList = await ref.read(tahunAjaranListProvider.future);
    if (!context.mounted) return;
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? mapelId, taId;
    String category = 'UMUM';
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: const Text('Tambah Kompetensi'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: FormFieldLabel(label: 'Code', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Kategori', child: DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: 'UMUM', child: Text('Umum')), DropdownMenuItem(value: 'KHUSUS', child: Text('Khusus'))], onChanged: (v) => setInner(() => category = v!))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Deskripsi (opsional)', child: TextField(controller: descCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'Mapel', child: DropdownButtonFormField<String>(value: mapelId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: mapelList.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(), onChanged: (v) => setInner(() => mapelId = v)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'TA', child: DropdownButtonFormField<String>(value: taId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: taList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setInner(() => taId = v))))]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || mapelId == null || taId == null) { _toast('Semua field wajib diisi', true); return; }
        setInner(() => saving = true);
        try { await adminCreateKompetensi(ref, mapelId: mapelId!, tahunAjaranId: taId!, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), category: category); if (!context.mounted) return; Navigator.of(ctx).pop(); _toast('✅ Kompetensi created'); }
        catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
