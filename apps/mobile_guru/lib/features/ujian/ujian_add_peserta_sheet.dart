// Sheet untuk add peserta ujian (bulk assign santri dari kelas tertentu).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

/// Tampilkan bottom sheet untuk pilih santri dari kelas ujian + assign as peserta.
Future<void> showAddUjianPesertaSheet(
  BuildContext context,
  WidgetRef ref, {
  required String ujianId,
  required String kelasId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddUjianPesertaSheet(
      ujianId: ujianId,
      kelasId: kelasId,
    ),
  );
}

class _AddUjianPesertaSheet extends ConsumerStatefulWidget {
  const _AddUjianPesertaSheet({
    required this.ujianId,
    required this.kelasId,
  });
  final String ujianId;
  final String kelasId;

  @override
  ConsumerState<_AddUjianPesertaSheet> createState() =>
      _AddUjianPesertaSheetState();
}

class _AddUjianPesertaSheetState extends ConsumerState<_AddUjianPesertaSheet> {
  final Set<String> _selected = {};
  final _ruangController = TextEditingController();
  final _pengawasController = TextEditingController();
  bool _saving = false;
  bool _selectAll = false;

  @override
  void dispose() {
    _ruangController.dispose();
    _pengawasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      _toast('Pilih minimal 1 santri', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final count = await addUjianPesertaBulk(
        ref,
        ujianId: widget.ujianId,
        santriIds: _selected.toList(),
        ruang: _ruangController.text.trim().isEmpty
            ? null
            : _ruangController.text.trim(),
        pengawas: _pengawasController.text.trim().isEmpty
            ? null
            : _pengawasController.text.trim(),
      );
      if (!mounted) return;
      _toast('✅ $count peserta ditambahkan');
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

  void _toggleSelectAll(List santriList) {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selected.addAll(santriList.map((s) => s.id as String));
      } else {
        _selected.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final santriAsync = ref.watch(santriByKelasProvider(widget.kelasId));

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tambah Peserta Ujian',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_selected.length} santri dipilih',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
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
            child: santriAsync.when(
              loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Gagal load santri: ${friendlyError(e)}',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      title: 'Tidak ada santri aktif di kelas ini',
                      icon: Icons.people_outline,
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (_) => _toggleSelectAll(list),
                            activeColor: AppColors.primary,
                          ),
                          const Text('Pilih Semua',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (c, i) {
                          final s = list[i];
                          return CheckboxListTile(
                            value: _selected.contains(s.id),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(s.id);
                                } else {
                                  _selected.remove(s.id);
                                }
                                _selectAll = _selected.length == list.length;
                              });
                            },
                            title: Text(s.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: Text('NIS: ${s.nis}',
                                style: const TextStyle(fontSize: 11)),
                            dense: true,
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ruangController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ruang (opsional)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextField(
                                  controller: _pengawasController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pengawas (opsional)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _saving || _selected.isEmpty ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white))
                                  : const Icon(Icons.group_add),
                              label: Text(_saving
                                  ? 'Menambahkan...'
                                  : 'Tambah ${_selected.length} Peserta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
