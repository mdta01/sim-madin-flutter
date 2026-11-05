// Tagihan — list + filter + delete + create/bulk/edit.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class TagihanScreen extends ConsumerStatefulWidget {
  const TagihanScreen({super.key});
  @override
  ConsumerState<TagihanScreen> createState() => _TagihanScreenState();
}
class _TagihanScreenState extends ConsumerState<TagihanScreen> {
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tagihanListAdminProvider(_status));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Tagihan SPP',
          icon: Icons.receipt_long_outlined,
          subtitle: 'Kelola tagihan & invoice',
          actions: [
            SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: TagihanStatus.belumBayar, child: Text('Belum Bayar')), DropdownMenuItem(value: TagihanStatus.cicil, child: Text('Cicil')), DropdownMenuItem(value: TagihanStatus.lunas, child: Text('Lunas'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(onPressed: () => _showCreateDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Tambah Tagihan')),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(onPressed: () => _showBulkDialog(context, ref), icon: const Icon(Icons.auto_awesome), label: const Text('Generate Bulk')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(tagihanListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 10),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(tagihanListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Tidak ada tagihan', subtitle: 'Tambahkan tagihan pertama Anda dengan tombol di atas.', icon: Icons.receipt_long_outlined, onRefresh: null) : ModernDataTableContainer(
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Santri')), DataColumn(label: Text('Jenis')), DataColumn(label: Text('Total')), DataColumn(label: Text('Dibayar')), DataColumn(label: Text('Sisa')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((t) {
                final outstanding = tagihanOutstanding(t);
                return DataRow(cells: [
                  DataCell(Text(t.santriName ?? '-', style: AppTextStyles.label)),
                  DataCell(Text(t.jenisTagihanName ?? t.jenisTagihanCode ?? '-', style: AppTextStyles.body3)),
                  DataCell(Text(formatRupiah(t.amount), style: AppTextStyles.body3)),
                  DataCell(Text(formatRupiah(t.paidAmount), style: AppTextStyles.body3.copyWith(color: AppColors.success))),
                  DataCell(Text(formatRupiah(outstanding), style: AppTextStyles.body3.copyWith(color: outstanding > 0 ? AppColors.danger : AppColors.success))),
                  DataCell(StatusChip(label: t.status == TagihanStatus.lunas ? 'Lunas' : t.status == TagihanStatus.cicil ? 'Cicil' : 'Belum', color: t.status == TagihanStatus.lunas ? AppColors.success : t.status == TagihanStatus.cicil ? AppColors.warning : AppColors.danger, bg: t.status == TagihanStatus.lunas ? AppColors.successLight : t.status == TagihanStatus.cicil ? AppColors.warningLight : AppColors.dangerLight, compact: true)),
                  DataCell(Row(children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), tooltip: 'Edit', onPressed: () => _showCreateDialog(context, ref, tagihan: t)),
                    IconButton(icon: const Icon(Icons.delete, size: 18), tooltip: 'Hapus', color: AppColors.danger, onPressed: () async { await adminDeleteTagihan(ref, t.id); }),
                  ])),
                ]);
              }).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref, {TagihanModel? tagihan}) async {
    final isEdit = tagihan != null;
    final santriList = await ref.read(santriListProvider.future);
    final jenisList = await ref.read(jenisTagihanListProvider.future);
    if (!context.mounted) return;

    final amountCtrl = TextEditingController(text: tagihan != null ? tagihan.amount.toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: tagihan?.description ?? '');
    String? santriId = tagihan?.santriId;
    String? jenisTagihanId = tagihan?.jenisTagihanId;
    DateTime? dueDate = tagihan?.dueDate;
    bool saving = false;
    // Defensive: kalau FK tidak ada di list (sudah dihapus), reset value supaya tidak crash assertion.
    final santriInList = santriList.any((s) => s.id == santriId);
    final jenisInList = jenisList.any((j) => j.id == jenisTagihanId);
    final santriValue = santriInList ? santriId : null;
    final jenisValue = jenisInList ? jenisTagihanId : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: Text(isEdit ? 'Edit Tagihan' : 'Tambah Tagihan'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          FormFieldLabel(label: 'Santri', child: DropdownButtonFormField<String>(value: santriValue, hint: const Text('Pilih Santri'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: santriList.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.nis})'))).toList(), onChanged: isEdit ? null : (v) => setInner(() => santriId = v), disabledHint: isEdit ? Text(tagihan.santriName ?? (santriInList ? santriList.firstWhere((s) => s.id == santriId).name : '-')) : null)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Jenis Tagihan', child: DropdownButtonFormField<String>(value: jenisValue, hint: const Text('Pilih Jenis Tagihan'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: jenisList.map((j) => DropdownMenuItem(value: j.id, child: Text('${j.name} (${j.code})'))).toList(), onChanged: isEdit ? null : (v) => setInner(() { jenisTagihanId = v; final sel = jenisList.firstWhere((j) => j.id == v); if (amountCtrl.text.isEmpty && sel.defaultAmount > 0) amountCtrl.text = sel.defaultAmount.toString(); }), disabledHint: isEdit ? Text(tagihan.jenisTagihanName ?? (jenisInList ? jenisList.firstWhere((j) => j.id == jenisTagihanId).name : '-')) : null)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Amount (Rp)', child: TextField(controller: amountCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Deskripsi (opsional)', child: TextField(controller: descCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Jatuh Tempo (opsional)', child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 2))); if (d != null) setInner(() => dueDate = d); }, icon: const Icon(Icons.calendar_today, size: 16), label: Text(dueDate != null ? formatDate(dueDate) : 'Pilih Tanggal'))),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (!isEdit && santriId == null) { _toast('Santri wajib dipilih', true); return; }
            if (!isEdit && jenisTagihanId == null) { _toast('Jenis Tagihan wajib dipilih', true); return; }
            if (amt <= 0) { _toast('Amount harus > 0', true); return; }
            setInner(() => saving = true);
            try {
              if (isEdit) {
                await adminUpdateTagihan(ref, tagihanId: tagihan.id, amount: amt, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), dueDate: dueDate);
              } else {
                await adminCreateTagihan(ref, santriId: santriId!, jenisTagihanId: jenisTagihanId!, amount: amt, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), dueDate: dueDate);
              }
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast(isEdit ? '✅ Tagihan updated' : '✅ Tagihan created');
            } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create')),
        ],
      )),
    );
  }

  Future<void> _showBulkDialog(BuildContext context, WidgetRef ref) async {
    final kelasList = await ref.read(kelasListProvider.future);
    final jenisList = await ref.read(jenisTagihanListProvider.future);
    if (!context.mounted) return;

    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? kelasId;
    String? jenisTagihanId;
    DateTime? dueDate;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: const Text('Generate Tagihan Bulk per Kelas'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Generate tagihan untuk semua santri AKTIF di kelas terpilih.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          FormFieldLabel(label: 'Kelas', child: DropdownButtonFormField<String>(value: kelasId, hint: const Text('Pilih Kelas'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: kelasList.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name))).toList(), onChanged: (v) => setInner(() => kelasId = v))),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Jenis Tagihan', child: DropdownButtonFormField<String>(value: jenisTagihanId, hint: const Text('Pilih Jenis Tagihan'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: jenisList.map((j) => DropdownMenuItem(value: j.id, child: Text('${j.name} (${j.code})'))).toList(), onChanged: (v) => setInner(() { jenisTagihanId = v; final sel = jenisList.firstWhere((j) => j.id == v); if (amountCtrl.text.isEmpty && sel.defaultAmount > 0) amountCtrl.text = sel.defaultAmount.toString(); }))),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Amount (Rp)', child: TextField(controller: amountCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Deskripsi', child: TextField(controller: descCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Jatuh Tempo', child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 2))); if (d != null) setInner(() => dueDate = d); }, icon: const Icon(Icons.calendar_today, size: 16), label: Text(dueDate != null ? formatDate(dueDate) : 'Pilih Tanggal'))),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
            if (kelasId == null) { _toast('Kelas wajib dipilih', true); return; }
            if (jenisTagihanId == null) { _toast('Jenis Tagihan wajib dipilih', true); return; }
            if (amt <= 0) { _toast('Amount harus > 0', true); return; }
            setInner(() => saving = true);
            try {
              final count = await adminCreateTagihanBulk(ref, kelasId: kelasId!, jenisTagihanId: jenisTagihanId!, amount: amt, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(), dueDate: dueDate);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast('✅ $count tagihan di-generate');
            } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate')),
        ],
      )),
    );
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
