// Rapor — generate rapor on-demand dari Nilai + Absensi + Perkembangan.
//
// Tidak pakai raporListAdminProvider (itu list rapor yang sudah di-publish).
// Di screen ini, admin pilih Santri + Tahun Ajaran → fetch semua data terkait
// (Nilai, Absensi, Perkembangan Quran/Kitab/Akhlak/Pembinaan) → tampilkan
// dalam card layout dengan 4 section.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import 'package:supabase_client/supabase_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

/// Provider untuk generate rapor on-demand berdasarkan
/// (santriId, tahunAjaranId). Kombinasi 4 tabel:
/// - Nilai (per mapel + type + score + KKM)
/// - Absensi (count by status)
/// - PerkembanganQuran + HafalanKitab + AkhlakPenilaian + Pembinaan
final raporGeneratorProvider = FutureProvider.family
    .autoDispose<RaporBundle?, RaporGeneratorParams>((ref, params) async {
  if (params.santriId == null || params.tahunAjaranId == null) return null;
  final client = ref.watch(supabaseClientProvider);

  // 1. Santri + Kelas info
  final santriRes = await client
      .from('Santri')
      .select('*, Kelas(name, code, level)')
      .eq('id', params.santriId!)
      .maybeSingle();
  SantriInfo? santriInfo;
  if (santriRes != null) {
    final s = santriRes;
    final kelas = s['Kelas'] as Map<String, dynamic>?;
    santriInfo = SantriInfo(
      id: s['id'] as String,
      nis: s['nis'] as String,
      nisn: s['nisn'] as String?,
      name: s['name'] as String,
      gender: s['gender'] as String,
      kelasName: kelas?['name'] as String? ?? '-',
      kelasCode: kelas?['code'] as String?,
      kelasLevel: kelas?['level'] as String?,
    );
  }

  // 2. Nilai per mapel
  final nilaiRes = await client
      .from('Nilai')
      .select('*, MataPelajaran(name, code, kkm)')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!)
      .order('assessmentDate', ascending: false);
  final nilaiList = (nilaiRes as List).map((r) {
    final row = r as Map<String, dynamic>;
    final mapel = row['MataPelajaran'] as Map<String, dynamic>?;
    return NilaiRow(
      id: row['id'] as String,
      mapelName: (mapel?['name'] as String?) ?? '-',
      mapelCode: mapel?['code'] as String?,
      type: row['type'] as String,
      score: (row['score'] as num).toDouble(),
      kkm: (mapel?['kkm'] as num?)?.toDouble() ?? 70.0,
      assessmentDate: DateTime.parse(row['assessmentDate'] as String),
    );
  }).toList();

  // 3. Absensi summary (count by status)
  final absensiRes = await client
      .from('Absensi')
      .select('status')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!);
  final absensiList = absensiRes as List;
  int hadir = 0, sakit = 0, izin = 0, alfa = 0;
  for (final r in absensiList) {
    final status = (r as Map<String, dynamic>)['status'] as String? ?? '';
    switch (status) {
      case AbsensiStatus.hadir:
        hadir++;
        break;
      case AbsensiStatus.sakit:
        sakit++;
        break;
      case AbsensiStatus.izin:
        izin++;
        break;
      case AbsensiStatus.alfa:
        alfa++;
        break;
    }
  }
  final absensiSummary =
      AbsensiSummary(hadir: hadir, sakit: sakit, izin: izin, alfa: alfa);

  // 4. Perkembangan Quran
  final quranRes = await client
      .from('PerkembanganQuran')
      .select('*, Guru(name)')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!)
      .order('pertemuanDate', ascending: false)
      .limit(50);
  final quranList = (quranRes as List).map((r) {
    final row = r as Map<String, dynamic>;
    final guru = row['Guru'] as Map<String, dynamic>?;
    return PerkembanganRow(
      id: row['id'] as String,
      category: 'Quran',
      type: row['type'] as String,
      title: [
        row['surah'] ?? '',
        if (row['juz'] != null) 'Juz ${row['juz']}',
        if (row['ayatFrom'] != null)
          'Ayat ${row['ayatFrom']}${row['ayatTo'] != null ? '-${row['ayatTo']}' : ''}',
      ].where((s) => s.toString().isNotEmpty).join(' • '),
      titleFallback: row['target'] as String? ?? 'Sesi Quran',
      score: (row['score'] as num?)?.toDouble(),
      status: row['status'] as String?,
      catatan: row['catatan'] as String?,
      date: row['pertemuanDate'] is String
          ? DateTime.parse(row['pertemuanDate'] as String)
          : null,
      guruName: guru?['name'] as String?,
    );
  }).toList();

  // 5. Hafalan Kitab
  final kitabRes = await client
      .from('HafalanKitab')
      .select('*, Guru(name)')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!)
      .order('pertemuanDate', ascending: false)
      .limit(50);
  final kitabList = (kitabRes as List).map((r) {
    final row = r as Map<String, dynamic>;
    final guru = row['Guru'] as Map<String, dynamic>?;
    return PerkembanganRow(
      id: row['id'] as String,
      category: 'Kitab',
      type: row['type'] as String,
      title: row['kitabName'] as String? ?? '-',
      titleFallback: row['target'] as String? ?? 'Hafalan Kitab',
      score: (row['score'] as num?)?.toDouble(),
      status: row['status'] as String?,
      catatan: row['catatan'] as String?,
      date: row['pertemuanDate'] is String
          ? DateTime.parse(row['pertemuanDate'] as String)
          : null,
      guruName: guru?['name'] as String?,
    );
  }).toList();

  // 6. Akhlak Penilaian
  final akhlakRes = await client
      .from('AkhlakPenilaian')
      .select('*, Guru(name)')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!)
      .order('periodeDate', ascending: false)
      .limit(20);
  final akhlakList = (akhlakRes as List).map((r) {
    final row = r as Map<String, dynamic>;
    final guru = row['Guru'] as Map<String, dynamic>?;
    return PerkembanganRow(
      id: row['id'] as String,
      category: 'Akhlak',
      type: 'Penilaian',
      title: 'Adab & Akhlak',
      titleFallback: row['periode'] as String? ?? 'Periode ini',
      score: (row['rataRata'] as num?)?.toDouble(),
      status: row['predikat'] as String?,
      catatan: row['catatan'] as String?,
      date: row['periodeDate'] is String
          ? DateTime.parse(row['periodeDate'] as String)
          : null,
      guruName: guru?['name'] as String?,
    );
  }).toList();

  // 7. Pembinaan
  final pembinaanRes = await client
      .from('Pembinaan')
      .select('*, Guru(name)')
      .eq('santriId', params.santriId!)
      .eq('tahunAjaranId', params.tahunAjaranId!)
      .order('createdAt', ascending: false)
      .limit(50);
  final pembinaanList = (pembinaanRes as List).map((r) {
    final row = r as Map<String, dynamic>;
    final guru = row['Guru'] as Map<String, dynamic>?;
    return PerkembanganRow(
      id: row['id'] as String,
      category: 'Pembinaan',
      type: row['type'] as String,
      title: row['title'] as String? ?? '-',
      titleFallback: row['category'] as String? ?? 'Pembinaan',
      score: null,
      status: row['status'] as String?,
      catatan: row['description'] as String?,
      date: DateTime.parse(row['createdAt'] as String),
      guruName: guru?['name'] as String?,
    );
  }).toList();

  return RaporBundle(
    santri: santriInfo,
    nilaiList: nilaiList,
    absensi: absensiSummary,
    perkembanganQuran: quranList,
    perkembanganKitab: kitabList,
    perkembanganAkhlak: akhlakList,
    perkembanganPembinaan: pembinaanList,
  );
});

