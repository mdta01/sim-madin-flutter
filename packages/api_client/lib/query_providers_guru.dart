// ============================================================================
// SIM MADIN — Query Providers (Phase 4 — mobile_guru)
// ============================================================================
// Riverpod providers untuk query data akademik guru:
//   - Jadwal mengajar (per guru)
//   - Santri per kelas
//   - Materi/Tugas/Pertemuan (per guru)
//   - Ujian + BankSoal + Peserta + Nilai
//   - Perkembangan santri (4 tab: Quran/Kitab/Akhlak/Pembinaan)
//   - Chat rooms + messages (realtime)
//
// Filter otomatis berdasarkan current_guru_id() via Supabase RLS — guru
// hanya bisa lihat data miliknya (lihat policy pertemuan_guru_write,
// materi_guru_write, dll di 02_rls_policies_phase45.sql).
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'query_providers.dart' show realtimeRefreshTick, supabaseClientProvider;

// ---------------------------------------------------------------------------
// Helper: parse relation rows
// ---------------------------------------------------------------------------

JadwalModel _jadwalFromRow(Map<String, dynamic> row) {
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return JadwalModel.fromJson({
    ...row,
    if (kelas != null) 'kelasName': kelas['name'],
    if (kelas != null) 'kelasCode': kelas['code'],
    if (mapel != null) 'mapelName': mapel['name'],
    if (mapel != null) 'mapelCode': mapel['code'],
    if (guru != null) 'guruName': guru['name'],
  });
}

