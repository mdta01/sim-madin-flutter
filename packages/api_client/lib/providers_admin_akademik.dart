// ============================================================================
// SIM MADIN — Akademik Providers (Phase 6c — admin_desktop)
// ============================================================================
// Query + Mutation providers untuk modul akademik:
//   Jadwal, Pertemuan, Absensi, Nilai, Materi, Tugas,
//   Ujian, BankSoal, Kompetensi, Rapor, Perkembangan
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'query_providers.dart';
import 'query_providers_admin.dart';

// ===========================================================================
// JADWAL
// ===========================================================================

final jadwalListAdminProvider =
    FutureProvider.family<List<JadwalModel>, String?>((ref, taId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Jadwal').select('*, Kelas(*), MataPelajaran(*), Guru(*)');
  if (taId != null) q = q.eq('tahunAjaranId', taId);
  final res = await q.order('dayOfWeek').order('startTime');
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return JadwalModel.fromJson({
      ...row,
      'kelasName': (row['Kelas'] ?? row['kelas'])?['name'],
      'kelasCode': (row['Kelas'] ?? row['kelas'])?['code'],
      'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'],
      'mapelCode': (row['MataPelajaran'] ?? row['mapel'])?['code'],
      'guruName': (row['Guru'] ?? row['guru'])?['name'],
    });
  }).toList();
});

Future<JadwalModel> adminCreateJadwal(WidgetRef ref, {required String tahunAjaranId, required String semesterId, required String kelasId, required String mapelId, required String guruId, required int dayOfWeek, required String startTime, required String endTime}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Jadwal').insert({'tahunAjaranId': tahunAjaranId, 'semesterId': semesterId, 'kelasId': kelasId, 'mapelId': mapelId, 'guruId': guruId, 'dayOfWeek': dayOfWeek, 'startTime': startTime, 'endTime': endTime}).select().single();
  ref.invalidate(jadwalListAdminProvider);
  return JadwalModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeleteJadwal(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Jadwal').delete().eq('id', id);
  ref.invalidate(jadwalListAdminProvider);
}

// ===========================================================================
// PERTEMUAN
// ===========================================================================

final pertemuanListAdminProvider = FutureProvider<List<PertemuanModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Pertemuan').select('*, Kelas(*), MataPelajaran(*), Guru(*)').order('date', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return PertemuanModel.fromJson({...row, 'kelasName': (row['Kelas'] ?? row['kelas'])?['name'], 'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

Future<void> adminDeletePertemuan(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Pertemuan').delete().eq('id', id);
  ref.invalidate(pertemuanListAdminProvider);
}

// ===========================================================================
// ABSENSI
// ===========================================================================

final absensiListAdminProvider = FutureProvider.family<List<AbsensiModel>, AbsensiFilterParams>((ref, params) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Absensi').select('*, Santri(*), Kelas(*)');
  if (params.kelasId != null) q = q.eq('kelasId', params.kelasId!);
  if (params.status != null && params.status != 'ALL') q = q.eq('status', params.status!);
  if (params.date != null) {
    final dayStart = DateTime(params.date!.year, params.date!.month, params.date!.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    q = q.gte('date', dayStart.toIso8601String()).lt('date', dayEnd.toIso8601String());
  }
  final res = await q.order('date', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return AbsensiModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'santriNis': (row['Santri'] ?? row['santri'])?['nis'], 'kelasName': (row['Kelas'] ?? row['kelas'])?['name']});
  }).toList();
});

class AbsensiFilterParams {
  const AbsensiFilterParams({this.kelasId, this.status, this.date});
  final String? kelasId;
  final String? status;
  final DateTime? date;
}

Future<void> adminDeleteAbsensi(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Absensi').delete().eq('id', id);
  ref.invalidate(absensiListAdminProvider);
}

// ===========================================================================
// NILAI
// ===========================================================================

final nilaiListAdminProvider = FutureProvider.family<List<NilaiModel>, NilaiFilterParams>((ref, params) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Nilai').select('*, Santri(*), Kelas(*), MataPelajaran(*)');
  if (params.kelasId != null) q = q.eq('kelasId', params.kelasId!);
  if (params.mapelId != null) q = q.eq('mapelId', params.mapelId!);
  if (params.type != null && params.type != 'ALL') q = q.eq('type', params.type!);
  final res = await q.order('assessmentDate', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return NilaiModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'santriNis': (row['Santri'] ?? row['santri'])?['nis'], 'kelasName': (row['Kelas'] ?? row['kelas'])?['name'], 'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'], 'mapelKkm': (row['MataPelajaran'] ?? row['mapel'])?['kkm']});
  }).toList();
});

