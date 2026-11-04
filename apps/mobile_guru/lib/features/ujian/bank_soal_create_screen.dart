// Bank Soal create — form input soal baru untuk bank soal guru.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

class BankSoalCreateScreen extends ConsumerStatefulWidget {
  const BankSoalCreateScreen({super.key});
  @override
  ConsumerState<BankSoalCreateScreen> createState() =>
      _BankSoalCreateScreenState();
}

class _BankSoalCreateScreenState extends ConsumerState<BankSoalCreateScreen> {
  final _codeController = TextEditingController();
  final _questionController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _answerKeyController = TextEditingController();
  final _bobotController = TextEditingController(text: '1');
  final _difficultyController = TextEditingController();
  final _tagsController = TextEditingController();
  // PG options (4 inputs A/B/C/D)
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _optionC = TextEditingController();
  final _optionD = TextEditingController();

  String? _mapelId;
  String _type = SoalType.pg;
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _questionController.dispose();
    _correctAnswerController.dispose();
    _answerKeyController.dispose();
    _bobotController.dispose();
    _difficultyController.dispose();
    _tagsController.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _optionC.dispose();
    _optionD.dispose();
    super.dispose();
  }

  /// Build PG options JSON string dari 4 inputs.
  /// Format: 'A:text|B:text|C:text|D:text' → encode ke JSON.
  String? _buildOptionsJson() {
    if (_type != SoalType.pg) return null;
    final opts = {
      'A': _optionA.text.trim(),
      'B': _optionB.text.trim(),
      'C': _optionC.text.trim(),
      'D': _optionD.text.trim(),
    };
    if (opts.values.every((v) => v.isEmpty)) return null;
    return jsonEncode(opts);
  }

  Future<void> _save() async {
    if (_codeController.text.trim().isEmpty) {
      _toast('Isi kode soal', isError: true);
      return;
    }
    if (_questionController.text.trim().isEmpty) {
      _toast('Isi pertanyaan', isError: true);
      return;
    }
    if (_mapelId == null) {
      _toast('Pilih mapel', isError: true);
      return;
    }
    if (_type == SoalType.pg) {
      // Validate correct answer is A/B/C/D
      final correct = _correctAnswerController.text.trim().toUpperCase();
      if (!['A', 'B', 'C', 'D'].contains(correct)) {
        _toast('Untuk PG, jawaban benar harus A/B/C/D', isError: true);
        return;
      }
      if (_optionA.text.trim().isEmpty && _optionB.text.trim().isEmpty) {
        _toast('Isi minimal opsi A dan B untuk PG', isError: true);
        return;
      }
    }
    final bobot = double.tryParse(_bobotController.text);
    if (bobot == null || bobot <= 0) {
      _toast('Bobot harus angka > 0', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await createBankSoal(
        ref,
        mapelId: _mapelId!,
        code: _codeController.text.trim(),
        type: _type,
        question: _questionController.text.trim(),
        options: _buildOptionsJson(),
        correctAnswer: _type == SoalType.pg
            ? _correctAnswerController.text.trim().toUpperCase()
            : null,
        answerKey: _answerKeyController.text.trim().isEmpty
            ? null
            : _answerKeyController.text.trim(),
        bobot: bobot,
        difficulty: _difficultyController.text.trim().isEmpty
            ? null
            : _difficultyController.text.trim(),
        tags: _tagsController.text.trim().isEmpty
            ? null
            : _tagsController.text.trim(),
      );
      if (!mounted) return;
      _toast('✅ Soal dibuat');
      context.go('/dashboard/ujian/bank-soal');
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
    final mapelAsync = ref.watch(mapelListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Soal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FormFieldLabel(
              label: 'Kode Soal',
              hint: 'Unik per mapel, mis. TG-TJW-01',
              child: TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'TG-TJW-01',
                  border: OutlineInputBorder(),
                ),
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
              label: 'Tipe Soal',
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  SoalType.pg,
                  SoalType.isian,
                  SoalType.essay,
                ].map((t) {
                  final label = t == SoalType.pg
                      ? 'Pilihan Ganda'
                      : t == SoalType.isian
                          ? 'Isian Singkat'
                          : 'Essay';
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
              label: 'Pertanyaan',
              child: TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ),
            if (_type == SoalType.pg) ...[
              const SizedBox(height: AppSpacing.md),
              FormFieldLabel(
                label: 'Opsi Jawaban (A-D)',
                hint: 'Kosongkan opsi yang tidak terpakai (min A & B)',
                child: Column(
                  children: [
                    _optionField(_optionA, 'A'),
                    const SizedBox(height: AppSpacing.xs),
                    _optionField(_optionB, 'B'),
                    const SizedBox(height: AppSpacing.xs),
                    _optionField(_optionC, 'C'),
                    const SizedBox(height: AppSpacing.xs),
                    _optionField(_optionD, 'D'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldLabel(
                label: 'Jawaban Benar (huruf)',
                hint: 'A, B, C, atau D',
                child: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _correctAnswerController,
                    decoration: const InputDecoration(
                      hintText: 'A',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              FormFieldLabel(
                label: 'Kunci Jawaban / Jawaban Ideal',
                hint: 'Untuk isian: jawaban singkat. Untuk essay: poin-poin.',
                child: TextField(
                  controller: _answerKeyController,
                  decoration: const InputDecoration(
                    hintText: 'Jawaban ideal...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FormFieldLabel(
                    label: 'Bobot',
                    child: TextField(
                      controller: _bobotController,
                      decoration: const InputDecoration(
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FormFieldLabel(
                    label: 'Tingkat (opsional)',
                    child: TextField(
                      controller: _difficultyController,
                      decoration: const InputDecoration(
                        hintText: 'Mudah/Sedang/Sulit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldLabel(
              label: 'Tags (opsional, dipisah koma)',
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: 'tajwid, nun mati, mim mati',
                  border: OutlineInputBorder(),
                ),
              ),
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Soal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionField(TextEditingController ctrl, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Teks opsi $label',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