MateriModel _materiFromRow(Map<String, dynamic> row) {
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return MateriModel.fromJson({
    ...row,
    if (mapel != null) 'mapelName': mapel['name'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

TugasModel _tugasFromRow(Map<String, dynamic> row) {
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return TugasModel.fromJson({
    ...row,
    if (mapel != null) 'mapelName': mapel['name'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

PertemuanModel _pertemuanFromRow(Map<String, dynamic> row) {
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return PertemuanModel.fromJson({
    ...row,
    if (kelas != null) 'kelasName': kelas['name'],
    if (mapel != null) 'mapelName': mapel['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

UjianModel _ujianFromRow(Map<String, dynamic> row) {
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return UjianModel.fromJson({
    ...row,
    if (mapel != null) 'mapelName': mapel['name'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

PerkembanganQuranModel _quranFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return PerkembanganQuranModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

HafalanKitabModel _kitabFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return HafalanKitabModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

AkhlakPenilaianModel _akhlakFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return AkhlakPenilaianModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

PembinaanModel _pembinaanFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return PembinaanModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (guru != null) 'guruName': guru['name'],
  });
}

ChatRoomModel _chatRoomFromRow(Map<String, dynamic> row) {
  final wali = (row['Wali'] ?? row['wali']) as Map<String, dynamic>?;
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  return ChatRoomModel.fromJson({
    ...row,
    if (wali != null) 'waliName': wali['name'],
    if (guru != null) 'guruName': guru['name'],
    if (santri != null) 'santriName': santri['name'],
  });
}

// ---------------------------------------------------------------------------
// Jadwal mengajar guru — semua jadwal milik guru yang login
// ---------------------------------------------------------------------------

final jadwalGuruProvider = FutureProvider<List<JadwalModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Jadwal')
      .select('*, Kelas(*), MataPelajaran(*), Guru(*, User(*))')
      .order('dayOfWeek').limit(100)
      .limit(100).order('startTime');
  return (res as List)
      .map((r) => _jadwalFromRow(r as Map<String, dynamic>))
      .toList();
});

/// Jadwal hari ini untuk guru yang login.
final jadwalHariIniProvider = FutureProvider<List<JadwalModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final all = await ref.watch(jadwalGuruProvider.future);
  // ISO: Monday=1, Sunday=7
  final today = DateTime.now().weekday;
  return all.where((j) => j.dayOfWeek == today).toList();
});

// ---------------------------------------------------------------------------
// Santri per kelas (filter by kelasId)
// ---------------------------------------------------------------------------

final santriByKelasProvider =
    FutureProvider.family<List<SantriModel>, String>((ref, kelasId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Santri')
      .select('*, Kelas(*), Wali(*)')
      .eq('kelasId', kelasId)
      .eq('status', SantriStatus.aktif)
      .limit(100)
      .order('name');  return (res as List)
      .map((r) => _santriFromRowGuru(r as Map<String, dynamic>))
      .toList();
});

SantriModel _santriFromRowGuru(Map<String, dynamic> row) {
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final wali = (row['Wali'] ?? row['wali']) as Map<String, dynamic>?;
  return SantriModel.fromJson({
    ...row,
    if (kelas != null) 'kelasName': kelas['name'],
    if (kelas != null) 'kelasCode': kelas['code'],
    if (wali != null) 'waliName': wali['name'],
    if (wali != null) 'waliPhone': wali['phone'],
  });
}

// ---------------------------------------------------------------------------
// Absensi per kelas + tanggal
// ---------------------------------------------------------------------------

final absensiByKelasDateProvider = FutureProvider.family<
    List<AbsensiModel>, ({String kelasId, DateTime date})>((ref, p) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final dayStart = DateTime(p.date.year, p.date.month, p.date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final res = await client
      .from('Absensi')
      .select('*, Santri(*), Kelas(*)')
      .eq('kelasId', p.kelasId)
      .gte('date', dayStart.toIso8601String())
      .lt('date', dayEnd.toIso8601String());
  return (res as List)
      .map((r) => _absensiFromRowGuru(r as Map<String, dynamic>))
      .toList();
});

AbsensiModel _absensiFromRowGuru(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  return AbsensiModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
  });
}

// ---------------------------------------------------------------------------
// Materi guru
// ---------------------------------------------------------------------------

final materiGuruProvider = FutureProvider<List<MateriModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Materi')
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .filter('deletedAt', 'is', null)
      .limit(100)
      .order('createdAt', ascending: false);  return (res as List)
      .map((r) => _materiFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Tugas guru + pengumpulan
// ---------------------------------------------------------------------------

final tugasGuruProvider = FutureProvider<List<TugasModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Tugas')
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .filter('deletedAt', 'is', null)
      .limit(100)
      .order('createdAt', ascending: false);  return (res as List)
      .map((r) => _tugasFromRow(r as Map<String, dynamic>))
      .toList();
});

final pengumpulanByTugasProvider =
    FutureProvider.family<List<PengumpulanTugasModel>, String>(
        (ref, tugasId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('PengumpulanTugas')
      .select('*, Santri(*), Tugas(title)')
      .eq('tugasId', tugasId)
      .limit(100)
      .order('submittedAt', ascending: false);  return (res as List)
      .map((r) => _pengumpulanFromRow(r as Map<String, dynamic>))
      .toList();
});

/// Detail tugas by ID — untuk header TugasDetailScreen.
/// Termasuk join MataPelajaran, Kelas, Guru supaya nama tersedia.
final tugasByIdProvider =
    FutureProvider.family<TugasModel?, String>((ref, tugasId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Tugas')
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .eq('id', tugasId)
      .maybeSingle();
  if (res == null) return null;
  return _tugasFromRow(res);
});

PengumpulanTugasModel _pengumpulanFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final tugas = (row['Tugas'] ?? row['tugas']) as Map<String, dynamic>?;
  return PengumpulanTugasModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (tugas != null) 'tugasTitle': tugas['title'],
  });
}

// ---------------------------------------------------------------------------
// Pertemuan guru
// ---------------------------------------------------------------------------

final pertemuanGuruProvider = FutureProvider<List<PertemuanModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Pertemuan')
      .select('*, Kelas(*), MataPelajaran(*), Guru(*, User(*))')
      .limit(100).order('date', ascending: false)
      .limit(100);
  return (res as List)
      .map((r) => _pertemuanFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Ujian guru + BankSoal + Peserta + Nilai
// ---------------------------------------------------------------------------

final ujianGuruProvider = FutureProvider<List<UjianModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Ujian')
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .filter('deletedAt', 'is', null)
      .limit(100)
      .order('startTime', ascending: false);  return (res as List)
      .map((r) => _ujianFromRow(r as Map<String, dynamic>))
      .toList();
});

final ujianByIdProvider =
    FutureProvider.family<UjianModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Ujian')
      .select('*, MataPelajaran(*), Kelas(*), Guru(*, User(*))')
      .eq('id', id)
      .maybeSingle();
  if (res == null) return null;
  return _ujianFromRow(res);
});

