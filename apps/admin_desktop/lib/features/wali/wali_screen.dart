// Wali CRUD screen — DataTable + create/edit + link santri.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class WaliScreen extends ConsumerStatefulWidget {
  const WaliScreen({super.key});
  @override
  ConsumerState<WaliScreen> createState() => _WaliScreenState();
}
class _WaliScreenState extends ConsumerState<WaliScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(waliListAdminProvider(_search.isEmpty ? null : _search));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Daftar Wali',
          icon: Icons.family_restroom,
          subtitle: 'Kelola data wali santri',
          actions: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari wali (nama, phone)...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(onPressed: () => _showDialog(context), icon: const Icon(Icons.person_add, size: 18), label: const Text('Tambah Wali')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(waliListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(waliListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada wali', subtitle: 'Tambahkan wali pertama Anda dengan tombol di atas.', icon: Icons.family_restroom, onRefresh: null) : ModernDataTableContainer(child: SingleChildScrollView(child: DataTable(
            columns: const [DataColumn(label: Text('Nama')), DataColumn(label: Text('Telepon')), DataColumn(label: Text('Email')), DataColumn(label: Text('Pekerjaan')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
            rows: list.map((w) => DataRow(cells: [
              DataCell(Text(w.name, style: AppTextStyles.label)),
              DataCell(Text(w.phone ?? '-', style: AppTextStyles.body3)),
              DataCell(Text(w.email ?? '-', style: AppTextStyles.body3)),
              DataCell(Text(w.occupation ?? '-', style: AppTextStyles.body3)),
              DataCell(StatusChip(label: w.activationStatus, color: w.activationStatus == WaliActivationStatus.active ? AppColors.success : AppColors.warning, bg: w.activationStatus == WaliActivationStatus.active ? AppColors.successLight : AppColors.warningLight, icon: w.activationStatus == WaliActivationStatus.active ? Icons.check_circle : Icons.cancel, compact: true)),
              DataCell(Row(children: [
                IconButton(icon: const Icon(Icons.link, size: 18), color: AppColors.info, tooltip: 'Link Santri', onPressed: () => _showLinkSantriDialog(context, w)),
                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(context, wali: w)),
                IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { if (await showConfirmDialog(context, title: 'Hapus Wali', message: 'Yakin hapus "${w.name}"?', destructive: true)) { try { await adminSoftDeleteWali(ref, w.id); _toast('✅ Wali dihapus'); } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } } }),
              ])),
            ])).toList(),
            headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
          ))),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Future<void> _showDialog(BuildContext context, {WaliModel? wali}) async {
    final isEdit = wali != null;
    final nameCtrl = TextEditingController(text: wali?.name ?? '');
    final phoneCtrl = TextEditingController(text: wali?.phone ?? '');
    final emailCtrl = TextEditingController(text: wali?.email ?? '');
    final nikCtrl = TextEditingController(text: wali?.nik ?? '');
    final occCtrl = TextEditingController(text: wali?.occupation ?? '');
    final addrCtrl = TextEditingController(text: wali?.address ?? '');
    final pinCtrl = TextEditingController();
    String rel = wali?.relationship ?? 'WALI';
    String status = wali?.activationStatus ?? WaliActivationStatus.active;
    bool saving = false;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text(isEdit ? 'Edit Wali' : 'Tambah Wali'),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldLabel(label: 'Nama', child: TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Telepon (WA)', child: TextField(controller: phoneCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.phone))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Email (opsional)', child: TextField(controller: emailCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.emailAddress))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'NIK (opsional)', child: TextField(controller: nikCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Pekerjaan (opsional)', child: TextField(controller: occCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)))),
        ]),
        const SizedBox(height: 8),
        FormFieldLabel(label: 'Alamat (opsional)', child: TextField(controller: addrCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 2)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FormFieldLabel(label: 'Hubungan', child: DropdownButtonFormField<String>(value: rel, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const ['AYAH','IBU','WALI','KAKEK','NENEK','PAMAN','BIBI'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setInner(() => rel = v!)))),
          const SizedBox(width: 8),
          Expanded(child: FormFieldLabel(label: 'Status', child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const [DropdownMenuItem(value: WaliActivationStatus.active, child: Text('Active')), DropdownMenuItem(value: WaliActivationStatus.suspended, child: Text('Suspended')), DropdownMenuItem(value: WaliActivationStatus.pending, child: Text('Pending'))], onChanged: (v) => setInner(() => status = v!)))),
        ]),
        if (!isEdit) ...[const SizedBox(height: 8), FormFieldLabel(label: 'PIN (6 digit, opsional)', hint: 'Default: no PIN. Set jika wali akan login via WA+PIN.', child: TextField(controller: pinCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, maxLength: 6))],
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: saving ? null : () async {
          if (nameCtrl.text.trim().isEmpty) { _toast('Nama wajib diisi', true); return; }
          setInner(() => saving = true);
          try {
            if (isEdit) { await adminUpdateWali(ref, waliId: wali.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(), nik: nikCtrl.text.trim().isEmpty ? null : nikCtrl.text.trim(), occupation: occCtrl.text.trim().isEmpty ? null : occCtrl.text.trim(), address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(), relationship: rel, activationStatus: status); }
            else { await adminCreateWali(ref, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(), email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(), nik: nikCtrl.text.trim().isEmpty ? null : nikCtrl.text.trim(), occupation: occCtrl.text.trim().isEmpty ? null : occCtrl.text.trim(), address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(), relationship: rel, activationStatus: status, pinHash: pinCtrl.text.length == 6 ? pinCtrl.text : null); }
            if (!context.mounted) return; Navigator.of(ctx).pop(); _toast(isEdit ? '✅ Wali updated' : '✅ Wali created');
          } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
        }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Create')),
      ],
    )));
  }
  Future<void> _showLinkSantriDialog(BuildContext context, WaliModel wali) async {
    final santriList = await ref.read(santriListProvider.future);
    if (!context.mounted) return;
    String? selectedSantriId;
    String relationship = 'AYAH';
    bool isPrimary = false;
    final existingLinks = await ref.read(santriWaliByWaliProvider(wali.id).future);
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
      title: Text('Link Santri — ${wali.name}'),
      content: SizedBox(width: 450, child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (existingLinks.isNotEmpty) ...[
          const Text('Santri Terhubung:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ...existingLinks.map((l) => ListTile(dense: true, title: Text(l.santriName ?? '-'), subtitle: Text(l.relationship), trailing: IconButton(icon: const Icon(Icons.link_off, size: 18), color: AppColors.danger, onPressed: () async { try { await adminUnlinkWaliSantri(ref, santriWaliId: l.id, waliId: wali.id); setInner(() {}); _toast('✅ Santri di-unlink'); } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); } }))),
          const Divider(),
        ],
        const Text('Tambah Link Baru:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: selectedSantriId, hint: const Text('Pilih Santri'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: santriList.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.nis})'))).toList(), onChanged: (v) => setInner(() => selectedSantriId = v)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: relationship, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: const ['AYAH','IBU','WALI','KAKEK','NENEK','PAMAN','BIBI'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setInner(() => relationship = v!))),
          const SizedBox(width: 8),
          CheckboxListTile(title: const Text('Wali Utama'), value: isPrimary, onChanged: (v) => setInner(() => isPrimary = v ?? false), dense: true),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup')),
        ElevatedButton(onPressed: selectedSantriId == null ? null : () async {
          try { await adminLinkWaliSantri(ref, waliId: wali.id, santriId: selectedSantriId!, relationship: relationship, isPrimary: isPrimary); _toast('✅ Santri di-link'); setInner(() {}); } catch (e) { _toast('Gagal: ${friendlyError(e)}', true); }
        }, child: const Text('Link')),
      ],
    )));
  }
  void _toast(String msg, [bool isError = false]) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success)); }
}
