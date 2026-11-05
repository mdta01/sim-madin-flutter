// Ujian — list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class UjianScreen extends ConsumerStatefulWidget {
  const UjianScreen({super.key});
  @override
  ConsumerState<UjianScreen> createState() => _UjianScreenState();
}
class _UjianScreenState extends ConsumerState<UjianScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ujianListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Bank Ujian',
          icon: Icons.quiz_outlined,
          subtitle: 'Kelola ujian & soal',
          actions: [
            FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Ujian')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(ujianListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(ujianListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada ujian', subtitle: 'Tambahkan ujian pertama Anda dengan tombol di atas.', icon: Icons.quiz_outlined, onRefresh: null) : ModernDataTableContainer(
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Judul')), DataColumn(label: Text('Type')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Mulai')), DataColumn(label: Text('Published')), DataColumn(label: Text('Actions'))],
              rows: list.map((u) => DataRow(cells: [
                DataCell(Text(u.title, style: AppTextStyles.label)),
                DataCell(StatusChip(label: u.type, color: u.type == UjianType.uas ? AppColors.danger : u.type == UjianType.uts ? AppColors.warning : AppColors.info, bg: u.type == UjianType.uas ? AppColors.dangerLight : u.type == UjianType.uts ? AppColors.warningLight : AppColors.infoLight, compact: true)),
                DataCell(Text(u.mapelName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(u.kelasName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(u.guruName ?? '-', style: AppTextStyles.body3)),
                DataCell(Text(u.startTime != null ? formatDateTime(u.startTime) : '-', style: AppTextStyles.body3)),
                DataCell(Icon(u.isPublished ? Icons.check_circle : Icons.drafts, size: 16, color: u.isPublished ? AppColors.success : AppColors.textMuted)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Ujian', message: 'Yakin hapus "${u.title}"?', destructive: true)) { await adminDeleteUjian(ref, u.id); _toast('✅ Ujian dihapus'); } })),
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
    final kelasList = await ref.read(kelasListProvider.future);
    final mapelList = await ref.read(mapelListProvider.future);
    final guruList = await ref.read(guruListAdminProvider(null).future);
    final taList = await ref.read(tahunAjaranListProvider.future);
    if (!context.mounted) return;
    final titleCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '90');
    String? kelasId, mapelId, guruId, taId;
    String type = UjianType.uts;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: const Text('Tambah Ujian'),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldLabel(label: 'Judul', child: TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Type', child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: UjianType.uts, child: Text('UTS')), DropdownMenuItem(value: UjianType.uas, child: Text('UAS')), DropdownMenuItem(value: UjianType.quiz, child: Text('Quiz'))], onChanged: (v) => setInner(() => type = v!)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Durasi (mnt)', child: TextField(controller: durCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'TA', child: DropdownButtonFormField<String>(value: taId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: taList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setInner(() => taId = v)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Kelas', child: DropdownButtonFormField<String>(value: kelasId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: kelasList.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name))).toList(), onChanged: (v) => setInner(() => kelasId = v)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Mapel', child: DropdownButtonFormField<String>(value: mapelId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: mapelList.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(), onChanged: (v) => setInner(() => mapelId = v)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Guru', child: DropdownButtonFormField<String>(value: guruId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: guruList.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(), onChanged: (v) => setInner(() => guruId = v)))),
        ]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (titleCtrl.text.trim().isEmpty || kelasId == null || mapelId == null || guruId == null || taId == null) { _toast('Semua field wajib diisi', true); return; }
        setInner(() => saving = true);
        try {
          final semList = await ref.read(semesterListProvider(taId).future);
          await adminCreateUjian(ref, tahunAjaranId: taId!, semesterId: semList.first.id, mapelId: mapelId!, kelasId: kelasId!, guruId: guruId!, title: titleCtrl.text.trim(), type: type, durationMnt: int.tryParse(durCtrl.text) ?? 90);
          if (!context.mounted) return; Navigator.of(ctx).pop(); _toast('✅ Ujian created');
        } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
