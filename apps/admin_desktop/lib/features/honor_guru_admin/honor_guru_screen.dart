// HonorGuru — list + filter + delete + generate bulk.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class HonorGuruScreen extends ConsumerStatefulWidget {
  const HonorGuruScreen({super.key});
  @override
  ConsumerState<HonorGuruScreen> createState() => _HonorGuruScreenState();
}
class _HonorGuruScreenState extends ConsumerState<HonorGuruScreen> {
  String _status = 'ALL';
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(honorGuruListAdminProvider(_status));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Honor Guru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SizedBox(width: 180, child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'ALL', child: Text('Semua')), DropdownMenuItem(value: HonorGuruStatus.draft, child: Text('Draft')), DropdownMenuItem(value: HonorGuruStatus.disetujui, child: Text('Disetujui')), DropdownMenuItem(value: HonorGuruStatus.dibayarkan, child: Text('Dibayarkan'))], onChanged: (v) => setState(() => _status = v ?? 'ALL'))),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showGenerateDialog(context, ref), icon: const Icon(Icons.auto_awesome), label: const Text('Generate Honor')),
          const SizedBox(width: AppSpacing.sm),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(honorGuruListAdminProvider)),
        ])),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(honorGuruListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada honor guru', icon: Icons.monetization_on_outlined) : Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Guru')), DataColumn(label: Text('Periode')), DataColumn(label: Text('Mengajar')), DataColumn(label: Text('Insentif')), DataColumn(label: Text('Tunjangan')), DataColumn(label: Text('Potongan')), DataColumn(label: Text('Total')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
              rows: list.map((h) {
                final total = h.totalHonor > 0 ? h.totalHonor : computeTotalHonor(h);
                return DataRow(cells: [
                  DataCell(Text(h.guruName ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  DataCell(Text(h.periodeLabel, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(h.honorMengajar), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(formatRupiah(h.insentif), style: const TextStyle(fontSize: 12, color: AppColors.success))),
                  DataCell(Text(formatRupiah(h.tunjangan), style: const TextStyle(fontSize: 12, color: AppColors.success))),
                  DataCell(Text(formatRupiah(h.potongan), style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                  DataCell(Text(formatRupiah(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  DataCell(StatusChip(label: HonorGuruStatus.label(h.status), color: h.status == HonorGuruStatus.dibayarkan ? AppColors.success : h.status == HonorGuruStatus.disetujui ? AppColors.info : AppColors.textMuted, bg: h.status == HonorGuruStatus.dibayarkan ? AppColors.successLight : h.status == HonorGuruStatus.disetujui ? AppColors.infoLight : const Color(0xFFF1F5F9), compact: true)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteHonorGuru(ref, h.id); })),
                ]);
              }).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 20,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }

  Future<void> _showGenerateDialog(BuildContext context, WidgetRef ref) async {
    final ta = await ref.read(tahunAjaranActiveProvider.future);
    final sem = await ref.read(semesterActiveProvider.future);
    if (!context.mounted) return;

    if (ta == null || sem == null) {
      _toast('Tahun Ajaran / Semester aktif belum diset. Aktifkan dulu di Settings.', true);
      return;
    }

    final now = DateTime.now();
    final periodeCtrl = TextEditingController(text: "${now.year}-${now.month.toString().padLeft(2, '0')}");
    final labelCtrl = TextEditingController(text: _defaultPeriodeLabel(now));
    final mengajarCtrl = TextEditingController(text: '500000');
    final insentifCtrl = TextEditingController(text: '100000');
    final tunjanganCtrl = TextEditingController(text: '50000');
    final potonganCtrl = TextEditingController(text: '0');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: const Text('Generate Honor Guru Bulk'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('TA: ${ta.code}  •  Semester: ${sem.name}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Periode (YYYY-MM)', child: TextField(controller: periodeCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: '2025-10')))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Periode Label', child: TextField(controller: labelCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: 'Oktober 2025')))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Honor Mengajar', child: TextField(controller: mengajarCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Insentif', child: TextField(controller: insentifCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Tunjangan', child: TextField(controller: tunjanganCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Potongan', child: TextField(controller: potonganCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: 'Rp '), keyboardType: TextInputType.number))),
          ]),
          const SizedBox(height: 8),
          const Text('Generate akan membuat honor DRAFT untuk semua guru AKTIF. Periode tidak boleh duplikat.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            final periode = periodeCtrl.text.trim();
            final label = labelCtrl.text.trim();
            if (periode.isEmpty || label.isEmpty) { _toast('Periode & Label wajib diisi', true); return; }
            final mengajar = double.tryParse(mengajarCtrl.text.trim()) ?? -1;
            final insentif = double.tryParse(insentifCtrl.text.trim()) ?? -1;
            final tunjangan = double.tryParse(tunjanganCtrl.text.trim()) ?? -1;
            final potongan = double.tryParse(potonganCtrl.text.trim()) ?? -1;
            if (mengajar < 0 || insentif < 0 || tunjangan < 0 || potongan < 0) { _toast('Nilai honor tidak valid', true); return; }
            setInner(() => saving = true);
            try {
              final count = await adminGenerateHonorGuruBulk(ref, tahunAjaranId: ta.id, semesterId: sem.id, periode: periode, periodeLabel: label, defaultHonorMengajar: mengajar, defaultInsentif: insentif, defaultTunjangan: tunjangan, defaultPotongan: potongan);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast('✅ $count honor guru di-generate');
            } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate')),
        ],
      )),
    );
  }

  String _defaultPeriodeLabel(DateTime now) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[now.month - 1]} ${now.year}';
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
