// Materi create — form input materi baru.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

class MateriCreateScreen extends ConsumerStatefulWidget {
  const MateriCreateScreen({super.key});
  @override
  ConsumerState<MateriCreateScreen> createState() => _MateriCreateScreenState();
}

class _MateriCreateScreenState extends ConsumerState<MateriCreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _pertemuanController = TextEditingController();
  String? _kelasId;
  String? _mapelId;
  String _type = MateriType.dokumen;
  bool _isPublished = false;
  bool _saving = false;
  PlatformFile? _pickedFile;
  Uint8List? _fileBytes;
  String? _fileMimeType;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _externalUrlController.dispose();
    _pertemuanController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _toast('Isi judul materi', isError: true);
      return;
    }
    if (_mapelId == null || _kelasId == null) {
      _toast('Pilih kelas dan mapel', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      String? fileUrl, filePath;
      if (_pickedFile != null && _fileBytes != null) {
        try {
          final uploadPath =
              StorageService.materiPath(_mapelId!, _pickedFile!.name);
          final result = await ref.read(storageServiceProvider).upload(
                bucket: StorageBucket.materi,
                path: uploadPath,
                fileBytes: _fileBytes!,
                mimeType: _fileMimeType!,
              );
          fileUrl = result.publicUrl; // materi bucket is public
          filePath = result.path;
        } catch (e) {
          _toast('Gagal upload file: ${friendlyError(e)}', isError: true);
          return;
        }
      }
      await createMateri(
        ref,
        mapelId: _mapelId!,
        kelasId: _kelasId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        type: _type,
        fileUrl: fileUrl,
        filePath: filePath,
        externalUrl: _externalUrlController.text.trim().isEmpty
            ? null
            : _externalUrlController.text.trim(),
        pertemuan: int.tryParse(_pertemuanController.text),
        isPublished: _isPublished,
      );
      if (!mounted) return;
      _toast('✅ Materi dibuat');
      context.go('/dashboard/akademik/materi');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _pickedFile = file;
      _fileBytes = file.bytes;
      _fileMimeType = _mimeType(file.extension ?? 'pdf');
    });
  }

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
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelasAsync = ref.watch(kelasListProvider);
    final mapelAsync = ref.watch(mapelListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Materi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormFieldLabel(
              label: 'Judul Materi',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Tajwid Bab 1 - Hukum Nun Mati',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Deskripsi (opsional)',
              child: TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'Deskripsi singkat materi...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Mata Pelajaran',
              child: kelasAsync.when(
                loading: () => const SizedBox(height: 30),
                error: (e, _) => Text(friendlyError(e)),
                data: (_) => mapelAsync.when(
                  loading: () => const SizedBox(height: 30),
                  error: (e, _) => Text(friendlyError(e)),
                  data: (list) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    value: _mapelId,
                    hint: const Text('Pilih Mapel'),
                    items: list
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text('${m.name} (${m.code})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _mapelId = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Kelas',
              child: kelasAsync.when(
                loading: () => const SizedBox(height: 30),
                error: (e, _) => Text(friendlyError(e)),
                data: (list) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()),
                  value: _kelasId,
                  hint: const Text('Pilih Kelas'),
                  items: list
                      .map((k) => DropdownMenuItem(
                            value: k.id,
                            child: Text(k.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _kelasId = v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Tipe Materi',
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  MateriType.dokumen,
                  MateriType.video,
                  MateriType.link,
                  MateriType.presentation
                ].map((t) {
                  return ChoiceChip(
                    label: Text(MateriType.label(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primaryLight,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'URL Eksternal (opsional, untuk type=LINK)',
              hint: 'https://youtube.com/...',
              child: TextField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                    hintText: 'https://...', border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Upload File (opsional, untuk type=DOKUMEN/PRESENTATION)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_pickedFile?.name ??
                        'Pilih File (PDF/PPT/DOC, max 50MB)'),
                  ),
                  if (_pickedFile != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(
                              'File dipilih: ${_pickedFile!.name}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.success))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _pickedFile = null;
                          _fileBytes = null;
                          _fileMimeType = null;
                        }),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Pertemuan ke- (opsional)',
              child: TextField(
                controller: _pertemuanController,
                decoration: const InputDecoration(
                    hintText: '1, 2, 3, ...', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Publish sekarang'),
              subtitle: const Text(
                  'Jika OFF, materi akan tersimpan sebagai draft'),
              value: _isPublished,
              onChanged: (v) => setState(() => _isPublished = v),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Materi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
