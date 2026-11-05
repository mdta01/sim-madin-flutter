// Surat — list + delete + create (with PDF upload to private bucket).
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class SuratScreen extends ConsumerWidget {
  const SuratScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suratListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Surat Resmi',
          icon: Icons.mail_outlined,
          subtitle: 'Kelola surat & disposisi',
          actions: [
            FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Buat Surat')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(suratListAdminProvider)),
          ],
        ),
        Expanded(
            child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(suratListAdminProvider)),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  title: 'Belum ada surat',
                  subtitle: 'Buat surat pertama Anda dengan tombol di atas.',
                  icon: Icons.mail_outlined,
                  onRefresh: null)
              : ModernDataTableContainer(
                  child: SingleChildScrollView(
                      child: DataTable(
                    columns: const [
                      DataColumn(label: Text('No. Surat')),
                      DataColumn(label: Text('Judul')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Santri')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('File')),
                      DataColumn(label: Text('Actions'))
                    ],
                    rows: list
                        .map((s) => DataRow(cells: [
                              DataCell(Text(s.nomorSurat,
                                  style: AppTextStyles.body3
                                      .copyWith(fontFamily: AppFonts.mono))),
                              DataCell(
                                  Text(s.title, style: AppTextStyles.label)),
                              DataCell(StatusChip(
                                  label: s.type,
                                  color: AppColors.info,
                                  bg: AppColors.infoLight,
                                  compact: true)),
                              DataCell(Text(s.santriName,
                                  style: AppTextStyles.body3)),
                              DataCell(StatusChip(
                                  label: s.status,
                                  color: s.status == 'SIGNED'
                                      ? AppColors.success
                                      : AppColors.warning,
                                  bg: s.status == 'SIGNED'
                                      ? AppColors.successLight
                                      : AppColors.warningLight,
                                  compact: true)),
                              DataCell(Text(
                                  s.tanggalSurat != null
                                      ? formatDate(s.tanggalSurat)
                                      : '-',
                                  style: AppTextStyles.body3)),
                              DataCell(Icon(
                                  (s.filePath != null &&
                                          s.filePath!.isNotEmpty) ||
                                          (s.fileUrl != null &&
                                              s.fileUrl!.isNotEmpty)
                                      ? Icons.attach_file
                                      : Icons.insert_drive_file_outlined,
                                  size: 16,
                                  color: (s.filePath != null &&
                                              s.filePath!.isNotEmpty) ||
                                          (s.fileUrl != null &&
                                              s.fileUrl!.isNotEmpty)
                                      ? AppColors.success
                                      : AppColors.textMuted)),
                              DataCell(IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: AppColors.danger,
                                  onPressed: () async {
                                    await adminDeleteSurat(ref, s.id);
                                  })),
                            ]))
                        .toList(),
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    columnSpacing: 24,
                  )),
                ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }

  static const _types = ['KETERANGAN', 'PINDAH', 'LULUS', 'LAINNYA'];
  static const _statuses = ['DRAFT', 'ISSUED', 'CANCELLED'];

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final santriList = await ref.read(santriListProvider.future);
    if (!context.mounted) return;

    final nomorCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String? santriId;
    String type = 'KETERANGAN';
    String status = 'DRAFT';
    DateTime? tanggalSurat = DateTime.now();
    bool saving = false;
    PlatformFile? pickedFile;
    Uint8List? fileBytes;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setInner) => AlertDialog(
                title: const Text('Buat Surat'),
                content: SizedBox(
                    width: 550,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      FormFieldLabel(
                          label: 'Santri',
                          child: DropdownButtonFormField<String>(
                              value: santriId,
                              hint: const Text('Pilih Santri'),
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(), isDense: true),
                              items: santriList
                                  .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text('${s.name} (${s.nis})')))
                                  .toList(),
                              onChanged: (v) => setInner(() => santriId = v))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: FormFieldLabel(
                                label: 'Type',
                                child: DropdownButtonFormField<String>(
                                    value: type,
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true),
                                    items: _types
                                        .map((t) => DropdownMenuItem(
                                            value: t, child: Text(t)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setInner(() => type = v!)))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: FormFieldLabel(
                                label: 'Status',
                                child: DropdownButtonFormField<String>(
                                    value: status,
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true),
                                    items: _statuses
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setInner(() => status = v!)))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: FormFieldLabel(
                                label: 'No. Surat (opsional)',
                                child: TextField(
                                    controller: nomorCtrl,
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        hintText: 'Auto jika kosong')))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: FormFieldLabel(
                                label: 'Tanggal Surat',
                                child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final d = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              tanggalSurat ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 30)));
                                      if (d != null) {
                                        setInner(() => tanggalSurat = d);
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today,
                                        size: 16),
                                    label: Text(tanggalSurat != null
                                        ? formatDate(tanggalSurat)
                                        : 'Pilih')))),
                      ]),
                      const SizedBox(height: 8),
                      FormFieldLabel(
                          label: 'Judul',
                          child: TextField(
                              controller: titleCtrl,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true))),
                      const SizedBox(height: 8),
                      FormFieldLabel(
                          label: 'Isi Surat',
                          child: TextField(
                              controller: contentCtrl,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(), isDense: true),
                              maxLines: 6)),
                      const SizedBox(height: 8),
                      FormFieldLabel(
                          label: 'Lampiran PDF (opsional, max 10MB)',
                          hint: pickedFile?.name ?? 'Belum ada file dipilih',
                          child: OutlinedButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final result = await FilePicker.platform
                                          .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf'],
                                        withData: true,
                                      );
                                      if (!context.mounted) return;
                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        final f = result.files.first;
                                        final bytes = f.bytes;
                                        if (bytes == null) {
                                          _toast(context,
                                              'Gagal membaca file. Coba lagi.', true);
                                          return;
                                        }
                                        setInner(() {
                                          pickedFile = f;
                                          fileBytes = bytes;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.attach_file, size: 16),
                              label: Text(pickedFile != null
                                  ? 'Ganti File'
                                  : 'Pilih File'))),
                    ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal')),
                  ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (santriId == null) {
                                _toast(context, 'Santri wajib dipilih', true);
                                return;
                              }
                              if (titleCtrl.text.trim().isEmpty) {
                                _toast(context, 'Judul wajib diisi', true);
                                return;
                              }
                              setInner(() => saving = true);
                              try {
                                String? fileUrl;
                                String? filePath;
                                if (fileBytes != null && pickedFile != null) {
                                  // surat ID belum diketahui sebelum insert,
                                  // jadi generate tempId unik untuk path Storage.
                                  final tempId = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  final path = StorageService.suratPath(
                                      tempId, pickedFile!.name);
                                  final res = await ref
                                      .read(storageServiceProvider)
                                      .upload(
                                        bucket: StorageBucket.surat,
                                        path: path,
                                        fileBytes: fileBytes!,
                                        mimeType: 'application/pdf',
                                      );
                                  // surat bucket is private — pakai signedUrl.
                                  fileUrl = res.signedUrl;
                                  filePath = res.path;
                                }
                                await adminCreateSurat(ref,
                                    santriId: santriId!,
                                    type: type,
                                    title: titleCtrl.text.trim(),
                                    nomorSurat: nomorCtrl.text.trim().isEmpty
                                        ? null
                                        : nomorCtrl.text.trim(),
                                    content: contentCtrl.text.trim().isEmpty
                                        ? null
                                        : contentCtrl.text.trim(),
                                    status: status,
                                    tanggalSurat: tanggalSurat,
                                    fileUrl: fileUrl,
                                    filePath: filePath);
                                if (!context.mounted) return;
                                Navigator.of(ctx).pop();
                                _toast(context, '✅ Surat dibuat');
                              } catch (e) {
                                _toast(context, 'Gagal: ${friendlyError(e)}',
                                    true);
                              } finally {
                                if (ctx.mounted) setInner(() => saving = false);
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create')),
                ],
              )),
    );
  }

  void _toast(BuildContext context, String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
