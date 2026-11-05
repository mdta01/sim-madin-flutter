// ============================================================================
// SIM MADIN — Mutation Providers (Phase 4 — mobile_guru)
// ============================================================================
// Mutations untuk akademik guru:
//   - bulkCreateAbsensi() — input absensi sekaligus 1 kelas
//   - bulkCreateNilai() — input nilai sekaligus 1 kelas
//   - createMateri(), updateMateri(), deleteMateri()
//   - createTugas(), updateTugas(), deleteTugas()
//   - gradePengumpulanTugas() — beri nilai + feedback
//   - createPertemuan(), completePertemuan()
//   - createUjian(), publishUjian()
//   - createBankSoal()
//   - addUjianSoal() — add soal to ujian
//   - addUjianPeserta() — bulk assign santri as peserta
//   - createPerkembanganQuran(), createHafalanKitab(), createAkhlakPenilaian(),
//     createPembinaan()
//   - createChatRoom(), sendChatMessage()
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import all from query_providers.dart so we can invalidate Phase 2 providers
// (santriListProvider, nilaiRecentProvider, absensiRecentProvider, dll)
// after guru mutations.
import 'query_providers.dart';
// Import all guru query providers (materiGuruProvider, tugasGuruProvider,
// ujianGuruProvider, perkembanganQuranProvider, chatRoomsGuruProvider, dll).
import 'query_providers_guru.dart';
// Import storage service (for delete operations on materi/tugas/ujian files).
import 'storage_service.dart';

