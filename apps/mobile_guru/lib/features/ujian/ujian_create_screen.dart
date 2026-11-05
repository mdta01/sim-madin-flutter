// Ujian create — form input ujian baru.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

class UjianCreateScreen extends ConsumerStatefulWidget {
  const UjianCreateScreen({super.key});
  @override
  ConsumerState<UjianCreateScreen> createState() => _UjianCreateScreenState();
}

class _UjianCreateScreenState extends ConsumerState<UjianCreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '90');
  final _ruangController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  final _passingScoreController = TextEditingController(text: '70');
  String? _mapelId;
  String? _kelasId;
  String _type = UjianType.uts;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isPublished = false;
  bool _saving = false;
  PlatformFile? _pickedFile;
  Uint8List? _fileBytes;
  String? _fileMimeType;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _ruangController.dispose();
    _maxScoreController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;
    final datetime = DateTime(picked.year, picked.month, picked.day,
        pickedTime.hour, pickedTime.minute);
    setState(() {
      if (isStart) {
        _startTime = datetime;
      } else {
        _endTime = datetime;
      }
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _toast('Isi judul ujian', isError: true);
      return;
    }
    if (_mapelId == null || _kelasId == null) {
      _toast('Pilih mapel dan kelas', isError: true);
      return;
    }
    // Validasi: endTime harus setelah startTime (kalau keduanya di-set).
    if (_startTime != null && _endTime != null) {
      if (!_endTime!.isAfter(_startTime!)) {
        _toast('Waktu selesai harus setelah waktu mulai', isError: true);
        return;
      }
    }
    // Validasi: passingScore harus <= maxScore.
    final maxScore = double.tryParse(_maxScoreController.text) ?? 100;
    final passingScore = double.tryParse(_passingScoreController.text) ?? 70;
    if (passingScore > maxScore) {
      _toast('Passing score tidak boleh melebihi max score', isError: true);
      return;
    }
    if (passingScore < 0 || maxScore <= 0) {
      _toast('Score tidak valid', isError: true);
      return;
    }
    final durationMnt = int.tryParse(_durationController.text) ?? 90;
    if (durationMnt <= 0 || durationMnt > 300) {
      _toast('Durasi harus 1-300 menit', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      String? fileUrl, filePath;
      if (_pickedFile != null && _fileBytes != null) {
        try {
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          final uploadPath =
              StorageService.ujianPath(tempId, 'soal', _pickedFile!.name);
          final result = await ref.read(storageServiceProvider).upload(
                bucket: StorageBucket.ujian,
                path: uploadPath,
                fileBytes: _fileBytes!,
                mimeType: _fileMimeType!,
              );
          fileUrl = result.signedUrl; // ujian bucket is private
          filePath = result.path;
        } catch (e) {
          _toast('Gagal upload file: ${friendlyError(e)}', isError: true);
          return;
        }
      }
      await createUjian(
        ref,
        mapelId: _mapelId!,
        kelasId: _kelasId!,
        title: _titleController.text.trim(),
        type: _type,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        durationMnt: durationMnt,
        ruang: _ruangController.text.trim().isEmpty
            ? null
            : _ruangController.text.trim(),
        maxScore: maxScore,
        passingScore: passingScore,
        fileUrl: fileUrl,
        filePath: filePath,
        isPublished: _isPublished,
      );
      if (!mounted) return;
      _toast('✅ Ujian dibuat');
      context.go('/dashboard/ujian/list');
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
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
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
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
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
      appBar: AppBar(title: const Text('Buat Ujian')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormFieldLabel(
              label: 'Judul Ujian',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: UTS Tajwid Semester Ganjil',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Tipe Ujian',
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  UjianType.uts,
                  UjianType.uas,
                  UjianType.quiz,
                  UjianType.tugas,
                ].map((t) {
                  final label = t == UjianType.uts
                      ? 'UTS'
                      : t == UjianType.uas
                          ? 'UAS'
                          : t == UjianType.quiz
                              ? 'Quiz'
                              : 'Tugas';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primaryLight,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Deskripsi (opsional)',
              child: TextField(
                controller: _descController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Upload File (opsional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_pickedFile?.name ??
                        'Pilih File (PDF/JPG/PNG, max 10MB)'),
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
              label: 'Mata Pelajaran',
              child: mapelAsync.when(
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
            Row(
              children: [
                Expanded(
                  child: FormFieldLabel(
                    label: 'Mulai (opsional)',
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _startTime == null
                            ? 'Pilih'
                            : formatDateTime(_startTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldLabel(
                    label: 'Selesai (opsional)',
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _endTime == null
                            ? 'Pilih'
                            : formatDateTime(_endTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FormFieldLabel(
                    label: 'Durasi (mnt)',
                    child: TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldLabel(
                    label: 'Ruang (opsional)',
                    child: TextField(
                      controller: _ruangController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FormFieldLabel(
                    label: 'Max Score',
                    child: TextField(
                      controller: _maxScoreController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldLabel(
                    label: 'Passing Score',
                    child: TextField(
                      controller: _passingScoreController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Publish sekarang'),
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Ujian'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Setelah ujian dibuat, tambahkan soal + assign peserta dari halaman detail ujian.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
