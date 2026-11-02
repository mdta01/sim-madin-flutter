// Nilai input — bulk per kelas + mapel + type.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class NilaiInputScreen extends ConsumerStatefulWidget {
  const NilaiInputScreen({super.key});
  @override
  ConsumerState<NilaiInputScreen> createState() => _NilaiInputScreenState();
}

class _NilaiInputScreenState extends ConsumerState<NilaiInputScreen> {
  String? _kelasId;
  String? _mapelId;
  String _type = NilaiType.harian;
  Map<String, String> _nilaiData = {};
  bool _saving = false;

  Future<void> _save() async {
    if (_kelasId == null || _mapelId == null) {
      _toast('Pilih kelas dan mapel', isError: true);
      return;
    }
    final entries = _nilaiData.entries
        .where((e) => int.tryParse(e.value) != null && int.parse(e.value) > 0)
        .map((e) => NilaiEntry(santriId: e.key, score: double.parse(e.value)))
        .toList();
    if (entries.isEmpty) {
      _toast('Isi minimal 1 nilai', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final count = await bulkCreateNilai(
        ref,
        kelasId: _kelasId!,
        mapelId: _mapelId!,
        type: _type,
        entries: entries,
      );
      if (!mounted) return;
      _toast('✅ $count nilai tersimpan');
      context.pop();
    } catch (e) {
      if (mounted) _toast('Gagal: $e', isError: true);
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
    final santriAsync = _kelasId == null
        ? const AsyncValue<List<SantriModel>>.data([])
        : ref.watch(santriByKelasProvider(_kelasId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Input Nilai')),
      body: Column(
        children: [
          // Selectors
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kelas',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                kelasAsync.when(
                  loading: () => const SizedBox(height: 30),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => PillSelector<String>(
                    items: list.map((k) => k.id).toList(),
                    selected: _kelasId,
                    onSelected: (id) =>
                        setState(() => {_kelasId = id; _nilaiData = {};}),
                    labelOf: (id) =>
                        list.firstWhere((k) => k.id == id).name,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Mata Pelajaran',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                mapelAsync.when(
                  loading: () => const SizedBox(height: 30),
                  error: (e, _) => Text('Error: $e'),
                  data: (list) => PillSelector<String>(
                    items: list.map((m) => m.id).toList(),
                    selected: _mapelId,
                    onSelected: (id) => setState(() => _mapelId = id),
                    labelOf: (id) =>
                        list.firstWhere((m) => m.id == id).name,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Jenis Nilai',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: NilaiType.all.map((t) {
                    return ChoiceChip(
                      label: Text(t),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: AppColors.primaryLight,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // List santri + nilai input
          Expanded(
            child: santriAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Pilih kelas',
                      subtitle: 'Pilih kelas untuk melihat santri');
                }
                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemBuilder: (c, i) {
                    final s = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primary,
                          child: Text(s.initials),
                        ),
                        title: Text(s.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('NIS: ${s.nis}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: ScoreInput(
                          value: _nilaiData[s.id] ?? '',
                          onChanged: (v) => setState(() {
                            _nilaiData[s.id] = v;
                          }),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Save
          if (_nilaiData.values.any((v) =>
              int.tryParse(v) != null && int.parse(v) > 0))
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
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
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan Nilai'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