class NilaiFilterParams {
  const NilaiFilterParams({this.kelasId, this.mapelId, this.type});
  final String? kelasId;
  final String? mapelId;
  final String? type;
}

Future<void> adminDeleteNilai(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Nilai').delete().eq('id', id);
  ref.invalidate(nilaiListAdminProvider);
}

// ===========================================================================
// MATERI
// ===========================================================================

final materiListAdminProvider = FutureProvider<List<MateriModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Materi').select('*, MataPelajaran(*), Kelas(*), Guru(*)').filter('deletedAt', 'is', null).order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return MateriModel.fromJson({...row, 'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'], 'kelasName': (row['Kelas'] ?? row['kelas'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

Future<void> adminDeleteMateri(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Materi').update({'deletedAt': DateTime.now().toIso8601String()}).eq('id', id);
  ref.invalidate(materiListAdminProvider);
}

// ===========================================================================
// TUGAS
// ===========================================================================

final tugasListAdminProvider = FutureProvider<List<TugasModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Tugas').select('*, MataPelajaran(*), Kelas(*), Guru(*)').filter('deletedAt', 'is', null).order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return TugasModel.fromJson({...row, 'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'], 'kelasName': (row['Kelas'] ?? row['kelas'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

Future<void> adminDeleteTugas(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Tugas').update({'deletedAt': DateTime.now().toIso8601String()}).eq('id', id);
  ref.invalidate(tugasListAdminProvider);
}

// ===========================================================================
// UJIAN
// ===========================================================================

final ujianListAdminProvider = FutureProvider<List<UjianModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Ujian').select('*, MataPelajaran(*), Kelas(*), Guru(*)').filter('deletedAt', 'is', null).order('startTime', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return UjianModel.fromJson({...row, 'mapelName': (row['MataPelajaran'] ?? row['mapel'])?['name'], 'kelasName': (row['Kelas'] ?? row['kelas'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

Future<UjianModel> adminCreateUjian(WidgetRef ref, {required String tahunAjaranId, required String semesterId, required String mapelId, required String kelasId, required String guruId, required String title, required String type, String? description, DateTime? startTime, DateTime? endTime, int durationMnt = 90, double maxScore = 100, double passingScore = 70, bool isPublished = false}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Ujian').insert({'tahunAjaranId': tahunAjaranId, 'semesterId': semesterId, 'mapelId': mapelId, 'kelasId': kelasId, 'guruId': guruId, 'title': title, 'type': type, if (description != null) 'description': description, if (startTime != null) 'startTime': startTime.toIso8601String(), if (endTime != null) 'endTime': endTime.toIso8601String(), 'durationMnt': durationMnt, 'maxScore': maxScore, 'passingScore': passingScore, 'isPublished': isPublished}).select().single();
  ref.invalidate(ujianListAdminProvider);
  return UjianModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeleteUjian(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Ujian').update({'deletedAt': DateTime.now().toIso8601String()}).eq('id', id);
  ref.invalidate(ujianListAdminProvider);
}

// ===========================================================================
// BANK SOAL
// ===========================================================================

final bankSoalListAdminProvider = FutureProvider<List<BankSoalModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('BankSoal').select().order('createdAt', ascending: false);
  return (res as List).map((r) => BankSoalModel.fromJson(r as Map<String, dynamic>)).toList();
});

Future<BankSoalModel> adminCreateBankSoal(WidgetRef ref, {required String mapelId, required String tahunAjaranId, required String guruId, required String code, required String type, required String question, String? options, String? correctAnswer, String? answerKey, double bobot = 1.0, String? difficulty}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('BankSoal').insert({'mapelId': mapelId, 'tahunAjaranId': tahunAjaranId, 'guruId': guruId, 'code': code, 'type': type, 'question': question, if (options != null) 'options': options, if (correctAnswer != null) 'correctAnswer': correctAnswer, if (answerKey != null) 'answerKey': answerKey, 'bobot': bobot, if (difficulty != null) 'difficulty': difficulty}).select().single();
  ref.invalidate(bankSoalListAdminProvider);
  return BankSoalModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeleteBankSoal(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('BankSoal').delete().eq('id', id);
  ref.invalidate(bankSoalListAdminProvider);
}

// ===========================================================================
// KOMPETENSI
// ===========================================================================

final kompetensiListAdminProvider = FutureProvider<List<KompetensiModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Kompetensi').select().order('sortOrder');
  return (res as List).map((r) => KompetensiModel.fromJson(r as Map<String, dynamic>)).toList();
});

