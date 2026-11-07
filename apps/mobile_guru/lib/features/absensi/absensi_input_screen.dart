// Absensi input — bulk per kelas + tanggal.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class AbsensiInputScreen extends ConsumerStatefulWidget {
  const AbsensiInputScreen({super.key});
  @override
  ConsumerState<AbsensiInputScreen> createState() => _AbsensiInputScreenState();
}

class _AbsensiInputScreenState extends ConsumerState<AbsensiInputScreen> {
  String? _selectedKelasId;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _absensiData = {}; // santriId → status
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      // Hanya sampai hari ini — tidak boleh pilih tanggal masa depan.
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _setStatus(String santriId, String status) {
    setState(() => _absensiData[santriId] = status);
  }

  void _setAll(String status) {
    final newMap = <String, String>{};
    _absensiData.keys.forEach((k) => newMap[k] = status);
    setState(() => _absensiData = newMap);
  }

  /// Compare two maps by content (untuk avoid unnecessary setState).
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_selectedKelasId == null) {
      _toast('Pilih kelas dulu', isError: true);
      return;
    }
    if (_absensiData.isEmpty) {
      _toast('Tidak ada santri untuk disave', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final entries = _absensiData.entries
          .map((e) => AbsensiEntry(santriId: e.key, status: e.value))
          .toList();
      final count = await bulkCreateAbsensi(
        ref,
        kelasId: _selectedKelasId!,
        date: _selectedDate,
        entries: entries,
      );
      if (!mounted) return;
      _toast('✅ $count absensi tersimpan');
      context.pop();
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
    final santriAsync = _selectedKelasId == null
        ? const AsyncValue<List<SantriModel>>.data([])
        : ref.watch(santriByKelasProvider(_selectedKelasId!));

    // Pre-fill existing absensi jika sudah ada di tanggal + kelas tsb.
    // Tanpa ini, guru yang buka ulang absensi setelah input sebelumnya akan
    // lihat semua status reset ke "Hadir" → risiko overwrite data sebelumnya.
    if (_selectedKelasId != null) {
      final existingAsync = ref.watch(absensiByKelasDateProvider(
        (kelasId: _selectedKelasId!, date: _selectedDate),
      ));
      existingAsync.whenData((existing) {
        if (!mounted || existing.isEmpty) return;
        // Hanya pre-fill kalau santri belum punya status di _absensiData
        // (artinya ini fresh load, bukan user edit).
        final needsPrefill = _absensiData.isEmpty ||
            _absensiData.values.every((v) => v == AbsensiStatus.hadir);
        if (!needsPrefill) return;
        final prefilled = <String, String>{};
        for (final s in existing) {
          prefilled[s.santriId] = s.status;
        }
        // Merge dengan yang sudah ada (kalau ada)
        final merged = <String, String>{..._absensiData, ...prefilled};
        if (merged.length != _absensiData.length ||
            !_mapsEqual(merged, _absensiData)) {
          // Schedule setState setelah build selesai (avoid build-phase mutation).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _absensiData = merged);
          });
        }
      });

      // Initialize defaults when santri loaded (untuk santri baru yang belum
      // punya absensi record).
      ref.listen<AsyncValue<List<SantriModel>>>(
          santriByKelasProvider(_selectedKelasId!), (_, next) {
        next.whenData((list) {
          if (!mounted) return;
          final defaults = <String, String>{};
          for (final s in list) {
            defaults[s.id] = _absensiData[s.id] ?? AbsensiStatus.hadir;
          }
          if (defaults.length != _absensiData.length) {
            setState(() => _absensiData = defaults);
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Input Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pilih Tanggal',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date + kelas selector
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Tanggal: ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    Text(formatDate(_selectedDate),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                kelasAsync.when(
                  loading: () => const SizedBox(
                      height: 24,
                      child: Center(
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)))),
                  error: (e, _) =>
                      Text('Error: ${friendlyError(e)}', style: const TextStyle(color: AppColors.danger)),
                  data: (list) => PillSelector<String>(
                    items: list.map((k) => k.id).toList(),
                    selected: _selectedKelasId,
                    onSelected: (id) => setState(() {
                      _selectedKelasId = id;
                      _absensiData = {};
                    }),
                    labelOf: (id) =>
                        list.firstWhere((k) => k.id == id).name,
                  ),
                ),
              ],
            ),
          ),
          // Bulk action buttons
          if (_absensiData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  const Text('Set Semua:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: AppSpacing.sm),
                  _bulkBtn('Hadir', AppColors.success, () => _setAll(AbsensiStatus.hadir)),
                  _bulkBtn('Alfa', AppColors.danger, () => _setAll(AbsensiStatus.alfa)),
                ],
              ),
            ),
          Expanded(
            child: santriAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: friendlyError(e)),
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
                    final status = _absensiData[s.id] ?? AbsensiStatus.hadir;
                    final style = absensiStatusStyle(status);
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
                        trailing: PopupMenuButton<String>(
                          child: StatusChip(
                              label: style.label,
                              color: style.color,
                              bg: style.bg),
                          onSelected: (v) => _setStatus(s.id, v),
                          itemBuilder: (_) => AbsensiStatus.all
                              .map((st) => PopupMenuItem(
                                  value: st,
                                  child: Row(children: [
                                    StatusChip(
                                        label: absensiStatusStyle(st).label,
                                        color: absensiStatusStyle(st).color,
                                        bg: absensiStatusStyle(st).bg,
                                        compact: true),
                                  ])))
                              .toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Save button
          if (_absensiData.isNotEmpty)
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
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan Absensi'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bulkBtn(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 30)),
          child: Text(label, style: const TextStyle(fontSize: 12))),
    );
  }
}
