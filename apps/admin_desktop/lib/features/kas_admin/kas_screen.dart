// Kas — list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class KasScreen extends ConsumerStatefulWidget {
  const KasScreen({super.key});
  @override
  ConsumerState<KasScreen> createState() => _KasScreenState();
}
class _KasScreenState extends ConsumerState<KasScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(kasListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Kas & Rekening', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add), label: const Text('Tambah Kas')),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(kasListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 4),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(kasListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada kas', icon: Icons.account_balance_wallet_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Code')), DataColumn(label: Text('Nama')), DataColumn(label: Text('Type')), DataColumn(label: Text('No. Rekening')), DataColumn(label: Text('Bank')), DataColumn(label: Text('Saldo')), DataColumn(label: Text('Actions'))],
              rows: list.map((k) => DataRow(cells: [
                DataCell(Text(k.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                DataCell(Text(k.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(StatusChip(label: KasType.label(k.type), color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(Text(k.accountNumber ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(k.bankName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(formatRupiah(k.balance), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteKas(ref, k.id); })),
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
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    String type = KasType.tunai;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: const Text('Tambah Kas'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: FormFieldLabel(label: 'Code', child: TextField(controller: codeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Type', child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: KasType.tunai, child: Text('Tunai')), DropdownMenuItem(value: KasType.bank, child: Text('Bank')), DropdownMenuItem(value: KasType.eWallet, child: Text('E-Wallet'))], onChanged: (v) => setInner(() => type = v!))))]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'No. Rekening (opsional)', child: TextField(controller: accCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Bank (opsional)', child: TextField(controller: bankCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))))]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) { _toast('Code dan Nama wajib diisi', true); return; }
        setInner(() => saving = true);
        try { await adminCreateKas(ref, code: codeCtrl.text.trim(), name: nameCtrl.text.trim(), type: type, accountNumber: accCtrl.text.trim().isEmpty ? null : accCtrl.text.trim(), bankName: bankCtrl.text.trim().isEmpty ? null : bankCtrl.text.trim()); if (!context.mounted) return; Navigator.of(ctx).pop(); _toast('✅ Kas created'); }
        catch (e) { _toast('Gagal: $e', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
