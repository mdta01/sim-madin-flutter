// BankSoal — list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class BankSoalScreen extends ConsumerStatefulWidget {
  const BankSoalScreen({super.key});
  @override
  ConsumerState<BankSoalScreen> createState() => _BankSoalScreenState();
}
class _BankSoalScreenState extends ConsumerState<BankSoalScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bankSoalListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Bank Soal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('Tambah Soal')),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(bankSoalListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(bankSoalListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada soal', icon: Icons.question_answer_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Type')), DataColumn(label: Text('Question')), DataColumn(label: Text('Bobot')), DataColumn(label: Text('Active')), DataColumn(label: Text('Actions'))],
              rows: list.map((s) => DataRow(cells: [
                DataCell(Text(s.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(StatusChip(label: s.type, color: s.type == SoalType.pg ? AppColors.info : s.type == SoalType.isian ? AppColors.warning : AppColors.danger, bg: s.type == SoalType.pg ? AppColors.infoLight : s.type == SoalType.isian ? AppColors.warningLight : AppColors.dangerLight, compact: true)),
                DataCell(Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4), child: Text(s.question, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis))),
                DataCell(Text(s.bobot.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                DataCell(Icon(s.isActive ? Icons.check_circle : Icons.cancel, size: 16, color: s.isActive ? AppColors.success : AppColors.danger)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteBankSoal(ref, s.id); })),
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
    final guruList = await ref.read(guruListAdminProvider(null).future);
    final taList = await ref.read(tahunAjaranListProvider.future);
    if (!context.mounted) return;
    final codeCtrl = TextEditingController();
    final qCtrl = TextEditingController();
    final optCtrl = TextEditingController();
    final ansCtrl = TextEditingController();
    String? mapelId, guruId, taId;
    String type = SoalType.pg;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: const Text('Tambah Soal'),
      content: SizedBox(width: 550, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: FormFieldLabel(label: 'Code', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Type', child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: SoalType.pg, child: Text('PG')), DropdownMenuItem(value: SoalType.isian, child: Text('Isian')), DropdownMenuItem(value: SoalType.essay, child: Text('Essay'))], onChanged: (v) => setInner(() => type = v!))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Pertanyaan', child: TextField(controller: qCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 3)),
        const SizedBox(height: 8),
        if (type == SoalType.pg) ...[
          FormFieldLabel(label: 'Options (JSON array)', hint: '["opsi A","opsi B","opsi C","opsi D"]', child: TextField(controller: optCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Jawaban Benar (A/B/C/D)', child: TextField(controller: ansCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          const SizedBox(height: 8),
        ],
        Row(children: [Expanded(child: FormFieldLabel(label: 'Mapel', child: DropdownButtonFormField<String>(value: mapelId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: mapelList.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(), onChanged: (v) => setInner(() => mapelId = v)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Guru', child: DropdownButtonFormField<String>(value: guruId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: guruList.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(), onChanged: (v) => setInner(() => guruId = v))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Tahun Ajaran', child: DropdownButtonFormField<String>(value: taId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: taList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setInner(() => taId = v))),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || qCtrl.text.trim().isEmpty || mapelId == null || guruId == null || taId == null) { _toast('Semua field wajib diisi', true); return; }
        setInner(() => saving = true);
        try { await adminCreateBankSoal(ref, mapelId: mapelId!, tahunAjaranId: taId!, guruId: guruId!, code: codeCtrl.text.trim(), type: type, question: qCtrl.text.trim(), options: optCtrl.text.trim().isEmpty ? null : optCtrl.text.trim(), correctAnswer: ansCtrl.text.trim().isEmpty ? null : ansCtrl.text.trim().toUpperCase()); if (!context.mounted) return; Navigator.of(ctx).pop(); _toast('✅ Soal created'); }
        catch (e) { _toast('Gagal: $e', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
