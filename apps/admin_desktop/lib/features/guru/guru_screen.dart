// Guru CRUD screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class GuruScreen extends ConsumerStatefulWidget {
  const GuruScreen({super.key});
  @override
  ConsumerState<GuruScreen> createState() => _GuruScreenState();
}
class _GuruScreenState extends ConsumerState<GuruScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(guruListAdminProvider(_search.isEmpty ? null : _search));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Daftar Guru',
          icon: Icons.school_outlined,
          subtitle: 'Kelola data guru pengajar',
          actions: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari guru (nama, NIP)...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(onPressed: () => _showDialog(context), icon: const Icon(Icons.person_add, size: 18), label: const Text('Tambah Guru')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(guruListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(guruListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada guru', subtitle: 'Tambahkan guru pertama Anda dengan tombol di atas.', icon: Icons.school_outlined, onRefresh: null) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
            columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('NIP')), DataColumn(label: Text('Spesialisasi')), DataColumn(label: Text('Telepon')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
            rows: list.map((g) => DataRow(cells: [
              DataCell(Text(g.name, style: AppTextStyles.label)),
              DataCell(Text(g.nip ?? '-', style: AppTextStyles.body3.copyWith(fontFamily: AppFonts.mono))),
              DataCell(Text(g.specialization ?? '-', style: AppTextStyles.body3)),
              DataCell(Text(g.phone ?? '-', style: AppTextStyles.body3)),
              DataCell(StatusChip(label: g.status, color: g.status == GuruStatus.aktif ? AppColors.success : AppColors.danger, bg: g.status == GuruStatus.aktif ? AppColors.successLight : AppColors.dangerLight, icon: g.status == GuruStatus.aktif ? Icons.check_circle : Icons.cancel, compact: true)),
              DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(context, guru: g)), IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Guru', message: 'Yakin hapus "${g.name}"?', destructive: true)) { try { await adminSoftDeleteGuru(ref, g.id); _toast('✅ Guru dihapus'); } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } } })])),
            ])).toList(),
            headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
          ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Future<void> _showDialog(BuildContext context, {GuruModel? guru}) async {
    final isEdit = guru != null;
    final nameCtrl = TextEditingController(text: guru?.name ?? '');
    final nipCtrl = TextEditingController(text: guru?.nip ?? '');
    final specCtrl = TextEditingController(text: guru?.specialization ?? '');
    final phoneCtrl = TextEditingController(text: guru?.phone ?? '');
    final emailCtrl = TextEditingController(text: guru?.email ?? '');
    final addrCtrl = TextEditingController(text: guru?.address ?? '');
    String gender = guru?.gender ?? SantriGender.l;
    String status = guru?.status ?? GuruStatus.aktif;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text(isEdit ? 'Edit Guru' : 'Tambah Guru'),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Gender', child: DropdownButtonFormField<String>(value: gender, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: 'L', child: Text('Laki-laki')), DropdownMenuItem(value: 'P', child: Text('Perempuan'))], onChanged: (v) => setInner(() => gender = v!)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'NIP (opsional)', child: TextField(controller: nipCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
        ]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Spesialisasi (opsional)', child: TextField(controller: specCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Telepon', child: TextField(controller: phoneCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.phone))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Email', child: TextField(controller: emailCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.emailAddress))),
        ]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Alamat (opsional)', child: TextField(controller: addrCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Status', child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: GuruStatus.aktif, child: Text('Aktif')), DropdownMenuItem(value: GuruStatus.cuti, child: Text('Cuti')), DropdownMenuItem(value: GuruStatus.keluar, child: Text('Keluar'))], onChanged: (v) => setInner(() => status = v!))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: saving ? null : () async {
          if (nameCtrl.text.trim().isEmpty) { _toast('Nama wajib diisi', true); return; }
          setInner(() => saving = true);
          try {
            if (isEdit) { await adminUpdateGuru(ref, guruId: guru.id, name: nameCtrl.text.trim(), gender: gender, nip: nipCtrl.text.trim().isEmpty ? null : nipCtrl.text.trim(), specialization: specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(), address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(), status: status); }
            else { await adminCreateGuru(ref, name: nameCtrl.text.trim(), gender: gender, nip: nipCtrl.text.trim().isEmpty ? null : nipCtrl.text.trim(), specialization: specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(), address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(), status: status); }
            if (!context.mounted) return; Navigator.of(ctx).pop(); _toast(isEdit ? '✅ Guru updated' : '✅ Guru created');
          } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
        }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create')),
      ],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
