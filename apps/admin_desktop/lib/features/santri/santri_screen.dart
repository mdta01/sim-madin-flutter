// Santri CRUD screen — DataTable + create/edit + search.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class SantriScreen extends ConsumerStatefulWidget {
  const SantriScreen({super.key});
  @override
  ConsumerState<SantriScreen> createState() => _SantriScreenState();
}

class _SantriScreenState extends ConsumerState<SantriScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue =
        ref.watch(santriListProvider);
    final kelasAsync = ref.watch(kelasListProvider);
    final waliAsync = ref.watch(waliListAdminProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(itemCount: 10),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(santriListProvider)),
              data: (list) {
                final filtered = _search.isEmpty
                    ? list
                    : list.where((s) =>
                        s.name.toLowerCase().contains(_search) ||
                        s.nis.toLowerCase().contains(_search)).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _search.isEmpty ? 'Belum ada santri' : 'Tidak ditemukan',
                    icon: Icons.people_outline,
                    onRefresh: () => ref.invalidate(santriListProvider),
                  );
                }
                return _buildTable(context, filtered, kelasAsync, waliAsync);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Cari santri (nama, NIS)...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showCreateEditDialog(context), icon: const Icon(Icons.person_add), label: const Text('Tambah Santri')),
          const SizedBox(width: AppSpacing.sm),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: () => ref.invalidate(santriListProvider)),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<SantriModel> list, AsyncValue<List<KelasModel>> kelasAsync, AsyncValue<List<WaliModel>> waliAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NIS')), DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Gender')), DataColumn(label: Text('Kelas')),
            DataColumn(label: Text('Wali')), DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: list.map((s) => DataRow(cells: [
            DataCell(Text(s.nis, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
            DataCell(Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            DataCell(Text(SantriGender.label(s.gender), style: const TextStyle(fontSize: 12))),
            DataCell(Text(s.kelasName ?? '-', style: const TextStyle(fontSize: 12))),
            DataCell(Text(s.waliName ?? '-', style: const TextStyle(fontSize: 12))),
            DataCell(StatusChip(label: s.status, color: s.status == SantriStatus.aktif ? AppColors.success : AppColors.danger, bg: s.status == SantriStatus.aktif ? AppColors.successLight : AppColors.dangerLight, compact: true)),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), tooltip: 'Edit', onPressed: () => _showCreateEditDialog(context, santri: s)),
              IconButton(icon: const Icon(Icons.delete, size: 18), tooltip: 'Hapus', color: AppColors.danger, onPressed: () => _confirmDelete(context, s)),
            ])),
          ])).toList(),
          headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
        ),
      ),
    );
  }

  Future<void> _showCreateEditDialog(BuildContext context, {SantriModel? santri}) async {
    final isEdit = santri != null;
    final nisCtrl = TextEditingController(text: santri?.nis ?? '');
    final nameCtrl = TextEditingController(text: santri?.name ?? '');
    final nisnCtrl = TextEditingController(text: santri?.nisn ?? '');
    final birthPlaceCtrl = TextEditingController(text: santri?.birthPlace ?? '');
    final addressCtrl = TextEditingController(text: santri?.address ?? '');
    final phoneCtrl = TextEditingController(text: santri?.phone ?? '');
    String gender = santri?.gender ?? SantriGender.l;
    String? kelasId = santri?.kelasId;
    String? waliId = santri?.waliId;
    String status = santri?.status ?? SantriStatus.aktif;
    DateTime? birthDate = santri?.birthDate;
    bool saving = false;

    final kelasList = await ref.read(kelasListProvider.future);
    final waliList = await ref.read(waliListAdminProvider(null).future);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: Text(isEdit ? 'Edit Santri' : 'Tambah Santri'),
        content: SizedBox(width: 550, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'NIS', child: TextField(controller: nisCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'NISN (opsional)', child: TextField(controller: nisnCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
          ]),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Nama Lengkap', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Jenis Kelamin', child: DropdownButtonFormField<String>(value: gender, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: SantriGender.l, child: Text('Laki-laki')), DropdownMenuItem(value: SantriGender.p, child: Text('Perempuan'))], onChanged: (v) => setInner(() => gender = v!)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Status', child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: SantriStatus.aktif, child: Text('Aktif')), DropdownMenuItem(value: SantriStatus.lulus, child: Text('Lulus')), DropdownMenuItem(value: SantriStatus.pindah, child: Text('Pindah')), DropdownMenuItem(value: SantriStatus.keluar, child: Text('Keluar'))], onChanged: (v) => setInner(() => status = v!)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Kelas', child: DropdownButtonFormField<String>(value: kelasId, hint: const Text('Pilih Kelas'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: kelasList.map((k) => DropdownMenuItem(value: k.id, child: Text(k.name))).toList(), onChanged: (v) => setInner(() => kelasId = v)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Wali', child: DropdownButtonFormField<String>(value: waliId, hint: const Text('Pilih Wali'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: waliList.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(), onChanged: (v) => setInner(() => waliId = v)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Tempat Lahir', child: TextField(controller: birthPlaceCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Tanggal Lahir', child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: birthDate ?? DateTime(2010), firstDate: DateTime(1990), lastDate: DateTime.now()); if (d != null) setInner(() => birthDate = d); }, icon: const Icon(Icons.calendar_today, size: 16), label: Text(birthDate != null ? formatDate(birthDate) : 'Pilih')))),
          ]),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Alamat', child: TextField(controller: addressCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Telepon (opsional)', child: TextField(controller: phoneCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.phone)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            if (nisCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) { _toast('NIS dan Nama wajib diisi', true); return; }
            setInner(() => saving = true);
            try {
              if (isEdit) {
                await adminUpdateSantri(ref, santriId: santri.id, nis: nisCtrl.text.trim(), name: nameCtrl.text.trim(), gender: gender, nisn: nisnCtrl.text.trim().isEmpty ? null : nisnCtrl.text.trim(), birthPlace: birthPlaceCtrl.text.trim().isEmpty ? null : birthPlaceCtrl.text.trim(), birthDate: birthDate, address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), kelasId: kelasId, waliId: waliId, status: status);
              } else {
                await adminCreateSantri(ref, nis: nisCtrl.text.trim(), name: nameCtrl.text.trim(), gender: gender, nisn: nisnCtrl.text.trim().isEmpty ? null : nisnCtrl.text.trim(), birthPlace: birthPlaceCtrl.text.trim().isEmpty ? null : birthPlaceCtrl.text.trim(), birthDate: birthDate, address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), kelasId: kelasId, waliId: waliId, status: status);
              }
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast(isEdit ? '✅ Santri updated' : '✅ Santri created');
            } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create')),
        ],
      )),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SantriModel santri) async {
    final confirmed = await showConfirmDialog(context, title: 'Hapus Santri', message: 'Yakin ingin menghapus "${santri.name}" (${santri.nis})?\nSantri akan di-soft delete (status=KELUAR).', destructive: true);
    if (!confirmed) return;
    try { await adminSoftDeleteSantri(ref, santri.id); _toast('✅ Santri dihapus'); } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); }
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
