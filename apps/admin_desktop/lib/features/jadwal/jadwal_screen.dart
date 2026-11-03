// Jadwal CRUD — DataTable + create dialog + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class JadwalScreen extends ConsumerStatefulWidget {
  const JadwalScreen({super.key});
  @override
  ConsumerState<JadwalScreen> createState() => _JadwalScreenState();
}
class _JadwalScreenState extends ConsumerState<JadwalScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jadwalListAdminProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _toolbar(context, 'Jadwal Mengajar', () => _showCreateDialog(context), () => ref.invalidate(jadwalListAdminProvider)),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(jadwalListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada jadwal', icon: Icons.calendar_month_outlined) : _table(list),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Widget _toolbar(BuildContext context, String title, VoidCallback onAdd, VoidCallback onRefresh) {
    return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Spacer(),
      FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Tambah')),
      const SizedBox(width: 8),
      IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
    ]));
  }
  Widget _table(List<JadwalModel> list) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
      child: SingleChildScrollView(child: DataTable(
        columns: const [DataColumn(label: Text('Hari')), DataColumn(label: Text('Jam')), DataColumn(label: Text('Mapel')), DataColumn(label: Text('Kelas')), DataColumn(label: Text('Guru')), DataColumn(label: Text('Actions'))],
        rows: list.map((j) => DataRow(cells: [
          DataCell(Text(dayOfWeekLabel(j.dayOfWeek), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          DataCell(Text('${j.startTime} - ${j.endTime}', style: const TextStyle(fontSize: 12))),
          DataCell(Text(j.mapelName ?? '-', style: const TextStyle(fontSize: 12))),
          DataCell(Text(j.kelasName ?? '-', style: const TextStyle(fontSize: 12))),
          DataCell(Text(j.guruName ?? '-', style: const TextStyle(fontSize: 12))),
          DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Jadwal', message: 'Yakin hapus jadwal ${j.mapelName} - ${j.kelasName}?', destructive: true)) { try { await adminDeleteJadwal(ref, j.id); _toast('✅ Jadwal dihapus'); } catch (e) { _toast('Gagal: $e', true); } } })),
        ])).toList(),
        headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
      )),
    );
  }
  Future<void> _showCreateDialog(BuildContext context) async {
    final kelasList = await ref.read(kelasListProvider.future);
    final mapelList = await ref.read(mapelListProvider.future);
    final guruList = await ref.read(guruListAdminProvider(null).future);
    final taList = await ref.read(tahunAjaranListProvider.future);
    if (!context.mounted) return;
    String? kelasId, mapelId, guruId, taId;
    int dayOfWeek = 1;
    final startCtrl = TextEditingController(text: '07:00');
    final endCtrl = TextEditingController(text: '08:30');
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: const Text('Tambah Jadwal'),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldLabel(label: 'Tahun Ajaran', child: DropdownButtonFormField<String>(value: taId, hint: const Text('Pilih TA'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: taList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(), onChanged: (v) => setInner(() => taId = v))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Kelas', child: DropdownButtonFormField<String>(value: kelasId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: kelasList.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name))).toList(), onChanged: (v) => setInner(() => kelasId = v)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Mapel', child: DropdownButtonFormField<String>(value: mapelId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: mapelList.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(), onChanged: (v) => setInner(() => mapelId = v)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Guru', child: DropdownButtonFormField<String>(value: guruId, hint: const Text('Pilih'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: guruList.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(), onChanged: (v) => setInner(() => guruId = v)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Hari', child: DropdownButtonFormField<int>(value: dayOfWeek, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: 1, child: Text('Senin')), DropdownMenuItem(value: 2, child: Text('Selasa')), DropdownMenuItem(value: 3, child: Text('Rabu')), DropdownMenuItem(value: 4, child: Text('Kamis')), DropdownMenuItem(value: 5, child: Text('Jumat')), DropdownMenuItem(value: 6, child: Text('Sabtu')), DropdownMenuItem(value: 7, child: Text('Minggu'))], onChanged: (v) => setInner(() => dayOfWeek = v!)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: FormFieldLabel(label: 'Mulai', child: TextField(controller: startCtrl, decoration: const InputDecoration(hintText: '07:00', border: OutlineInputBorder(), isDense: true)))), const SizedBox(width: 8), Expanded(child: FormFieldLabel(label: 'Selesai', child: TextField(controller: endCtrl, decoration: const InputDecoration(hintText: '08:30', border: OutlineInputBorder(), isDense: true))))]),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')), ElevatedButton(onPressed: saving ? null : () async {
        if (kelasId == null || mapelId == null || guruId == null || taId == null) { _toast('Semua field wajib diisi', true); return; }
        setInner(() => saving = true);
        try { await adminCreateJadwal(ref, tahunAjaranId: taId!, semesterId: (await ref.read(semesterListProvider(taId).future)).first.id, kelasId: kelasId!, mapelId: mapelId!, guruId: guruId!, dayOfWeek: dayOfWeek, startTime: startCtrl.text.trim(), endTime: endCtrl.text.trim()); if (!context.mounted) return; Navigator.of(ctx).pop(); _toast('✅ Jadwal created'); }
        catch (e) { _toast('Gagal: $e', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
      }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'))],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
