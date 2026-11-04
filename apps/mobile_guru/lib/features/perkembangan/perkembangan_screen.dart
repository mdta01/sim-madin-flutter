// Perkembangan santri — 4 tabs (Quran/Kitab/Akhlak/Pembinaan) + create.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import 'perkembangan_create_sheet.dart';

class PerkembanganScreen extends ConsumerStatefulWidget {
  const PerkembanganScreen({super.key});
  @override
  ConsumerState<PerkembanganScreen> createState() =>
      _PerkembanganScreenState();
}

class _PerkembanganScreenState extends ConsumerState<PerkembanganScreen> {
  String _tab = 'quran';

  /// Mapping tab code ke label Indonesia untuk EmptyState dll.
  static const _tabLabels = {
    'quran': 'Quran',
    'kitab': 'Kitab',
    'akhlak': 'Akhlak',
    'pembinaan': 'Pembinaan',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perkembangan Santri')),
      // FAB kontekstual — buka sheet input sesuai tab aktif.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPerkembanganCreateSheet(context, ref, tab: _tab),
        icon: const Icon(Icons.add),
        label: Text('Input ${_tabLabels[_tab] ?? ''}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: AppColors.white,
            child: Row(
              children: [
                _tabBtn('Quran', 'quran'),
                _tabBtn('Kitab', 'kitab'),
                _tabBtn('Akhlak', 'akhlak'),
                _tabBtn('Pembinaan', 'pembinaan'),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, String value) {
    final active = _tab == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: active ? AppColors.primary : Colors.transparent,
                    width: 2)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? AppColors.primary
                      : AppColors.textMuted)),
        ),
      ),
    );
  }

  Widget _buildList() {
    switch (_tab) {
      case 'quran':
        return _quranList();
      case 'kitab':
        return _kitabList();
      case 'akhlak':
        return _akhlakList();
      case 'pembinaan':
        return _pembinaanList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _quranList() {
    final async = ref.watch(perkembanganQuranProvider);
    return _listScaffold<PerkembanganQuranModel>(
      async: async,
      itemBuilder: (item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          title: Text(item.santriName ?? 'Santri',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${item.type} • ${item.surah ?? '-'}${item.juz != null ? ' • Juz ${item.juz}' : ''}${item.ayatFrom != null ? ' • ${item.ayatFrom}${item.ayatTo != null ? '-${item.ayatTo}' : ''}' : ''}',
              style: const TextStyle(fontSize: 12)),
          trailing: item.score != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.score! >= 70
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(item.score!.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.score! >= 70
                              ? AppColors.success
                              : AppColors.danger)),
                )
              : null,
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _kitabList() {
    final async = ref.watch(hafalanKitabProvider);
    return _listScaffold<HafalanKitabModel>(
      async: async,
      itemBuilder: (item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          title: Text(item.santriName ?? 'Santri',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${item.type} • ${item.kitabName}${item.halaman != null ? ' • hlm ${item.halaman}' : ''}',
              style: const TextStyle(fontSize: 12)),
          trailing: item.score != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.score! >= 70
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(item.score!.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: item.score! >= 70
                              ? AppColors.success
                              : AppColors.danger)),
                )
              : null,
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _akhlakList() {
    final async = ref.watch(akhlakPenilaianProvider);
    return _listScaffold<AkhlakPenilaianModel>(
      async: async,
      itemBuilder: (item) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          title: Text(item.santriName ?? 'Santri',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Rata-rata: ${item.rataRata.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12)),
          trailing: item.predikat != null
              ? StatusChip(
                  label: item.predikat!,
                  color: AppColors.info,
                  bg: AppColors.infoLight,
                  compact: true)
              : null,
        ),
      ),
    );
  }

  Widget _pembinaanList() {
    final async = ref.watch(pembinaanProvider);
    return _listScaffold<PembinaanModel>(
      async: async,
      itemBuilder: (item) {
        final sevStyle = pembinaanSeverityStyle(item.severity);
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            title: Text(item.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${item.santriName ?? '-'} • ${item.type}',
                style: const TextStyle(fontSize: 12)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(
                    label: sevStyle.label,
                    color: sevStyle.color,
                    bg: sevStyle.bg,
                    compact: true),
                const SizedBox(height: 4),
                StatusChip(
                    label: item.status == PembinaanStatus.open ? 'Open' : 'Resolved',
                    color: item.status == PembinaanStatus.open
                        ? AppColors.danger
                        : AppColors.success,
                    bg: item.status == PembinaanStatus.open
                        ? AppColors.dangerLight
                        : AppColors.successLight,
                    compact: true),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _listScaffold<T>({
    required AsyncValue<List<T>> async,
    required Widget Function(T) itemBuilder,
  }) {
    return async.when(
      loading: () => const LoadingSkeleton(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
              title: 'Belum ada data ${_tabLabels[_tab] ?? _tab}',
              icon: Icons.trending_up);
        }
        return RefreshIndicator(
          onRefresh: () async {
            // Conditional invalidate berdasarkan tab aktif supaya
            // tidak refresh semua 4 provider padahal cuma 1 yang dilihat.
            switch (_tab) {
              case 'quran':
                ref.invalidate(perkembanganQuranProvider);
                break;
              case 'kitab':
                ref.invalidate(hafalanKitabProvider);
                break;
              case 'akhlak':
                ref.invalidate(akhlakPenilaianProvider);
                break;
              case 'pembinaan':
                ref.invalidate(pembinaanProvider);
                break;
            }
          },
          child: ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (c, i) => itemBuilder(list[i]),
          ),
        );
      },
    );
  }
}