final ujianSoalByUjianProvider =
    FutureProvider.family<List<UjianSoalModel>, String>((ref, ujianId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('UjianSoal')
      .select('*, BankSoal(*)')
      .eq('ujianId', ujianId)
      .limit(100)
      .order('urutan');  return (res as List)
      .map((r) => UjianSoalModel.fromJson({
            ...(r as Map<String, dynamic>),
            'question': (r['BankSoal'] ?? r['bankSoal'])?['question'],
            'type': (r['BankSoal'] ?? r['bankSoal'])?['type'],
            'options': (r['BankSoal'] ?? r['bankSoal'])?['options'],
          }))
      .toList();
});

final ujianPesertaByUjianProvider =
    FutureProvider.family<List<UjianPesertaModel>, String>(
        (ref, ujianId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('UjianPeserta')
      .select('*, Santri(*)')
      .eq('ujianId', ujianId)
      .limit(100)
      .order('createdAt');  return (res as List)
      .map((r) => UjianPesertaModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'santriNis': (r['Santri'] ?? r['santri'])?['nis'],
          }))
      .toList();
});

final ujianNilaiByUjianProvider =
    FutureProvider.family<List<UjianNilaiModel>, String>(
        (ref, ujianId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('UjianNilai')
      .select('*, Santri(*)')
      .eq('ujianId', ujianId)
      .limit(100)
      .order('createdAt');  return (res as List)
      .map((r) => UjianNilaiModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'santriNis': (r['Santri'] ?? r['santri'])?['nis'],
          }))
      .toList();
});

// ---------------------------------------------------------------------------
// Bank Soal guru (soal milik sendiri)
// ---------------------------------------------------------------------------

final bankSoalGuruProvider = FutureProvider<List<BankSoalModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('BankSoal')
      .select()
      .limit(100)
      .order('createdAt', ascending: false);  return (res as List)
      .map((r) => BankSoalModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Perkembangan santri (4 tabs)
// ---------------------------------------------------------------------------

final perkembanganQuranProvider =
    FutureProvider<List<PerkembanganQuranModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('PerkembanganQuran')
      .select('*, Santri(*), Guru(*, User(*))')
      .limit(100).order('pertemuanDate', ascending: false)
      .limit(100);
  return (res as List)
      .map((r) => _quranFromRow(r as Map<String, dynamic>))
      .toList();
});

final hafalanKitabProvider =
    FutureProvider<List<HafalanKitabModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('HafalanKitab')
      .select('*, Santri(*), Guru(*, User(*))')
      .limit(100).order('pertemuanDate', ascending: false)
      .limit(100);
  return (res as List)
      .map((r) => _kitabFromRow(r as Map<String, dynamic>))
      .toList();
});

final akhlakPenilaianProvider =
    FutureProvider<List<AkhlakPenilaianModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('AkhlakPenilaian')
      .select('*, Santri(*), Guru(*, User(*))')
      .limit(100).order('periodeDate', ascending: false)
      .limit(100);
  return (res as List)
      .map((r) => _akhlakFromRow(r as Map<String, dynamic>))
      .toList();
});

final pembinaanProvider = FutureProvider<List<PembinaanModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Pembinaan')
      .select('*, Santri(*), Guru(*, User(*))')
      .limit(100).order('createdAt', ascending: false)
      .limit(100);
  return (res as List)
      .map((r) => _pembinaanFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Pengumuman (read-only untuk guru)
// ---------------------------------------------------------------------------

final pengumumanListProvider =
    FutureProvider<List<AnnouncementModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Announcement')
      .select()
      .limit(100).order('publishedAt', ascending: false)
      .limit(20);
  return (res as List)
      .map((r) => AnnouncementModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Chat rooms guru + messages (realtime)
// ---------------------------------------------------------------------------

final chatRoomsGuruProvider = FutureProvider<List<ChatRoomModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('ChatRoom')
      .select('*, Wali(*), Guru(*, User(*)), Santri(*)')
      .eq('isActive', true)
      .limit(100).order('lastMessageAt', ascending: false)
      .limit(50);
  return (res as List)
      .map((r) => _chatRoomFromRow(r as Map<String, dynamic>))
      .toList();
});

