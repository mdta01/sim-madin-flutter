// Perkembangan create — bottom sheet form untuk input 4 jenis perkembangan.
// Kontekstual berdasarkan tab aktif: quran / kitab / akhlak / pembinaan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

/// Tampilkan sheet untuk input perkembangan sesuai tab aktif.
/// tab: 'quran' | 'kitab' | 'akhlak' | 'pembinaan'
Future<void> showPerkembanganCreateSheet(
  BuildContext context,
  WidgetRef ref, {
  required String tab,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _PerkembanganCreateSheet(tab: tab),
  );
}

class _PerkembanganCreateSheet extends ConsumerStatefulWidget {
  const _PerkembanganCreateSheet({required this.tab});
  final String tab;

  @override
  ConsumerState<_PerkembanganCreateSheet> createState() =>
      _PerkembanganCreateSheetState();
}

class _PerkembanganCreateSheetState
    extends ConsumerState<_PerkembanganCreateSheet> {
  bool _saving = false;
  // common
  String? _santriId;
  final _catatanController = TextEditingController();

  // quran
  String _quranType = 'TIQRO';
  final _surahController = TextEditingController();
  final _juzController = TextEditingController();
  final _ayatFromController = TextEditingController();
  final _ayatToController = TextEditingController();
  final _quranScoreController = TextEditingController();
  String _quranStatus = 'PROGRESS';
  final _quranTargetController = TextEditingController();

  // kitab
  String _kitabType = 'HAFALAN';
  final _kitabNameController = TextEditingController();
  final _halamanController = TextEditingController();
  final _kitabScoreController = TextEditingController();
  String _kitabStatus = 'PROGRESS';
  final _kitabTargetController = TextEditingController();

  // akhlak
  final _adabGuruController = TextEditingController(text: '0');
  final _adabOrtuController = TextEditingController(text: '0');
  final _adabTemanController = TextEditingController(text: '0');
  final _kedisiplinanController = TextEditingController(text: '0');
  final _kebersihanController = TextEditingController(text: '0');
  final _tanggungJawabController = TextEditingController(text: '0');
  final _predikatController = TextEditingController();

  // pembinaan
  String _pembinaanType = 'TEGURAN';
  final _pembinaanCategoryController = TextEditingController();
  final _pembinaanTitleController = TextEditingController();
  final _pembinaanDescController = TextEditingController();
  String _pembinaanSeverity = PembinaanSeverity.ringan;
  final _pembinaanTindakanController = TextEditingController();

  @override
  void dispose() {
    _catatanController.dispose();
    _surahController.dispose();
    _juzController.dispose();
    _ayatFromController.dispose();
    _ayatToController.dispose();
    _quranScoreController.dispose();
    _quranTargetController.dispose();
    _kitabNameController.dispose();
    _halamanController.dispose();
    _kitabScoreController.dispose();
    _kitabTargetController.dispose();
    _adabGuruController.dispose();
    _adabOrtuController.dispose();
    _adabTemanController.dispose();
    _kedisiplinanController.dispose();
    _kebersihanController.dispose();
    _tanggungJawabController.dispose();
    _predikatController.dispose();
    _pembinaanCategoryController.dispose();
    _pembinaanTitleController.dispose();
    _pembinaanDescController.dispose();
    _pembinaanTindakanController.dispose();
    super.dispose();
  }

  String get _tabLabel {
    switch (widget.tab) {
      case 'quran':
        return 'Perkembangan Quran';
      case 'kitab':
        return 'Hafalan Kitab';
      case 'akhlak':
        return 'Penilaian Akhlak';
      case 'pembinaan':
        return 'Pembinaan';
      default:
        return 'Input Perkembangan';
    }
  }

  Future<void> _submit() async {
    if (_santriId == null) {
      _toast('Pilih santri dulu', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      switch (widget.tab) {
        case 'quran':
          await _submitQuran();
          break;
        case 'kitab':
          await _submitKitab();
          break;
        case 'akhlak':
          await _submitAkhlak();
          break;
        case 'pembinaan':
          await _submitPembinaan();
          break;
      }
      if (!mounted) return;
      _toast('✅ Data tersimpan');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitQuran() async {
    await createPerkembanganQuran(
      ref,
      santriId: _santriId!,
      type: _quranType,
      surah: _surahController.text.trim().isEmpty
          ? null
          : _surahController.text.trim(),
      juz: _juzController.text.trim().isEmpty
          ? null
          : _juzController.text.trim(),
      ayatFrom: int.tryParse(_ayatFromController.text),
      ayatTo: int.tryParse(_ayatToController.text),
      score: double.tryParse(_quranScoreController.text),
      status: _quranStatus,
      target: _quranTargetController.text.trim().isEmpty
          ? null
          : _quranTargetController.text.trim(),
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
    );
  }

  Future<void> _submitKitab() async {
    if (_kitabNameController.text.trim().isEmpty) {
      throw Exception('Nama kitab wajib diisi');
    }
    await createHafalanKitab(
      ref,
      santriId: _santriId!,
      type: _kitabType,
      kitabName: _kitabNameController.text.trim(),
      halaman: int.tryParse(_halamanController.text),
      score: double.tryParse(_kitabScoreController.text),
      status: _kitabStatus,
      target: _kitabTargetController.text.trim().isEmpty
          ? null
          : _kitabTargetController.text.trim(),
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
    );
  }

  Future<void> _submitAkhlak() async {
    await createAkhlakPenilaian(
      ref,
      santriId: _santriId!,
      adabGuru: double.tryParse(_adabGuruController.text) ?? 0,
      adabOrangTua: double.tryParse(_adabOrtuController.text) ?? 0,
      adabTeman: double.tryParse(_adabTemanController.text) ?? 0,
      kedisiplinan: double.tryParse(_kedisiplinanController.text) ?? 0,
      kebersihan: double.tryParse(_kebersihanController.text) ?? 0,
      tanggungJawab: double.tryParse(_tanggungJawabController.text) ?? 0,
      predikat: _predikatController.text.trim().isEmpty
          ? null
          : _predikatController.text.trim(),
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
    );
  }

  Future<void> _submitPembinaan() async {
    if (_pembinaanTitleController.text.trim().isEmpty) {
      throw Exception('Judul wajib diisi');
    }
    if (_pembinaanCategoryController.text.trim().isEmpty) {
      throw Exception('Kategori wajib diisi');
    }
    await createPembinaan(
      ref,
      santriId: _santriId!,
      type: _pembinaanType,
      category: _pembinaanCategoryController.text.trim(),
      title: _pembinaanTitleController.text.trim(),
      description: _pembinaanDescController.text.trim().isEmpty
          ? null
          : _pembinaanDescController.text.trim(),
      severity: _pembinaanSeverity,
      tindakan: _pembinaanTindakanController.text.trim().isEmpty
          ? null
          : _pembinaanTindakanController.text.trim(),
    );
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
    // Untuk pilih santri, kita pakai list semua santri (RLS akan filter by guru).
    final santriAsync = ref.watch(santriListProvider);
    final kelasAsync = ref.watch(kelasListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text('Input $_tabLabel',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Santri picker — pilih kelas dulu lalu santri dari kelas tsb.
                FormFieldLabel(
                  label: 'Pilih Santri',
                  child: kelasAsync.when(
                    loading: () => const SizedBox(height: 30),
                    error: (e, _) => Text(friendlyError(e)),
                    data: (kelasList) {
                      return santriAsync.when(
                        loading: () => const SizedBox(height: 30),
                        error: (e, _) => Text(friendlyError(e)),
                        data: (santriList) {
                          // Filter hanya santri AKTIF.
                          final aktifSantri = santriList
                              .where((s) => s.status == SantriStatus.aktif)
                              .toList();
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            value: _santriId,
                            hint: const Text('Pilih santri'),
                            isExpanded: true,
                            items: aktifSantri
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(
                                        '${s.name} (${s.kelasName ?? '-'})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _santriId = v),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._buildTabFields(),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving || _santriId == null ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabFields() {
    switch (widget.tab) {
      case 'quran':
        return _quranFields();
      case 'kitab':
        return _kitabFields();
      case 'akhlak':
        return _akhlakFields();
      case 'pembinaan':
        return _pembinaanFields();
      default:
        return [];
    }
  }

  // ====================== Quran Fields ======================
  List<Widget> _quranFields() {
    return [
      FormFieldLabel(
        label: 'Tipe',
        child: Wrap(
          spacing: AppSpacing.xs,
          children: ['TIQRO', 'TAHFIDZ', 'TILAWAH'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _quranType == t,
              onSelected: (_) => setState(() => _quranType = t),
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
              label: 'Surah',
              child: TextField(
                controller: _surahController,
                decoration: const InputDecoration(
                    hintText: 'Al-Baqarah', border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: FormFieldLabel(
              label: 'Juz',
              child: TextField(
                controller: _juzController,
                decoration: const InputDecoration(
                    hintText: '1-30', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
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
              label: 'Ayat Dari',
              child: TextField(
                controller: _ayatFromController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FormFieldLabel(
              label: 'Ayat Sampai',
              child: TextField(
                controller: _ayatToController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: FormFieldLabel(
              label: 'Nilai',
              child: TextField(
                controller: _quranScoreController,
                decoration: const InputDecoration(
                    hintText: '0-100', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Status',
        child: Wrap(
          spacing: AppSpacing.xs,
          children: ['PROGRESS', 'SELESAI', 'ULANGI'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _quranStatus == t,
              onSelected: (_) => setState(() => _quranStatus = t),
              selectedColor: AppColors.primaryLight,
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Target (opsional)',
        child: TextField(
          controller: _quranTargetController,
          decoration: const InputDecoration(
              hintText: 'Target hafalan berikutnya...', border: OutlineInputBorder()),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Catatan (opsional)',
        child: TextField(
          controller: _catatanController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ),
    ];
  }

  // ====================== Kitab Fields ======================
  List<Widget> _kitabFields() {
    return [
      FormFieldLabel(
        label: 'Tipe',
        child: Wrap(
          spacing: AppSpacing.xs,
          children: ['HAFALAN', 'BACAAN'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _kitabType == t,
              onSelected: (_) => setState(() => _kitabType = t),
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
              label: 'Nama Kitab',
              child: TextField(
                controller: _kitabNameController,
                decoration: const InputDecoration(
                    hintText: 'Safinatun Najah', border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: FormFieldLabel(
              label: 'Hlm',
              child: TextField(
                controller: _halamanController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: FormFieldLabel(
              label: 'Nilai',
              child: TextField(
                controller: _kitabScoreController,
                decoration: const InputDecoration(
                    hintText: '0-100', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Status',
        child: Wrap(
          spacing: AppSpacing.xs,
          children: ['PROGRESS', 'SELESAI', 'ULANGI'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _kitabStatus == t,
              onSelected: (_) => setState(() => _kitabStatus = t),
              selectedColor: AppColors.primaryLight,
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Target (opsional)',
        child: TextField(
          controller: _kitabTargetController,
          decoration: const InputDecoration(
              hintText: 'Target hafalan berikutnya...', border: OutlineInputBorder()),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Catatan (opsional)',
        child: TextField(
          controller: _catatanController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ),
    ];
  }

  // ====================== Akhlak Fields ======================
  List<Widget> _akhlakFields() {
    return [
      const Text('Nilai Aspek (0-100)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      _scoreGrid([
        ('Adab ke Guru', _adabGuruController),
        ('Adab ke Ortu', _adabOrtuController),
        ('Adab ke Teman', _adabTemanController),
        ('Kedisiplinan', _kedisiplinanController),
        ('Kebersihan', _kebersihanController),
        ('Tanggung Jawab', _tanggungJawabController),
      ]),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: FormFieldLabel(
              label: 'Predikat (opsional)',
              child: TextField(
                controller: _predikatController,
                decoration: const InputDecoration(
                    hintText: 'A / B / C', border: OutlineInputBorder()),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Catatan (opsional)',
        child: TextField(
          controller: _catatanController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ),
    ];
  }

  Widget _scoreGrid(List<(String, TextEditingController)> fields) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 4.0,
      children: fields
          .map((f) => Row(
                children: [
                  Expanded(
                    child: Text(f.$1,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: f.$2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }

  // ====================== Pembinaan Fields ======================
  List<Widget> _pembinaanFields() {
    return [
      FormFieldLabel(
        label: 'Tipe Pembinaan',
        child: Wrap(
          spacing: AppSpacing.xs,
          children: ['PEMBERIAN', 'TEGURAN', 'HUKUMAN', 'APEL'].map((t) {
            return ChoiceChip(
              label: Text(t),
              selected: _pembinaanType == t,
              onSelected: (_) => setState(() => _pembinaanType = t),
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
              label: 'Kategori *',
              child: TextField(
                controller: _pembinaanCategoryController,
                decoration: const InputDecoration(
                    hintText: 'Akademik / Disiplin / Ibadah', border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 120,
            child: FormFieldLabel(
              label: 'Tingkat',
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
                value: _pembinaanSeverity,
                items: const [
                  DropdownMenuItem(
                      value: PembinaanSeverity.ringan, child: Text('Ringan')),
                  DropdownMenuItem(
                      value: PembinaanSeverity.sedang, child: Text('Sedang')),
                  DropdownMenuItem(
                      value: PembinaanSeverity.berat, child: Text('Berat')),
                ],
                onChanged: (v) => setState(() => _pembinaanSeverity = v!),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Judul *',
        child: TextField(
          controller: _pembinaanTitleController,
          decoration: const InputDecoration(
              hintText: 'Ringkasan kejadian...', border: OutlineInputBorder()),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Deskripsi (opsional)',
        child: TextField(
          controller: _pembinaanDescController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FormFieldLabel(
        label: 'Tindakan (opsional)',
        child: TextField(
          controller: _pembinaanTindakanController,
          decoration: const InputDecoration(
              hintText: 'Tindakan yang diambil...', border: OutlineInputBorder()),
        ),
      ),
    ];
  }
}
