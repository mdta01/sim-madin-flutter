// Perkembangan — 4 sub-tabs (Quran, Kitab, Akhlak, Pembinaan), all read-only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class PerkembanganScreen extends ConsumerStatefulWidget {
  const PerkembanganScreen({super.key});
  @override
  ConsumerState<PerkembanganScreen> createState() => _PerkembanganScreenState();
}
class _PerkembanganScreenState extends ConsumerState<PerkembanganScreen> {
  String _tab = 'quran';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
          const Text('Perkembangan Santri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { ref.invalidate(perkembanganQuranListAdminProvider); ref.invalidate(perkembanganKitabListAdminProvider); ref.invalidate(perkembanganAkhlakListAdminProvider); ref.invalidate(perkembanganPembinaanListAdminProvider); }),
        ])),
        Container(color: AppColors.white, child: Row(children: [
          _tabBtn('Quran', 'quran'), _tabBtn('Kitab', 'kitab'), _tabBtn('Akhlak', 'akhlak'), _tabBtn('Pembinaan', 'pembinaan'),
        ])),
        Expanded(child: _buildContent()),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }
  Widget _tabBtn(String label, String value) {
    final active = _tab == value;
    return Expanded(child: InkWell(onTap: () => setState(() => _tab = value), child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2))), child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textMuted)))));
  }
  Widget _buildContent() {
    switch (_tab) {
      case 'quran': return _quranTab();
      case 'kitab': return _kitabTab();
      case 'akhlak': return _akhlakTab();
      case 'pembinaan': return _pembinaanTab();
      default: return const SizedBox.shrink();
    }
  }
  Widget _quranTab() {
    final async = ref.watch(perkembanganQuranListAdminProvider);
    return async.when(loading: () => const LoadingSkeleton(itemCount: 8), error: (e, _) => ErrorView(message: e.toString()), data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada data Quran', icon: Icons.menu_book_outlined) : _table(list, ['Santri','Type','Surah','Juz','Ayat','Score','Tanggal'], (q) => [DataCell(Text(q.santriName ?? '-', style: const TextStyle(fontSize: 13))), DataCell(Text(q.type, style: const TextStyle(fontSize: 12))), DataCell(Text(q.surah ?? '-', style: const TextStyle(fontSize: 12))), DataCell(Text(q.juz ?? '-', style: const TextStyle(fontSize: 12))), DataCell(Text(q.ayatFrom != null ? '${q.ayatFrom}${q.ayatTo != null ? '-${q.ayatTo}' : ''}' : '-', style: const TextStyle(fontSize: 12))), DataCell(q.score != null ? Text(q.score!.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: q.score! >= 70 ? AppColors.success : AppColors.danger)) : const Text('-')), DataCell(Text(formatDate(q.pertemuanDate), style: const TextStyle(fontSize: 12)))]));
  }
  Widget _kitabTab() {
    final async = ref.watch(perkembanganKitabListAdminProvider);
    return async.when(loading: () => const LoadingSkeleton(itemCount: 8), error: (e, _) => ErrorView(message: e.toString()), data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada data Kitab', icon: Icons.menu_book_outlined) : _table(list, ['Santri','Type','Kitab','Halaman','Score','Tanggal'], (k) => [DataCell(Text(k.santriName ?? '-', style: const TextStyle(fontSize: 13))), DataCell(Text(k.type, style: const TextStyle(fontSize: 12))), DataCell(Text(k.kitabName, style: const TextStyle(fontSize: 12))), DataCell(Text(k.halaman != null ? '${k.halaman}' : '-', style: const TextStyle(fontSize: 12))), DataCell(k.score != null ? Text(k.score!.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: k.score! >= 70 ? AppColors.success : AppColors.danger)) : const Text('-')), DataCell(Text(formatDate(k.pertemuanDate), style: const TextStyle(fontSize: 12)))]));
  }
  Widget _akhlakTab() {
    final async = ref.watch(perkembanganAkhlakListAdminProvider);
    return async.when(loading: () => const LoadingSkeleton(itemCount: 8), error: (e, _) => ErrorView(message: e.toString()), data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada data Akhlak', icon: Icons.volunteer_activism_outlined) : _table(list, ['Santri','Rata-rata','Predikat','Periode','Tanggal'], (a) => [DataCell(Text(a.santriName ?? '-', style: const TextStyle(fontSize: 13))), DataCell(Text(a.rataRata.toStringAsFixed(1), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: a.rataRata >= 80 ? AppColors.success : a.rataRata >= 60 ? AppColors.warning : AppColors.danger))), DataCell(a.predikat != null ? StatusChip(label: a.predikat!, color: AppColors.info, bg: AppColors.infoLight, compact: true) : const Text('-')), DataCell(Text(a.periode ?? '-', style: const TextStyle(fontSize: 12))), DataCell(Text(formatDate(a.periodeDate), style: const TextStyle(fontSize: 12)))]));
  }
  Widget _pembinaanTab() {
    final async = ref.watch(perkembanganPembinaanListAdminProvider);
    return async.when(loading: () => const LoadingSkeleton(itemCount: 8), error: (e, _) => ErrorView(message: e.toString()), data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada data Pembinaan', icon: Icons.psychology_outlined) : _table(list, ['Judul','Santri','Type','Severity','Status','Tanggal'], (p) {
      final sevColor = p.severity == 'BERAT' ? AppColors.danger : p.severity == 'SEDANG' ? AppColors.warning : AppColors.success;
      final sevBg = p.severity == 'BERAT' ? AppColors.dangerLight : p.severity == 'SEDANG' ? AppColors.warningLight : AppColors.successLight;
      return [DataCell(Text(p.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))), DataCell(Text(p.santriName ?? '-', style: const TextStyle(fontSize: 12))), DataCell(Text(p.type, style: const TextStyle(fontSize: 12))), DataCell(StatusChip(label: p.severity, color: sevColor, bg: sevBg, compact: true)), DataCell(StatusChip(label: p.status == 'OPEN' ? 'Open' : 'Resolved', color: p.status == 'OPEN' ? AppColors.danger : AppColors.success, bg: p.status == 'OPEN' ? AppColors.dangerLight : AppColors.successLight, compact: true)), DataCell(Text(formatDate(p.createdAt), style: const TextStyle(fontSize: 12)))];
    }));
  }
  Widget _table<T>(List<T> list, List<String> cols, List<DataCell> Function(T) cells) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)), child: SingleChildScrollView(child: DataTable(columns: cols.map((c) => DataColumn(label: Text(c))).toList(), rows: list.map((item) => DataRow(cells: cells(item))).toList(), headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24)));
  }
}
