// ============================================================================
// SIM MADIN — Master Data Providers (Phase 6b — admin_desktop)
// ============================================================================
// Query + Mutation providers untuk master data:
//   Santri, Wali, Guru, Kelas, MataPelajaran, TahunAjaran, Semester
//
// Pattern: FutureProvider untuk list, mutation functions untuk CRUD.
// Soft delete pattern: update deletedAt = now(), tidak DELETE fisik.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'query_providers.dart';

// ===========================================================================
// QUERY PROVIDERS
// ===========================================================================

// --- Guru list (all, with search) ---
final guruListAdminProvider =
    FutureProvider.family<List<GuruModel>, String?>((ref, search) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Guru').select('*, User(*)').filter('deletedAt', 'is', null);
  if (search != null && search.isNotEmpty) {
    q = q.or('name.ilike.%$search%,nip.ilike.%$search%,specialization.ilike.%$search%');
  }
  final res = await q.limit(100).order('name');
  return (res as List)
      .map((r) => _guruFromRow(r as Map<String, dynamic>))
      .toList();
});

GuruModel _guruFromRow(Map<String, dynamic> row) {
  final user = (row['User'] ?? row['user']) as Map<String, dynamic>?;
  return GuruModel.fromJson({
    ...row,
    if (user != null) 'userId': user['id'],
  });
}