class RaporGeneratorParams {
  const RaporGeneratorParams({this.santriId, this.tahunAjaranId});
  final String? santriId;
  final String? tahunAjaranId;

  @override
  bool operator ==(Object other) =>
      other is RaporGeneratorParams &&
      other.santriId == santriId &&
      other.tahunAjaranId == tahunAjaranId;

  @override
  int get hashCode => Object.hash(santriId, tahunAjaranId);
}

class SantriInfo {
  const SantriInfo({
    required this.id,
    required this.nis,
    this.nisn,
    required this.name,
    required this.gender,
    required this.kelasName,
    this.kelasCode,
    this.kelasLevel,
  });
  final String id;
  final String nis;
  final String? nisn;
  final String name;
  final String gender;
  final String kelasName;
  final String? kelasCode;
  final String? kelasLevel;
}

class NilaiRow {
  const NilaiRow({
    required this.id,
    required this.mapelName,
    this.mapelCode,
    required this.type,
    required this.score,
    required this.kkm,
    required this.assessmentDate,
  });
  final String id;
  final String mapelName;
  final String? mapelCode;
  final String type;
  final double score;
  final double kkm;
  final DateTime assessmentDate;

  bool get lulus => score >= kkm;
}

class AbsensiSummary {
  const AbsensiSummary({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alfa,
  });
  final int hadir;
  final int sakit;
  final int izin;
  final int alfa;