Future<KompetensiModel> adminCreateKompetensi(WidgetRef ref, {required String mapelId, required String tahunAjaranId, required String code, required String name, String? description, String category = 'UMUM', int sortOrder = 0}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Kompetensi').insert({'mapelId': mapelId, 'tahunAjaranId': tahunAjaranId, 'code': code, 'name': name, if (description != null) 'description': description, 'category': category, 'sortOrder': sortOrder}).select().single();
  ref.invalidate(kompetensiListAdminProvider);
  return KompetensiModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeleteKompetensi(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Kompetensi').delete().eq('id', id);
  ref.invalidate(kompetensiListAdminProvider);
}

// ===========================================================================
// RAPOR (read-only list for admin)
// ===========================================================================

final raporListAdminProvider = FutureProvider<List<RaporAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Rapor').select('*, Santri(name, nis, Kelas(name)), TahunAjaran(code), Semester(name)').order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final santri = row['Santri'] as Map<String, dynamic>?;
    final kelas = santri?['Kelas'] as Map<String, dynamic>?;
    final ta = row['TahunAjaran'] as Map<String, dynamic>?;
    final sem = row['Semester'] as Map<String, dynamic>?;
    return RaporAdminModel(
      id: row['id'] as String,
      santriName: santri?['name'] ?? '-',
      santriNis: santri?['nis'] ?? '-',
      kelasName: kelas?['name'] ?? '-',
      tahunAjaranCode: ta?['code'] ?? '-',
      semesterName: sem?['name'] ?? '-',
      published: (row['published'] as bool?) ?? false,
      publishedAt: row['publishedAt'] is String ? DateTime.parse(row['publishedAt'] as String) : null,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }).toList();
});

class RaporAdminModel {
  const RaporAdminModel({required this.id, required this.santriName, required this.santriNis, required this.kelasName, required this.tahunAjaranCode, required this.semesterName, required this.published, this.publishedAt, required this.createdAt});
  final String id;
  final String santriName;
  final String santriNis;
  final String kelasName;
  final String tahunAjaranCode;
  final String semesterName;
  final bool published;
  final DateTime? publishedAt;
  final DateTime createdAt;
}

// ===========================================================================
// PERKEMBANGAN (read-only list for admin — all 4 types combined)
// ===========================================================================

final perkembanganQuranListAdminProvider = FutureProvider<List<PerkembanganQuranModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('PerkembanganQuran').select('*, Santri(name, nis), Guru(name)').order('pertemuanDate', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return PerkembanganQuranModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

final perkembanganKitabListAdminProvider = FutureProvider<List<HafalanKitabModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('HafalanKitab').select('*, Santri(name, nis), Guru(name)').order('pertemuanDate', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return HafalanKitabModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

final perkembanganAkhlakListAdminProvider = FutureProvider<List<AkhlakPenilaianModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('AkhlakPenilaian').select('*, Santri(name, nis), Guru(name)').order('periodeDate', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return AkhlakPenilaianModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

final perkembanganPembinaanListAdminProvider = FutureProvider<List<PembinaanModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Pembinaan').select('*, Santri(name, nis), Guru(name)').order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return PembinaanModel.fromJson({...row, 'santriName': (row['Santri'] ?? row['santri'])?['name'], 'guruName': (row['Guru'] ?? row['guru'])?['name']});
  }).toList();
});

// ===========================================================================
// Kompetensi model (port from Prisma — not in shared yet)
// ===========================================================================

class KompetensiModel {
  const KompetensiModel({required this.id, required this.mapelId, required this.tahunAjaranId, required this.code, required this.name, this.description, this.category = 'UMUM', this.sortOrder = 0, this.isActive = true, required this.createdAt, required this.updatedAt});
  final String id;
  final String mapelId;
  final String tahunAjaranId;
  final String code;
  final String name;
  final String? description;
  final String category;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KompetensiModel.fromJson(Map<String, dynamic> j) => KompetensiModel(
    id: j['id'] as String,
    mapelId: j['mapelId'] as String,
    tahunAjaranId: j['tahunAjaranId'] as String,
    code: j['code'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    category: (j['category'] as String?) ?? 'UMUM',
    sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    isActive: (j['isActive'] as bool?) ?? true,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}
