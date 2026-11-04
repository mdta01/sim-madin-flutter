// Sheet/dialog untuk add soal ke ujian dari bank soal guru.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

/// Tampilkan bottom sheet untuk pilih soal dari BankSoal + set urutan + bobot.
/// Setelah OK, panggil `addUjianSoal` dan tutup sheet.
Future<void> showAddUjianSoalSheet(
  BuildContext context,
  WidgetRef ref, {
  required String ujianId,
  required int nextUrutan,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddUjianSoalSheet(
      ujianId: ujianId,
      nextUrutan: nextUrutan,
    ),
  );
}

class _AddUjianSoalSheet extends ConsumerStatefulWidget {
  const _AddUjianSoalSheet({
    required this.ujianId,
    required this.nextUrutan,
  });
  final String ujianId;
  final int nextUrutan;

  @override
  ConsumerState<_AddUjianSoalSheet> createState() => _AddUjianSoalSheetState();
}

class _AddUjianSoalSheetState extends ConsumerState<_AddUjianSoalSheet> {
  String? _selectedBankSoalId;
  final _bobotController = TextEditingController(text: '1.0');
  final _urutanController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urutanController.text = widget.nextUrutan.toString();
  }

  @override
  void dispose() {
    _bobotController.dispose();
    _urutanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBankSoalId == null) {
      _toast('Pilih soal dulu', isError: true);
      return;
    }
    final urutan = int.tryParse(_urutanController.text);
    if (urutan == null || urutan < 1) {
      _toast('Urutan harus angka >= 1', isError: true);
      return;
    }
    final bobot = double.tryParse(_bobotController.text);
    if (bobot == null || bobot <= 0) {
      _toast('Bobot harus angka > 0', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await addUjianSoal(
        ref,
        ujianId: widget.ujianId,
        bankSoalId: _selectedBankSoalId!,
        urutan: urutan,
        bobot: bobot,
      );
      if (!mounted) return;
      _toast('✅ Soal ditambahkan');
      Navigator.of(context).pop();
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
    final bankSoalAsync = ref.watch(bankSoalGuruProvider);

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
                const Expanded(
                  child: Text(
                    'Tambah Soal ke Ujian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                const Text('Pilih dari Bank Soal:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                bankSoalAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(friendlyError(e),
                      style: const TextStyle(color: AppColors.danger)),
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bank soal masih kosong',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning)),
                            SizedBox(height: 4),
                            Text(
                                'Buat soal dulu di menu Bank Soal sebelum menambahkan ke ujian.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.warning)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: list.map((s) {
                        final typeLabel = s.type == SoalType.pg
                            ? 'PG'
                            : s.type == SoalType.isian
                                ? 'Isian'
                                : 'Essay';
                        return RadioListTile<String>(
                          value: s.id,
                          groupValue: _selectedBankSoalId,
                          onChanged: (v) =>
                              setState(() => _selectedBankSoalId = v),
                          title: Text(s.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                              '$typeLabel • ${s.code} • bobot default ${s.bobot.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 11)),
                          dense: true,
                          activeColor: AppColors.primary,
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Urutan',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _urutanController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bobot',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _bobotController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving || _selectedBankSoalId == null
                        ? null
                        : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.add),
                    label: Text(_saving ? 'Menambahkan...' : 'Tambah Soal'),
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
}