  int get total => hadir + sakit + izin + alfa;
}

class PerkembanganRow {
  const PerkembanganRow({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.titleFallback,
    this.score,
    this.status,
    this.catatan,
    this.date,
    this.guruName,
  });
  final String id;
  final String category; // Quran | Kitab | Akhlak | Pembinaan
  final String type;
  final String title;
  final String titleFallback;
  final double? score;
  final String? status;
  final String? catatan;
  final DateTime? date;
  final String? guruName;
}

class RaporBundle {
  const RaporBundle({
    this.santri,
    required this.nilaiList,
    required this.absensi,
    required this.perkembanganQuran,
    required this.perkembanganKitab,
    required this.perkembanganAkhlak,
    required this.perkembanganPembinaan,
  });
  final SantriInfo? santri;
  final List<NilaiRow> nilaiList;
  final AbsensiSummary absensi;
  final List<PerkembanganRow> perkembanganQuran;
  final List<PerkembanganRow> perkembanganKitab;
  final List<PerkembanganRow> perkembanganAkhlak;
  final List<PerkembanganRow> perkembanganPembinaan;
}

class RaporScreen extends ConsumerStatefulWidget {
  const RaporScreen({super.key});
  @override
  ConsumerState<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends ConsumerState<RaporScreen> {
  String? _santriId;
  String? _tahunAjaranId;
  final _santriSearchCtrl = TextEditingController();
  String _santriSearch = '';

  @override
  void dispose() {
    _santriSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final santriAsync = ref.watch(santriListProvider);
    final taAsync = ref.watch(tahunAjaranListProvider);
    final params = RaporGeneratorParams(
      santriId: _santriId,
      tahunAjaranId: _tahunAjaranId,
    );
    final raporAsync = ref.watch(raporGeneratorProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header + selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.description_outlined,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Rapor Generator', style: AppTextStyles.h3),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.invalidate(santriListProvider);
                        ref.invalidate(tahunAjaranListProvider);
                        ref.invalidate(raporGeneratorProvider(params));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FormFieldLabel(
                        label: 'Santri',
                        child: santriAsync.when(
                          loading: () => const SizedBox(
                              height: 48,
                              child: Center(
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)))),
                          error: (e, _) => Text('Gagal load santri: ${friendlyError(e)}',
                              style: TextStyle(color: AppColors.danger)),
                          data: (list) {
                            final filtered = _santriSearch.isEmpty
                                ? list
                                : list
                                    .where((s) =>
                                        s.name.toLowerCase().contains(_santriSearch) ||
                                        s.nis.toLowerCase().contains(_santriSearch))
                                    .toList();
                            return DropdownButtonFormField<String>(
                              value: _santriId,
                              hint: const Text('Pilih Santri'),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  isDense: true, border: OutlineInputBorder()),
                              items: filtered
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text('${s.name} (${s.nis})',
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _santriId = v),
                              menuMaxHeight: 320,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FormFieldLabel(
                        label: 'Tahun Ajaran',
                        child: taAsync.when(
                          loading: () => const SizedBox(
                              height: 48,
                              child: Center(
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)))),
                          error: (e, _) => Text('Gagal load TA: ${friendlyError(e)}',
                              style: TextStyle(color: AppColors.danger)),
                          data: (list) => DropdownButtonFormField<String>(
                            value: _tahunAjaranId,
                            hint: const Text('Pilih TA'),
                            isExpanded: true,
                            decoration: const InputDecoration(
                                isDense: true, border: OutlineInputBorder()),
                            items: list
                                .map((ta) => DropdownMenuItem(
                                      value: ta.id,
                                      child: Text('${ta.code} • ${ta.name}',
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _tahunAjaranId = v),
                            menuMaxHeight: 320,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: (_santriId == null || _tahunAjaranId == null)
                            ? null
                            : () {
                                ref.invalidate(
                                    raporGeneratorProvider(params));
                                _toast('✅ Rapor di-generate');
                              },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Generate Rapor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Santri quick filter (small search box)
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _santriSearchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Filter santri by nama/NIS...',
                      prefixIcon: Icon(Icons.filter_list, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _santriSearch = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: (_santriId == null || _tahunAjaranId == null)
                ? const ModernEmptyState(
                    title: 'Pilih Santri & Tahun Ajaran',
                    subtitle:
                        'Pilih santri dan tahun ajaran di atas, lalu klik "Generate Rapor" untuk menampilkan nilai, absensi, dan perkembangan.',
                    icon: Icons.description_outlined,
                  )
                : raporAsync.when(
                    loading: () =>
                        const ModernLoadingSkeleton(itemCount: 6, itemHeight: 90),
                    error: (e, _) => ModernErrorView(
                      message: friendlyError(e),
                      onRetry: () =>
                          ref.invalidate(raporGeneratorProvider(params)),
                    ),
                    data: (bundle) => bundle == null
                        ? const ModernEmptyState(
                            title: 'Data tidak ditemukan',
                            icon: Icons.error_outline)
                        : _buildRaporBody(bundle),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildRaporBody(RaporBundle bundle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Info Santri
          _section(
            icon: Icons.person_outline,
            title: 'Section 1: Info Santri',
            child: _buildSantriInfo(bundle.santri),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section 2: Nilai per mapel
          _section(
            icon: Icons.grade_outlined,
            title: 'Section 2: Nilai per Mata Pelajaran',
            subtitle: '${bundle.nilaiList.length} record nilai',
            child: _buildNilaiTable(bundle.nilaiList),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section 3: Absensi summary
          _section(
            icon: Icons.check_circle_outline,
            title: 'Section 3: Ringkasan Absensi',
            subtitle: 'Total ${bundle.absensi.total} record',
            child: _buildAbsensiSummary(bundle.absensi),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section 4: Perkembangan
          _section(
            icon: Icons.trending_up,
            title: 'Section 4: Perkembangan Santri',
            subtitle:
                'Quran: ${bundle.perkembanganQuran.length} • Kitab: ${bundle.perkembanganKitab.length} • Akhlak: ${bundle.perkembanganAkhlak.length} • Pembinaan: ${bundle.perkembanganPembinaan.length}',
            child: _buildPerkembangan(bundle),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildSantriInfo(SantriInfo? s) {
    if (s == null) {
      return Text('Data santri tidak ditemukan.',
          style: AppTextStyles.body2.copyWith(color: AppColors.danger));
    }
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _infoTile('Nama', s.name),
              _infoTile('NIS', s.nis, mono: true),
              if (s.nisn != null) _infoTile('NISN', s.nisn!, mono: true),
              _infoTile('Gender', SantriGender.label(s.gender)),
              _infoTile('Kelas', s.kelasName),
              if (s.kelasLevel != null) _infoTile('Level', s.kelasLevel!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null)),
      ],
    );
  }

  Widget _buildNilaiTable(List<NilaiRow> list) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: ModernEmptyState(
          title: 'Belum ada nilai',
          subtitle: 'Belum ada record nilai untuk santri + tahun ajaran ini.',
          icon: Icons.grade_outlined,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Mapel')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('KKM')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Tanggal')),
          ],
          rows: list
              .map((n) => DataRow(cells: [
                    DataCell(Text(n.mapelName,
                        style: AppTextStyles.body2
                            .copyWith(fontWeight: FontWeight.w500))),
                    DataCell(StatusChip(
                      label: n.type,
                      color: AppColors.info,
                      bg: AppColors.infoLight,
                      compact: true,
                    )),
                    DataCell(Text(n.score.toStringAsFixed(0),
                        style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: n.lulus ? AppColors.success : AppColors.danger))),
                    DataCell(Text(n.kkm.toStringAsFixed(0),
                        style: AppTextStyles.body3.copyWith(color: AppColors.textMuted))),
                    DataCell(StatusChip(
                      label: n.lulus ? 'LULUS' : 'BELUM',
                      color: n.lulus ? AppColors.success : AppColors.danger,
                      bg: n.lulus ? AppColors.successLight : AppColors.dangerLight,
                      compact: true,
                    )),
                    DataCell(Text(formatDate(n.assessmentDate),
                        style: AppTextStyles.body3.copyWith(color: AppColors.textMuted))),
                  ]))
              .toList(),
          headingRowHeight: 44,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          columnSpacing: 24,
          horizontalMargin: 12,
        ),
      ),
    );
  }

  Widget _buildAbsensiSummary(AbsensiSummary a) {
    return Row(
      children: [
        Expanded(
            child: _absensiCard('Hadir', a.hadir, AppColors.success,
                AppColors.successLight, Icons.check_circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _absensiCard('Sakit', a.sakit, AppColors.warning,
                AppColors.warningLight, Icons.sick)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _absensiCard('Izin', a.izin, AppColors.info,
                AppColors.infoLight, Icons.event_available)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _absensiCard('Alfa', a.alfa, AppColors.danger,
                AppColors.dangerLight, Icons.cancel)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _absensiCard('Total', a.total, AppColors.primary,
                AppColors.primaryLight, Icons.calculate)),
      ],
    );
  }

  Widget _absensiCard(
      String label, int value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text('$value',
              style: AppTextStyles.h2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildPerkembangan(RaporBundle bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _perkembanganSubSection('Quran', bundle.perkembanganQuran, Icons.menu_book),
        const SizedBox(height: AppSpacing.md),
        _perkembanganSubSection('Kitab', bundle.perkembanganKitab, Icons.auto_stories),
        const SizedBox(height: AppSpacing.md),
        _perkembanganSubSection('Akhlak', bundle.perkembanganAkhlak, Icons.volunteer_activism),
        const SizedBox(height: AppSpacing.md),
        _perkembanganSubSection('Pembinaan', bundle.perkembanganPembinaan, Icons.psychology),
      ],
    );
  }

  Widget _perkembanganSubSection(
      String title, List<PerkembanganRow> list, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(title, style: AppTextStyles.label),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('${list.length}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('Tidak ada record $title.',
                style: AppTextStyles.body3.copyWith(color: AppColors.textMuted)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: list
                  .map((r) => ListTile(
                        dense: true,
                        leading: r.score != null
                            ? CircleAvatar(
                                radius: 16,
                                backgroundColor: (r.score! >= 70
                                        ? AppColors.successLight
                                        : AppColors.dangerLight),
                                child: Text(r.score!.toStringAsFixed(0),
                                    style: AppTextStyles.label.copyWith(
                                        color: r.score! >= 70
                                            ? AppColors.success
                                            : AppColors.danger,
                                        fontSize: 12)),
                              )
                            : CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.infoLight,
                                child: Icon(icon, size: 14, color: AppColors.info),
                              ),
                        title: Text(r.title.isNotEmpty ? r.title : r.titleFallback,
                            style: AppTextStyles.body2),
                        subtitle: Text(
                          [
                            r.type,
                            if (r.guruName != null) 'oleh ${r.guruName}',
                            if (r.date != null) formatDate(r.date),
                            if (r.catatan != null) r.catatan,
                          ].join(' • '),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: r.status != null
                            ? StatusChip(
                                label: r.status!,
                                color: AppColors.info,
                                bg: AppColors.infoLight,
                                compact: true,
                              )
                            : null,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }
}