/// Unread message count per chat room untuk guru.
/// Query ChatMessage where senderType != 'GURU' (pesan dari wali/yang belum
/// dibaca guru) AND isRead = false. Return Map<roomId, count>.
final chatUnreadCountGuruProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  // Get list room IDs yang aktif (RLS akan filter by guru).
  final roomsRes = await client
      .from('ChatRoom')
      .select('id')
      .eq('isActive', true)
      .limit(50);
  final roomIds = (roomsRes as List)
      .map((r) => (r as Map<String, dynamic>)['id'] as String)
      .toList();
  if (roomIds.isEmpty) return {};

  final msgRes = await client
      .from('ChatMessage')
      .select('chatRoomId')
      .inFilter('chatRoomId', roomIds)
      .neq('senderType', ChatSenderType.guru)
      .eq('isRead', false);
  final counts = <String, int>{};
  for (final r in msgRes as List) {
    final roomId = (r as Map<String, dynamic>)['chatRoomId'] as String;
    counts[roomId] = (counts[roomId] ?? 0) + 1;
  }
  return counts;
});

final chatMessagesProvider =
    FutureProvider.family<List<ChatMessageModel>, String>((ref, roomId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('ChatMessage')
      .select()
      .eq('chatRoomId', roomId)
      .limit(100).order('createdAt', ascending: false)
      .limit(100);
  final list = (res as List)
      .map((r) => ChatMessageModel.fromJson(r as Map<String, dynamic>))
      .toList();
  // Reverse to chronological order for display
  return list.reversed.toList();
});

// ---------------------------------------------------------------------------
// Guru stats (for dashboard)
// ---------------------------------------------------------------------------

final guruStatsProvider = FutureProvider<GuruStats>((ref) async {
  ref.watch(realtimeRefreshTick);
  final jadwal = await ref.watch(jadwalGuruProvider.future);
  final materi = await ref.watch(materiGuruProvider.future);
  final tugas = await ref.watch(tugasGuruProvider.future);
  final pertemuan = await ref.watch(pertemuanGuruProvider.future);

  final today = DateTime.now().weekday;
  final pertemuanToday = pertemuan.where((p) {
    final pDate = p.date;
    return pDate.year == DateTime.now().year &&
        pDate.month == DateTime.now().month &&
        pDate.day == DateTime.now().day;
  }).length;
  final jadwalToday = jadwal.where((j) => j.dayOfWeek == today).length;

  return GuruStats(
    jadwalTodayCount: jadwalToday,
    pertemuanTodayCount: pertemuanToday,
    materiCount: materi.length,
    tugasActiveCount: tugas.where((t) => t.isPublished).length,
  );
});

class GuruStats {
  const GuruStats({
    required this.jadwalTodayCount,
    required this.pertemuanTodayCount,
    required this.materiCount,
    required this.tugasActiveCount,
  });

  final int jadwalTodayCount;
  final int pertemuanTodayCount;
  final int materiCount;
  final int tugasActiveCount;
}

/// Helper untuk invalidate semua providers guru — panggil setelah mutasi.
void invalidateGuruQueries(WidgetRef ref) {
  ref.invalidate(jadwalGuruProvider);
  ref.invalidate(jadwalHariIniProvider);
  ref.invalidate(materiGuruProvider);
  ref.invalidate(tugasGuruProvider);
  ref.invalidate(tugasByIdProvider);
  ref.invalidate(pertemuanGuruProvider);
  ref.invalidate(ujianGuruProvider);
  ref.invalidate(bankSoalGuruProvider);
  ref.invalidate(perkembanganQuranProvider);
  ref.invalidate(hafalanKitabProvider);
  ref.invalidate(akhlakPenilaianProvider);
  ref.invalidate(pembinaanProvider);
  ref.invalidate(pengumumanListProvider);
  ref.invalidate(chatRoomsGuruProvider);
  ref.invalidate(chatUnreadCountGuruProvider);
  ref.invalidate(guruStatsProvider);
}