// --- Wali list (all, with search) ---
final waliListAdminProvider =
    FutureProvider.family<List<WaliModel>, String?>((ref, search) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Wali').select().filter('deletedAt', 'is', null);
  if (search != null && search.isNotEmpty) {
    q = q.or('name.ilike.%$search%,phone.ilike.%$search%,nik.ilike.%$search%');
  }
  final res = await q.limit(100).order('name');
  return (res as List)
      .map((r) => WaliModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// --- TahunAjaran list (all, not just active) ---
final tahunAjaranListProvider = FutureProvider<List<TahunAjaranModel>>(
    (ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('TahunAjaran').select().limit(100).order('startDate', ascending: false);
  return (res as List)
      .map((r) => TahunAjaranModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// --- Semester list (all, filter by tahunAjaranId) ---
final semesterListProvider =
    FutureProvider.family<List<SemesterModel>, String?>((ref, taId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Semester').select().limit(100);
  if (taId != null) q = q.eq('tahunAjaranId', taId);
  final res = await q.limit(100).order('startDate', ascending: false);
  return (res as List)
      .map((r) => SemesterModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// --- SantriWali list (link wali ↔ santri) ---
final santriWaliByWaliProvider =
    FutureProvider.family<List<SantriWaliModel>, String>((ref, waliId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('SantriWali')
      .select('*, Santri(name, nis, kelasId, Kelas(name))')
      .eq('waliId', waliId);
  return (res as List).map((r) {
    final santri = (r as Map<String, dynamic>)['Santri'] as Map<String, dynamic>?;
    final kelas = santri?['Kelas'] as Map<String, dynamic>?;
    return SantriWaliModel.fromJson({
      ...r,
      'santriName': santri?['name'],
      'waliName': null,
      'waliPhone': null,
    });
  }).toList();
});

// ===========================================================================
// MUTATION PROVIDERS — Santri
// ===========================================================================

Future<SantriModel> adminCreateSantri(
  WidgetRef ref, {
  required String nis,
  required String name,
  required String gender,
  String? nisn,
  String? birthPlace,
  DateTime? birthDate,
  String? address,
  String? phone,
  String? photoUrl,
  String? kelasId,
  String? waliId,
  String? tahunAjaranId,
  String status = SantriStatus.aktif,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'nis': nis,
    'name': name,
    'gender': gender,
    if (nisn != null) 'nisn': nisn,
    if (birthPlace != null) 'birthPlace': birthPlace,
    if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (kelasId != null) 'kelasId': kelasId,
    if (waliId != null) 'waliId': waliId,
    if (tahunAjaranId != null) 'tahunAjaranId': tahunAjaranId,
    'status': status,
  };
  final res = await client.from('Santri').insert(body).select().single();
  ref.invalidate(santriListProvider);
  return SantriModel.fromJson(res as Map<String, dynamic>);
}

Future<SantriModel> adminUpdateSantri(
  WidgetRef ref, {
  required String santriId,
  String? nis,
  String? name,
  String? gender,
  String? nisn,
  String? birthPlace,
  DateTime? birthDate,
  String? address,
  String? phone,
  String? photoUrl,
  String? kelasId,
  String? waliId,
  String? status,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (nis != null) 'nis': nis,
    if (name != null) 'name': name,
    if (gender != null) 'gender': gender,
    if (nisn != null) 'nisn': nisn,
    if (birthPlace != null) 'birthPlace': birthPlace,
    if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (kelasId != null) 'kelasId': kelasId,
    if (waliId != null) 'waliId': waliId,
    if (status != null) 'status': status,
  };
  final res = await client.from('Santri').update(body).eq('id', santriId).select().single();
  ref.invalidate(santriListProvider);
  return SantriModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminSoftDeleteSantri(WidgetRef ref, String santriId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Santri').update({
    'deletedAt': DateTime.now().toIso8601String(),
    'status': SantriStatus.keluar,
  }).eq('id', santriId);
  ref.invalidate(santriListProvider);
}

// ===========================================================================
// MUTATION PROVIDERS — Guru
// ===========================================================================

Future<GuruModel> adminCreateGuru(
  WidgetRef ref, {
  required String name,
  required String gender,
  String? userId,
  String? nip,
  String? nuptk,
  String? birthPlace,
  DateTime? birthDate,
  String? address,
  String? phone,
  String? email,
  String? photoUrl,
  String? specialization,
  String status = GuruStatus.aktif,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'name': name,
    'gender': gender,
    if (userId != null) 'userId': userId,
    if (nip != null) 'nip': nip,
    if (nuptk != null) 'nuptk': nuptk,
    if (birthPlace != null) 'birthPlace': birthPlace,
    if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (specialization != null) 'specialization': specialization,
    'status': status,
  };
  final res = await client.from('Guru').insert(body).select().single();
  ref.invalidate(guruListAdminProvider);
  return GuruModel.fromJson(res as Map<String, dynamic>);
}

Future<GuruModel> adminUpdateGuru(
  WidgetRef ref, {
  required String guruId,
  String? name,
  String? gender,
  String? nip,
  String? nuptk,
  String? birthPlace,
  DateTime? birthDate,
  String? address,
  String? phone,
  String? email,
  String? photoUrl,
  String? specialization,
  String? status,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (name != null) 'name': name,
    if (gender != null) 'gender': gender,
    if (nip != null) 'nip': nip,
    if (nuptk != null) 'nuptk': nuptk,
    if (birthPlace != null) 'birthPlace': birthPlace,
    if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (specialization != null) 'specialization': specialization,
    if (status != null) 'status': status,
  };
  final res = await client.from('Guru').update(body).eq('id', guruId).select().single();
  ref.invalidate(guruListAdminProvider);
  return GuruModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminSoftDeleteGuru(WidgetRef ref, String guruId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Guru').update({
    'deletedAt': DateTime.now().toIso8601String(),
    'status': GuruStatus.keluar,
  }).eq('id', guruId);
  ref.invalidate(guruListAdminProvider);
}

// ===========================================================================
// MUTATION PROVIDERS — Wali
// ===========================================================================

Future<WaliModel> adminCreateWali(
  WidgetRef ref, {
  required String name,
  String? phone,
  String? email,
  String? nik,
  String? occupation,
  String? address,
  String relationship = 'WALI',
  String activationStatus = WaliActivationStatus.active,
  String? pinHash,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (nik != null) 'nik': nik,
    if (occupation != null) 'occupation': occupation,
    if (address != null) 'address': address,
    'relationship': relationship,
    'activationStatus': activationStatus,
    if (pinHash != null) 'pinHash': pinHash,
  };
  final res = await client.from('Wali').insert(body).select().single();
  ref.invalidate(waliListAdminProvider);
  return WaliModel.fromJson(res as Map<String, dynamic>);
}

Future<WaliModel> adminUpdateWali(
  WidgetRef ref, {
  required String waliId,
  String? name,
  String? phone,
  String? email,
  String? nik,
  String? occupation,
  String? address,
  String? relationship,
  String? activationStatus,
  String? pinHash,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (nik != null) 'nik': nik,
    if (occupation != null) 'occupation': occupation,
    if (address != null) 'address': address,
    if (relationship != null) 'relationship': relationship,
    if (activationStatus != null) 'activationStatus': activationStatus,
    if (pinHash != null) 'pinHash': pinHash,
  };
  final res = await client.from('Wali').update(body).eq('id', waliId).select().single();
  ref.invalidate(waliListAdminProvider);
  return WaliModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminSoftDeleteWali(WidgetRef ref, String waliId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Wali').update({
    'deletedAt': DateTime.now().toIso8601String(),
  }).eq('id', waliId);
  ref.invalidate(waliListAdminProvider);
}

/// Link wali to santri (create SantriWali record).
Future<void> adminLinkWaliSantri(
  WidgetRef ref, {
  required String waliId,
  required String santriId,
  required String relationship,
  bool isPrimary = false,
  bool canAccess = true,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('SantriWali').insert({
    'waliId': waliId,
    'santriId': santriId,
    'relationship': relationship,
    'isPrimary': isPrimary,
    'canAccess': canAccess,
  });
  ref.invalidate(santriWaliByWaliProvider(waliId));
}

/// Unlink wali from santri.
Future<void> adminUnlinkWaliSantri(
  WidgetRef ref, {
  required String santriWaliId,
  required String waliId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('SantriWali').delete().eq('id', santriWaliId);
  ref.invalidate(santriWaliByWaliProvider(waliId));
}

// ===========================================================================
// MUTATION PROVIDERS — Kelas
// ===========================================================================

Future<KelasModel> adminCreateKelas(
  WidgetRef ref, {
  required String code,
  required String name,
  required String level,
  String? description,
  int capacity = 30,
  int sortOrder = 0,
  String? waliKelasId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'code': code,
    'name': name,
    'level': level,
    if (description != null) 'description': description,
    'capacity': capacity,
    'sortOrder': sortOrder,
    if (waliKelasId != null) 'waliKelasId': waliKelasId,
  };
  final res = await client.from('Kelas').insert(body).select().single();
  ref.invalidate(kelasListProvider);
  return KelasModel.fromJson(res as Map<String, dynamic>);
}

Future<KelasModel> adminUpdateKelas(
  WidgetRef ref, {
  required String kelasId,
  String? code,
  String? name,
  String? level,
  String? description,
  int? capacity,
  int? sortOrder,
  bool? isActive,
  String? waliKelasId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (level != null) 'level': level,
    if (description != null) 'description': description,
    if (capacity != null) 'capacity': capacity,
    if (sortOrder != null) 'sortOrder': sortOrder,
    if (isActive != null) 'isActive': isActive,
    if (waliKelasId != null) 'waliKelasId': waliKelasId,
  };
  final res = await client.from('Kelas').update(body).eq('id', kelasId).select().single();
  ref.invalidate(kelasListProvider);
  return KelasModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminSoftDeleteKelas(WidgetRef ref, String kelasId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Kelas').update({
    'deletedAt': DateTime.now().toIso8601String(),
    'isActive': false,
  }).eq('id', kelasId);
  ref.invalidate(kelasListProvider);
}

// ===========================================================================
// MUTATION PROVIDERS — MataPelajaran
// ===========================================================================

Future<MataPelajaranModel> adminCreateMapel(
  WidgetRef ref, {
  required String code,
  required String name,
  required String category,
  String? description,
  double kkm = 70.0,
  int durationMnt = 90,
  int sortOrder = 0,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'code': code,
    'name': name,
    'category': category,
    if (description != null) 'description': description,
    'kkm': kkm,
    'durationMnt': durationMnt,
    'sortOrder': sortOrder,
  };
  final res = await client.from('MataPelajaran').insert(body).select().single();
  ref.invalidate(mapelListProvider);
  return MataPelajaranModel.fromJson(res as Map<String, dynamic>);
}

Future<MataPelajaranModel> adminUpdateMapel(
  WidgetRef ref, {
  required String mapelId,
  String? code,
  String? name,
  String? category,
  String? description,
  double? kkm,
  int? durationMnt,
  int? sortOrder,
  bool? isActive,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (category != null) 'category': category,
    if (description != null) 'description': description,
    if (kkm != null) 'kkm': kkm,
    if (durationMnt != null) 'durationMnt': durationMnt,
    if (sortOrder != null) 'sortOrder': sortOrder,
    if (isActive != null) 'isActive': isActive,
  };
  final res = await client.from('MataPelajaran').update(body).eq('id', mapelId).select().single();
  ref.invalidate(mapelListProvider);
  return MataPelajaranModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminSoftDeleteMapel(WidgetRef ref, String mapelId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('MataPelajaran').update({
    'deletedAt': DateTime.now().toIso8601String(),
    'isActive': false,
  }).eq('id', mapelId);
  ref.invalidate(mapelListProvider);
}

// ===========================================================================
// MUTATION PROVIDERS — TahunAjaran + Semester
// ===========================================================================

Future<TahunAjaranModel> adminCreateTahunAjaran(
  WidgetRef ref, {
  required String code,
  required String name,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'code': code,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isActive': false,
  };
  final res = await client.from('TahunAjaran').insert(body).select().single();
  ref.invalidate(tahunAjaranListProvider);
  ref.invalidate(tahunAjaranActiveProvider);
  return TahunAjaranModel.fromJson(res as Map<String, dynamic>);
}

Future<TahunAjaranModel> adminUpdateTahunAjaran(
  WidgetRef ref, {
  required String taId,
  String? code,
  String? name,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (startDate != null) 'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate.toIso8601String(),
  };
  final res = await client.from('TahunAjaran').update(body).eq('id', taId).select().single();
  ref.invalidate(tahunAjaranListProvider);
  return TahunAjaranModel.fromJson(res as Map<String, dynamic>);
}

/// Activate tahun ajaran (deactivate all others first).
Future<void> adminActivateTahunAjaran(WidgetRef ref, String taId) async {
  final client = ref.read(supabaseClientProvider);
  // Deactivate all
  await client.from('TahunAjaran').update({'isActive': false}).neq('id', taId);
  // Activate selected
  await client.from('TahunAjaran').update({'isActive': true}).eq('id', taId);
  ref.invalidate(tahunAjaranListProvider);
  ref.invalidate(tahunAjaranActiveProvider);
}

/// Activate semester (deactivate all others first).
Future<void> adminActivateSemester(WidgetRef ref, String semesterId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Semester').update({'isActive': false}).neq('id', semesterId);
  await client.from('Semester').update({'isActive': true}).eq('id', semesterId);
  ref.invalidate(semesterListProvider);
  ref.invalidate(semesterActiveProvider);
}

Future<SemesterModel> adminCreateSemester(
  WidgetRef ref, {
  required String tahunAjaranId,
  required String code,
  required String name,
  required SemesterType type,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'tahunAjaranId': tahunAjaranId,
    'code': code,
    'name': name,
    'type': semesterTypeToString(type),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isActive': false,
  };
  final res = await client.from('Semester').insert(body).select().single();
  ref.invalidate(semesterListProvider);
  return SemesterModel.fromJson(res as Map<String, dynamic>);
}