/// Helper untuk dapatkan guruId dari user yang login (via Wali.userId
/// match). Return null kalau user bukan guru.
Future<String?> _getCurrentGuruId(WidgetRef ref) async {
  final client = ref.read(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;
  final res = await client
      .from('Guru')
      .select('id')
      .eq('userId', user.id)
      .maybeSingle();
  return res?['id'] as String?;
}

/// Helper untuk dapatkan tahunAjaranId aktif.
Future<String?> _getActiveTahunAjaranId(SupabaseClient client) async {
  final res = await client
      .from('TahunAjaran')
      .select('id')
      .eq('isActive', true)
      .limit(1)
      .maybeSingle();
  return res?['id'] as String?;
}

/// Helper untuk dapatkan semesterId aktif.
Future<String?> _getActiveSemesterId(SupabaseClient client) async {
  final res = await client
      .from('Semester')
      .select('id')
      .eq('isActive', true)
      .limit(1)
      .maybeSingle();
  return res?['id'] as String?;
}

// ---------------------------------------------------------------------------
// Absensi bulk
// ---------------------------------------------------------------------------

class AbsensiEntry {
  const AbsensiEntry({
    required this.santriId,
    required this.status,
    this.note,
  });
  final String santriId;
  final String status;
  final String? note;
}

/// Bulk insert absensi untuk 1 kelas di tanggal tertentu.
/// Akan upsert (on conflict update) berdasarkan [santriId, date, tahunAjaranId].
Future<int> bulkCreateAbsensi(
  WidgetRef ref, {
  required String kelasId,
  required DateTime date,
  required List<AbsensiEntry> entries,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  final taId = await _getActiveTahunAjaranId(client);
  if (taId == null) {
    throw Exception('Tidak ada tahun ajaran aktif. Aktifkan dulu di admin.');
  }

  final dayStart = DateTime(date.year, date.month, date.day);
  final rows = entries.map((e) {
    return {
      'tahunAjaranId': taId,
      'santriId': e.santriId,
      'kelasId': kelasId,
      'date': dayStart.toIso8601String(),
      'status': e.status,
      if (e.note != null && e.note!.isNotEmpty) 'note': e.note,
      if (guruId != null) 'recordedByGuruId': guruId,
    };
  }).toList();

  // Upsert: kalau sudah ada absensi untuk santri+date, update status-nya.
  final res = await client
      .from('Absensi')
      .upsert(rows, onConflict: '"santriId",date,"tahunAjaranId"')
      .select();

  // Invalidate specific instance of family provider.
  ref.invalidate(absensiByKelasDateProvider(
    (kelasId: kelasId, date: date),
  ));
  return (res as List).length;
}

// ---------------------------------------------------------------------------
// Nilai bulk
// ---------------------------------------------------------------------------

class NilaiEntry {
  const NilaiEntry({
    required this.santriId,
    required this.score,
  });
  final String santriId;
  final double score;
}

/// Bulk insert nilai untuk 1 kelas + mapel + type.
Future<int> bulkCreateNilai(
  WidgetRef ref, {
  required String kelasId,
  required String mapelId,
  required String type, // NilaiType.*
  required List<NilaiEntry> entries,
  String? semesterId,
  String? notes,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  final taId = await _getActiveTahunAjaranId(client);
  if (taId == null) {
    throw Exception('Tidak ada tahun ajaran aktif.');
  }
  final semId = semesterId ?? await _getActiveSemesterId(client);
  if (semId == null) {
    throw Exception('Tidak ada semester aktif.');
  }

  final rows = entries.map((e) {
    return {
      'tahunAjaranId': taId,
      'semesterId': semId,
      'santriId': e.santriId,
      'kelasId': kelasId,
      'mapelId': mapelId,
      'type': type,
      'score': e.score,
      if (guruId != null) 'guruId': guruId,
      if (notes != null) 'notes': notes,
      'assessmentDate': DateTime.now().toIso8601String(),
    };
  }).toList();

  // Upsert by unique constraint [santriId, mapelId, type, semesterId, tahunAjaranId]
  final res = await client.from('Nilai').upsert(rows, onConflict:
      '"santriId","mapelId",type,"semesterId","tahunAjaranId"').select();

  ref.invalidate(nilaiRecentProvider);
  return (res as List).length;
}

// ---------------------------------------------------------------------------
// Materi CRUD
// ---------------------------------------------------------------------------

Future<MateriModel> createMateri(
  WidgetRef ref, {
  required String mapelId,
  required String kelasId,
  required String title,
  String? description,
  required String type, // MateriType.*
  String? fileUrl,
  String? filePath,
  String? externalUrl,
  int? pertemuan,
  bool isPublished = false,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'mapelId': mapelId,
    'kelasId': kelasId,
    'guruId': guruId,
    'title': title,
    if (description != null) 'description': description,
    'type': type,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (filePath != null) 'filePath': filePath,
    if (externalUrl != null) 'externalUrl': externalUrl,
    if (pertemuan != null) 'pertemuan': pertemuan,
    'isPublished': isPublished,
    if (isPublished) 'publishedAt': DateTime.now().toIso8601String(),
    'createdById': client.auth.currentUser?.id,
  };

  final res = await client
      .from('Materi')
      .insert(body)
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .single();
  final materi = MateriModel.fromJson({
    ...res,
    'mapelName': res['MataPelajaran']?['name'],
    'kelasName': res['Kelas']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
  ref.invalidate(materiGuruProvider);
  return materi;
}

Future<void> deleteMateri(WidgetRef ref, String materiId) async {
  // Hapus object di Storage sebelum soft-delete
  final client = ref.read(supabaseClientProvider);
  final res = await client
      .from('Materi')
      .select('filePath')
      .eq('id', materiId)
      .maybeSingle();
  final filePath = res?['filePath'] as String?;
  if (filePath != null && filePath.isNotEmpty) {
    try {
      await ref.read(storageServiceProvider).delete(
            bucket: StorageBucket.materi,
            path: filePath,
          );
    } catch (_) {}
  }
  await client
      .from('Materi')
      .update({'deletedAt': DateTime.now().toIso8601String()})
      .eq('id', materiId);
  ref.invalidate(materiGuruProvider);
}

// ---------------------------------------------------------------------------
// Tugas CRUD + grade pengumpulan
// ---------------------------------------------------------------------------

Future<TugasModel> createTugas(
  WidgetRef ref, {
  required String mapelId,
  required String kelasId,
  required String title,
  String? description,
  String type = TugasType.individu,
  String? fileUrl,
  String? filePath,
  double maxScore = 100,
  DateTime? dueDate,
  bool isPublished = false,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'mapelId': mapelId,
    'kelasId': kelasId,
    'guruId': guruId,
    'title': title,
    if (description != null) 'description': description,
    'type': type,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (filePath != null) 'filePath': filePath,
    'maxScore': maxScore,
    if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    'isPublished': isPublished,
    if (isPublished) 'publishedAt': DateTime.now().toIso8601String(),
    'createdById': client.auth.currentUser?.id,
  };

  final res = await client
      .from('Tugas')
      .insert(body)
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .single();
  final tugas = TugasModel.fromJson({
    ...res,
    'mapelName': res['MataPelajaran']?['name'],
    'kelasName': res['Kelas']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
  ref.invalidate(tugasGuruProvider);
  return tugas;
}

Future<void> deleteTugas(WidgetRef ref, String tugasId) async {
  // Hapus object di Storage sebelum soft-delete
  final client = ref.read(supabaseClientProvider);
  final res = await client
      .from('Tugas')
      .select('filePath')
      .eq('id', tugasId)
      .maybeSingle();
  final filePath = res?['filePath'] as String?;
  if (filePath != null && filePath.isNotEmpty) {
    try {
      await ref.read(storageServiceProvider).delete(
            bucket: StorageBucket.tugas,
            path: filePath,
          );
    } catch (_) {}
  }
  await client
      .from('Tugas')
      .update({'deletedAt': DateTime.now().toIso8601String()})
      .eq('id', tugasId);
  ref.invalidate(tugasGuruProvider);
}

/// Grade pengumpulan tugas — set score + feedback + status GRADED.
Future<void> gradePengumpulanTugas(
  WidgetRef ref, {
  required String pengumpulanId,
  required double score,
  String? feedback,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'score': score,
    'status': TugasStatus.graded,
    'gradedAt': DateTime.now().toIso8601String(),
    'gradedById': client.auth.currentUser?.id,
    if (feedback != null) 'feedback': feedback,
  };
  // Ambil tugasId dulu untuk invalidate yang benar
  final cur = await client
      .from('PengumpulanTugas')
      .select('tugasId')
      .eq('id', pengumpulanId)
      .single();
  await client
      .from('PengumpulanTugas')
      .update(body)
      .eq('id', pengumpulanId);
  final tugasId = cur['tugasId'] as String?;
  if (tugasId != null) {
    ref.invalidate(pengumpulanByTugasProvider(tugasId));
  }
}

// ---------------------------------------------------------------------------
// Pertemuan
// ---------------------------------------------------------------------------

Future<PertemuanModel> createPertemuan(
  WidgetRef ref, {
  required String kelasId,
  required String mapelId,
  required int pertemuanKe,
  required DateTime date,
  String? topic,
  String? description,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'kelasId': kelasId,
    'mapelId': mapelId,
    'guruId': guruId,
    'pertemuanKe': pertemuanKe,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    if (topic != null) 'topic': topic,
    if (description != null) 'description': description,
    'isCompleted': false,
  };

  final res = await client
      .from('Pertemuan')
      .insert(body)
      .select('*, Kelas(*), MataPelajaran(*), Guru(*, User(*))')
      .single();
  final pertemuan = PertemuanModel.fromJson({
    ...res,
    'kelasName': res['Kelas']?['name'],
    'mapelName': res['MataPelajaran']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
  ref.invalidate(pertemuanGuruProvider);
  return pertemuan;
}

Future<void> completePertemuan(WidgetRef ref, String pertemuanId) async {
  final client = ref.read(supabaseClientProvider);
  await client
      .from('Pertemuan')
      .update({'isCompleted': true}).eq('id', pertemuanId);
  ref.invalidate(pertemuanGuruProvider);
}

// ---------------------------------------------------------------------------
// Ujian + BankSoal + Peserta
// ---------------------------------------------------------------------------

Future<UjianModel> createUjian(
  WidgetRef ref, {
  required String mapelId,
  required String kelasId,
  required String title,
  required String type, // UjianType.*
  String? description,
  DateTime? startTime,
  DateTime? endTime,
  int durationMnt = 90,
  String? ruang,
  String? pengawas,
  double maxScore = 100,
  double passingScore = 70,
  String? fileUrl,
  String? filePath,
  bool isPublished = false,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'mapelId': mapelId,
    'kelasId': kelasId,
    'guruId': guruId,
    'title': title,
    'type': type,
    if (description != null) 'description': description,
    if (startTime != null) 'startTime': startTime.toIso8601String(),
    if (endTime != null) 'endTime': endTime.toIso8601String(),
    'durationMnt': durationMnt,
    if (ruang != null) 'ruang': ruang,
    if (pengawas != null) 'pengawas': pengawas,
    'isPublished': isPublished,
    'maxScore': maxScore,
    'passingScore': passingScore,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (filePath != null) 'filePath': filePath,
  };

  final res = await client
      .from('Ujian')
      .insert(body)
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .single();
  final ujian = UjianModel.fromJson({
    ...res,
    'mapelName': res['MataPelajaran']?['name'],
    'kelasName': res['Kelas']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
  ref.invalidate(ujianGuruProvider);
  return ujian;
}

Future<void> publishUjian(WidgetRef ref, String ujianId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Ujian').update({'isPublished': true}).eq('id', ujianId);
  ref.invalidate(ujianGuruProvider);
  ref.invalidate(ujianByIdProvider(ujianId));
}

Future<BankSoalModel> createBankSoal(
  WidgetRef ref, {
  required String mapelId,
  required String code,
  required String type, // SoalType.*
  required String question,
  String? options, // JSON string for PG
  String? correctAnswer,
  String? answerKey,
  double bobot = 1.0,
  String? difficulty,
  String? tags,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);

  final body = {
    'mapelId': mapelId,
    'tahunAjaranId': taId,
    'guruId': guruId,
    'code': code,
    'type': type,
    'question': question,
    if (options != null) 'options': options,
    if (correctAnswer != null) 'correctAnswer': correctAnswer,
    if (answerKey != null) 'answerKey': answerKey,
    'bobot': bobot,
    if (difficulty != null) 'difficulty': difficulty,
    if (tags != null) 'tags': tags,
    'isActive': true,
  };

  final res = await client
      .from('BankSoal')
      .insert(body)
      .select()
      .single();
  ref.invalidate(bankSoalGuruProvider);
  return BankSoalModel.fromJson(res);
}

/// Add soal to ujian (link BankSoal to Ujian via UjianSoal).
Future<void> addUjianSoal(
  WidgetRef ref, {
  required String ujianId,
  required String bankSoalId,
  required int urutan,
  double bobot = 1.0,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('UjianSoal').insert({
    'ujianId': ujianId,
    'bankSoalId': bankSoalId,
    'urutan': urutan,
    'bobot': bobot,
  });
  ref.invalidate(ujianSoalByUjianProvider(ujianId));
}

/// Bulk assign santri as peserta ujian.
Future<int> addUjianPesertaBulk(
  WidgetRef ref, {
  required String ujianId,
  required List<String> santriIds,
  String? ruang,
  String? pengawas,
}) async {
  final client = ref.read(supabaseClientProvider);
  final rows = santriIds
      .map((sid) => {
            'ujianId': ujianId,
            'santriId': sid,
            if (ruang != null) 'ruang': ruang,
            if (pengawas != null) 'pengawas': pengawas,
            'isHadir': true,
          })
      .toList();
  final res = await client
      .from('UjianPeserta')
      .upsert(rows, onConflict: '"ujianId","santriId"')
      .select();
  ref.invalidate(ujianPesertaByUjianProvider(ujianId));
  return (res as List).length;
}

// ---------------------------------------------------------------------------
// Perkembangan santri (4 tabs)
// ---------------------------------------------------------------------------

Future<PerkembanganQuranModel> createPerkembanganQuran(
  WidgetRef ref, {
  required String santriId,
  required String type, // TIQRO | TAHFIDZ | TILAWAH
  String? surah,
  String? juz,
  int? ayatFrom,
  int? ayatTo,
  double? score,
  String? status, // PROGRESS | SELESAI | ULANGI
  String? target,
  String? catatan,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'santriId': santriId,
    'guruId': guruId,
    'type': type,
    if (surah != null) 'surah': surah,
    if (juz != null) 'juz': juz,
    if (ayatFrom != null) 'ayatFrom': ayatFrom,
    if (ayatTo != null) 'ayatTo': ayatTo,
    if (score != null) 'score': score,
    if (status != null) 'status': status,
    if (target != null) 'target': target,
    if (catatan != null) 'catatan': catatan,
    'pertemuanDate': DateTime.now().toIso8601String(),
  };

  final res = await client
      .from('PerkembanganQuran')
      .insert(body)
      .select('*, Santri(*), Guru(*, User(*))')
      .single();
  ref.invalidate(perkembanganQuranProvider);
  return PerkembanganQuranModel.fromJson({
    ...res,
    'santriName': res['Santri']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
}

Future<HafalanKitabModel> createHafalanKitab(
  WidgetRef ref, {
  required String santriId,
  required String type, // HAFALAN | BACAAN
  required String kitabName,
  int? halaman,
  double? score,
  String? status,
  String? target,
  String? catatan,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'santriId': santriId,
    'guruId': guruId,
    'type': type,
    'kitabName': kitabName,
    if (halaman != null) 'halaman': halaman,
    if (score != null) 'score': score,
    if (status != null) 'status': status,
    if (target != null) 'target': target,
    if (catatan != null) 'catatan': catatan,
    'pertemuanDate': DateTime.now().toIso8601String(),
  };

  final res = await client
      .from('HafalanKitab')
      .insert(body)
      .select('*, Santri(*), Guru(*, User(*))')
      .single();
  ref.invalidate(hafalanKitabProvider);
  return HafalanKitabModel.fromJson({
    ...res,
    'santriName': res['Santri']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
}

Future<AkhlakPenilaianModel> createAkhlakPenilaian(
  WidgetRef ref, {
  required String santriId,
  double adabGuru = 0,
  double adabOrangTua = 0,
  double adabTeman = 0,
  double kedisiplinan = 0,
  double kebersihan = 0,
  double tanggungJawab = 0,
  String? predikat,
  String? catatan,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final avg = (adabGuru + adabOrangTua + adabTeman + kedisiplinan +
          kebersihan + tanggungJawab) /
      6;

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'santriId': santriId,
    'guruId': guruId,
    'adabGuru': adabGuru,
    'adabOrangTua': adabOrangTua,
    'adabTeman': adabTeman,
    'kedisiplinan': kedisiplinan,
    'kebersihan': kebersihan,
    'tanggungJawab': tanggungJawab,
    'rataRata': avg,
    if (predikat != null) 'predikat': predikat,
    if (catatan != null) 'catatan': catatan,
    'periodeDate': DateTime.now().toIso8601String(),
  };

  final res = await client
      .from('AkhlakPenilaian')
      .insert(body)
      .select('*, Santri(*), Guru(*, User(*))')
      .single();
  ref.invalidate(akhlakPenilaianProvider);
  return AkhlakPenilaianModel.fromJson({
    ...res,
    'santriName': res['Santri']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
}

Future<PembinaanModel> createPembinaan(
  WidgetRef ref, {
  required String santriId,
  required String type, // PEMBERIAN | TEGURAN | HUKUMAN | APEL
  required String category,
  required String title,
  String? description,
  String severity = PembinaanSeverity.ringan,
  String? tindakan,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');
  final taId = await _getActiveTahunAjaranId(client);
  final semId = await _getActiveSemesterId(client);

  final body = {
    'tahunAjaranId': taId,
    'semesterId': semId,
    'santriId': santriId,
    'guruId': guruId,
    'type': type,
    'category': category,
    'title': title,
    if (description != null) 'description': description,
    'severity': severity,
    if (tindakan != null) 'tindakan': tindakan,
    'status': PembinaanStatus.open,
  };

  final res = await client
      .from('Pembinaan')
      .insert(body)
      .select('*, Santri(*), Guru(*, User(*))')
      .single();
  ref.invalidate(pembinaanProvider);
  return PembinaanModel.fromJson({
    ...res,
    'santriName': res['Santri']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
  });
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

Future<ChatRoomModel> createChatRoom(
  WidgetRef ref, {
  required String type, // ChatRoomType.*
  required String waliId,
  String? santriId,
  String? title,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');

  final body = {
    'type': type,
    'waliId': waliId,
    'guruId': guruId,
    if (santriId != null) 'santriId': santriId,
    if (title != null) 'title': title,
    'isActive': true,
  };

  final res = await client
      .from('ChatRoom')
      .insert(body)
      .select('*, Wali(*), Guru(*, User(*)), Santri(*)')
      .single();
  ref.invalidate(chatRoomsGuruProvider);
  return ChatRoomModel.fromJson({
    ...res,
    'waliName': res['Wali']?['name'],
    'guruName': res['Guru']?['User']?['name'] ?? res['Guru']?['name'],
    'santriName': res['Santri']?['name'],
  });
}

Future<ChatMessageModel> sendChatMessage(
  WidgetRef ref, {
  required String chatRoomId,
  required String message,
}) async {
  final client = ref.read(supabaseClientProvider);
  final guruId = await _getCurrentGuruId(ref);
  if (guruId == null) throw Exception('User bukan guru.');

  final body = {
    'chatRoomId': chatRoomId,
    'senderType': ChatSenderType.guru,
    'senderGuruId': guruId,
    'message': message,
    'isRead': false,
  };

  final res = await client
      .from('ChatMessage')
      .insert(body)
      .select()
      .single();

  // Update lastMessage + lastMessageAt di ChatRoom
  await client.from('ChatRoom').update({
    'lastMessage': message,
    'lastMessageAt': DateTime.now().toIso8601String(),
  }).eq('id', chatRoomId);

  ref.invalidate(chatMessagesProvider(chatRoomId));
  ref.invalidate(chatRoomsGuruProvider);
  // Invalidate juga unread count — supaya badge di chat list ikut update.
  ref.invalidate(chatUnreadCountGuruProvider);
  return ChatMessageModel.fromJson(res);
}
