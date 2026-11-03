// Santri list per kelas (Tab 2).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class SantriListScreen extends ConsumerStatefulWidget {
  const SantriListScreen({super.key});
  @override
  ConsumerState<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends ConsumerState<SantriListScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _selectedKelasId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kelasAsync = ref.watch(kelasListProvider);
    final santriAsync = _selectedKelasId == null
        ? const AsyncValue<List<SantriModel>>.data([])
        : ref.watch(santriByKelasProvider(_selectedKelasId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Santri')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: kelasAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (list) => list.isEmpty
                  ? const Text('Belum ada kelas. Tambah dari admin desktop.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12))
                  : PillSelector<String>(
                      items: list.map((k) => k.id).toList(),
                      selected: _selectedKelasId,
                      onSelected: (id) =>
                          setState(() => _selectedKelasId = id),
                      labelOf: (id) =>
                          list.firstWhere((k) => k.id == id).name,
                    ),
            ),
          ),
          if (_selectedKelasId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NIS...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: santriAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                      santriByKelasProvider(_selectedKelasId!))),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada santri',
                      subtitle: 'Pilih kelas untuk melihat santri');
                }
                final filtered = _query.isEmpty
                    ? list
                    : list
                        .where((s) =>
                            s.name.toLowerCase().contains(_query) ||
                            s.nis.toLowerCase().contains(_query))
                        .toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(santriByKelasProvider(_selectedKelasId!));
                    await ref.read(
                        santriByKelasProvider(_selectedKelasId!).future);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    itemBuilder: (c, i) {
                      final s = filtered[i];
                      return SantriInfoCard(
                        name: s.name,
                        nis: s.nis,
                        kelas: s.kelasName,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
