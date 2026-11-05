// Materi — list + create-with-file-upload + delete (soft).
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class MateriScreen extends ConsumerWidget {
  const MateriScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materiListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Materi Pelajaran',
          icon: Icons.menu_book_outlined,
          subtitle: 'Kelola materi & dokumen',
          actions: [
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload Materi'),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(materiListAdminProvider)),
          ],
        ),
        Expanded(
            child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(materiListAdminProvider)),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  title: 'Belum ada materi',
                  subtitle: 'Upload materi pertama Anda dengan tombol di atas.',
                  icon: Icons.book_outlined,
                  onRefresh: null)
              : ModernDataTableContainer(
                  child: SingleChildScrollView(
                      child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Judul')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Mapel')),
                    DataColumn(label: Text('Kelas')),
                    DataColumn(label: Text('Guru')),
                    DataColumn(label: Text('File')),
                    DataColumn(label: Text('Published')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: list
                      .map((m) => DataRow(cells: [
                            DataCell(Text(m.title, style: AppTextStyles.label)),
                            DataCell(StatusChip(
                                label: MateriType.label(m.type),
                                color: AppColors.info,
                                bg: AppColors.infoLight,
                                compact: true)),
                            DataCell(Text(m.mapelName ?? '-',
                                style: AppTextStyles.body3)),
                            DataCell(Text(m.kelasName ?? '-',
                                style: AppTextStyles.body3)),
                            DataCell(Text(m.guruName ?? '-',
                                style: AppTextStyles.body3)),
                            DataCell(Icon(
                                (m.filePath != null && m.filePath!.isNotEmpty) ||
                                        (m.fileUrl != null &&
                                            m.fileUrl!.isNotEmpty)
                                    ? Icons.attach_file
                                    : Icons.insert_drive_file_outlined,
                                size: 16,
                                color: (m.filePath != null &&
                                            m.filePath!.isNotEmpty) ||
                                        (m.fileUrl != null &&
                                            m.fileUrl!.isNotEmpty)
                                    ? AppColors.success
                                    : AppColors.textMuted)),
                            DataCell(Icon(
                                m.isPublished ? Icons.check_circle : Icons.drafts,
                                size: 16,
                                color: m.isPublished
                                    ? AppColors.success
                                    : AppColors.textMuted)),
                            DataCell(IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: AppColors.danger,
                                onPressed: () async {
                                  await adminDeleteMateri(ref, m.id);
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

  static const _types = [
    MateriType.dokumen,
    MateriType.presentation,
    MateriType.video,
    MateriType.link,
  ];

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final mapelList = await ref.read(mapelListProvider.future);
    final kelasList = await ref.read(kelasListProvider.future);
    if (!context.mounted) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? mapelId, kelasId;
    String type = MateriType.dokumen;
    bool isPublished = false;
    bool saving = false;
    PlatformFile? pickedFile;
    Uint8List? fileBytes;
    String? fileExtension;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Upload Materi'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                        child: FormFieldLabel(
                            label: 'Mapel',
                            child: DropdownButtonFormField<String>(
                                value: mapelId,
                                hint: const Text('Pilih Mapel'),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(), isDense: true),
                                items: mapelList
                                    .map((m) => DropdownMenuItem(
                                        value: m.id, child: Text(m.name)))
                                    .toList(),
                                onChanged: (v) =>
                                    setInner(() => mapelId = v)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FormFieldLabel(
                            label: 'Kelas',
                            child: DropdownButtonFormField<String>(
                                value: kelasId,
                                hint: const Text('Pilih Kelas'),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(), isDense: true),
                                items: kelasList
                                    .map((k) => DropdownMenuItem(
                                        value: k.id, child: Text(k.name)))
                                    .toList(),
                                onChanged: (v) =>
                                    setInner(() => kelasId = v)))),
                  ]),
                  const SizedBox(height: 8),
                  FormFieldLabel(
                      label: 'Judul',
                      child: TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(height: 8),
                  FormFieldLabel(
                      label: 'Deskripsi (opsional)',
                      child: TextField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(), isDense: true),
                          maxLines: 3)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: FormFieldLabel(
                            label: 'Type',
                            child: DropdownButtonFormField<String>(
                                value: type,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(), isDense: true),
                                items: _types
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(MateriType.label(t))))
                                    .toList(),
                                onChanged: (v) =>
                                    setInner(() => type = v!)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FormFieldLabel(
                            label: 'Published',
                            child: Switch(
                                value: isPublished,
                                onChanged: (v) =>
                                    setInner(() => isPublished = v)))),
                  ]),
                  const SizedBox(height: 8),
                  FormFieldLabel(
                      label: 'File (PDF/PPT/DOC/DOCX, max 50MB)',
                      hint: pickedFile?.name ?? 'Belum ada file dipilih',
                      child: OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'pdf',
                                      'ppt',
                                      'pptx',
                                      'doc',
                                      'docx'
                                    ],
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
                                      fileExtension =
                                          f.extension?.toLowerCase() ?? 'pdf';
                                    });
                                  }
                                },
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: Text(pickedFile != null
                              ? 'Ganti File'
                              : 'Pilih File'))),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (mapelId == null || kelasId == null) {
                          _toast(context, 'Mapel & Kelas wajib dipilih', true);
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
                            final ext = fileExtension ?? 'pdf';
                            final mimeType = _mimeType(ext);
                            final path = StorageService.materiPath(
                                mapelId!, pickedFile!.name);
                            final res = await ref
                                .read(storageServiceProvider)
                                .upload(
                                  bucket: StorageBucket.materi,
                                  path: path,
                                  fileBytes: fileBytes!,
                                  mimeType: mimeType,
                                );
                            // materi bucket is public — publicUrl works.
                            fileUrl = res.publicUrl;
                            filePath = res.path;
                          }
                          await adminCreateMateri(
                            ref,
                            mapelId: mapelId!,
                            kelasId: kelasId!,
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            type: type,
                            fileUrl: fileUrl,
                            filePath: filePath,
                            isPublished: isPublished,
                          );
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          _toast(context, '✅ Materi dibuat');
                        } catch (e) {
                          _toast(context, 'Gagal: ${friendlyError(e)}', true);
                        } finally {
                          if (ctx.mounted) setInner(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save')),
          ],
        ),
      ),
    );
  }

  /// MIME type lookup for common document extensions.
  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  void _toast(BuildContext context, String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
