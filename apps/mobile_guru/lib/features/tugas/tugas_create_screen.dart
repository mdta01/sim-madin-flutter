// Tugas create — form input tugas baru.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

class TugasCreateScreen extends ConsumerStatefulWidget {
  const TugasCreateScreen({super.key});
  @override
  ConsumerState<TugasCreateScreen> createState() => _TugasCreateScreenState();
}

class _TugasCreateScreenState extends ConsumerState<TugasCreateScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  DateTime? _dueDate;
  String? _kelasId;
  String? _mapelId;
  String _type = TugasType.individu;
  bool _isPublished = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        setState(() => _dueDate = picked);
      }
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _toast('Isi judul tugas', isError: true);
      return;
    }
    if (_mapelId == null || _kelasId == null) {
      _toast('Pilih kelas dan mapel', isError: true);
      return;
    }
    final maxScore = double.tryParse(_maxScoreController.text);
    if (maxScore == null || maxScore <= 0 || maxScore > 1000) {
      _toast('Max score harus angka 1-1000', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await createTugas(
        ref,
        mapelId: _mapelId!,
        kelasId: _kelasId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        type: _type,
        maxScore: maxScore,
        dueDate: _dueDate,
        isPublished: _isPublished,
      );
      if (!mounted) return;
      _toast('✅ Tugas dibuat');
      context.go('/dashboard/akademik/tugas');
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

  @override
  Widget build(BuildContext context) {
    final kelasAsync = ref.watch(kelasListProvider);
    final mapelAsync = ref.watch(mapelListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Tugas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormFieldLabel(
              label: 'Judul Tugas',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Tugas Tajwid Bab 1',
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
                  hintText: 'Instruksi tugas untuk santri...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
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
            FormFieldLabel(
              label: 'Tipe Tugas',
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [TugasType.individu, TugasType.kelompok].map((t) {
                  final label = t == TugasType.individu
                      ? 'Individu'
                      : 'Kelompok';
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
            Row(
              children: [
                Expanded(
                  child: FormFieldLabel(
                    label: 'Max Score',
                    child: SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _maxScoreController,
                        decoration: const InputDecoration(
                          hintText: '100',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FormFieldLabel(
                    label: 'Tenggat (opsional)',
                    child: InkWell(
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _dueDate != null
                              ? formatDateTime(_dueDate)
                              : 'Pilih tanggal & jam',
                          style: TextStyle(
                            fontSize: 14,
                            color: _dueDate != null
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Publish sekarang'),
              subtitle: const Text(
                  'Jika OFF, tugas tersimpan sebagai draft (santri tidak bisa lihat)'),
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Tugas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
