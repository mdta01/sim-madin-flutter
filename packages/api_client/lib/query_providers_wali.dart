// ============================================================================
// SIM MADIN — Query Providers (Phase 5 — mobile_wali)
// ============================================================================
// Riverpod providers untuk query data wali santri:
//   - waliSessionProvider — load dari secure storage (token + wali + santriList)
//   - santriAnakProvider — list santri milik wali yang login
//   - santriDetailProvider.family<String> — profil + kelas + wali info per santri
//   - absensiAnakProvider.family<String> — absensi anak tertentu (recent)
//   - nilaiAnakProvider.family<String> — nilai anak tertentu
//   - tagihanAnakProvider.family<String> — tagihan anak (filter status)
//   - paymentAnakProvider.family<String> — payment history anak
//   - ujianPesertaAnakProvider.family<String> — ujian yang diikuti anak
//   - notifikasiWaliProvider — notifikasi untuk wali yang login
//   - chatRoomsWaliProvider — chat rooms milik wali
//   - chatMessagesWaliProvider.family<String> — messages per room
//   - pengumumanWaliProvider — pengumuman untuk wali
//   - perkembanganAnakProvider.family<String> — perkembangan santri (4 jenis)
//
// Catatan: tidak ada waliTokenProvider — token wali disimpan di
// secure storage via AuthStorage (Phase 1) dan dipakai sebagai
// Authorization header di Dio interceptor (lihat api_client.dart).
// Tapi karena wali login pakai phone+PIN (bukan Supabase Auth),
// Supabase queries di sini pakai service_role-like approach via
// custom RPC functions — atau untuk Phase 5 simplifikasi, langsung
// query dengan anon key + filter by waliId yang di-cache dari session.
//
// RLS Note: policies wali_read (lihat 02_rls_policies_phase45.sql)
// mengandalkan `current_wali_id()` yang join `Wali.userId = auth.uid()::text`.
// Karena wali login pakai phone+PIN (bukan Supabase Auth), wali tidak
// punya auth.uid() → policies akan return 0 rows.
//
// Workaround untuk Phase 5 testing:
//   - Login wali WA+PIN bisa create dummy Supabase Auth user (email fake
//     seperti `wali+{waliId}@madrasah.test`, password random) supaya
//     dapat auth.uid() yang kemudian link ke Wali.userId.
//   - Atau admin desktop (Phase 6) meng-set Wali.userId manual.
//   - Untuk dev/test sekarang, saya sediakan 2 mode:
//     1. Mock mode: data hardcoded di server.ts mock (skip RLS check)
//     2. Production: admin link Wali.userId via Supabase Auth user
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'query_providers.dart' show realtimeRefreshTick;

/// Provider untuk data wali yang sedang login (dari secure storage).
/// Di-set saat login berhasil (lihat mutation_providers_wali.dart).
///
/// Catatan: class ini berbeda dengan `WaliSession` di api_client.dart
/// (yang punya wali:Map + santriList:List<Map>). Class ini punya
/// typed fields (WaliModel + List<SantriModel>) untuk convenience.
final waliSessionProvider = StateProvider<TypedWaliSession?>((_) => null);

/// Helper untuk dapatkan waliId dari session yang aktif.
String? currentWaliId(WidgetRef ref) {
  return ref.read(waliSessionProvider)?.wali.id;
}

// ---------------------------------------------------------------------------
// Santri anak list — wali yang login hanya bisa lihat anaknya (RLS enforced)
// ---------------------------------------------------------------------------

final santriAnakProvider = FutureProvider<List<SantriModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final session = ref.watch(waliSessionProvider);
  if (session == null) return [];

  // Phase 5 simplifikasi: pakai santriList dari session (saved saat login).
  // Kalau ingin refresh dari DB, query ke Supabase — tapi RLS butuh auth.uid.
  // Untuk sekarang, pakai cached list dari session.
  return session.santriList;
});

/// Detail santri (profil lengkap + kelas + wali).
final santriDetailProvider =
    FutureProvider.family<SantriModel?, String>((ref, santriId) async {
  final session = ref.watch(waliSessionProvider);
  if (session == null) return null;
  return session.santriList.where((s) => s.id == santriId).firstOrNull;
});

// ---------------------------------------------------------------------------
// Absensi anak (recent 30 days)
// ---------------------------------------------------------------------------

final absensiAnakProvider =
    FutureProvider.family<List<AbsensiModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Absensi')
      .select('*, Santri(*), Kelas(*)')
      .eq('santriId', santriId)
      .order('date', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => _absensiFromRow(r as Map<String, dynamic>))
      .toList();
});

AbsensiModel _absensiFromRow(Map<String, dynamic> row) {
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
// Nilai anak (recent 50)
// ---------------------------------------------------------------------------

final nilaiAnakProvider =
    FutureProvider.family<List<NilaiModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Nilai')
      .select('*, Santri(*), Kelas(*), MataPelajaran(*)')
      .eq('santriId', santriId)
      .order('assessmentDate', ascending: false)
      .limit(50);
  return (res as List)
      .map((r) => _nilaiFromRow(r as Map<String, dynamic>))
      .toList();
});

NilaiModel _nilaiFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  return NilaiModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (mapel != null) 'mapelName': mapel['name'],
    if (mapel != null) 'mapelKkm': mapel['kkm'],
  });
}

// ---------------------------------------------------------------------------
// Tagihan anak (filter status, default all)
// ---------------------------------------------------------------------------

final tagihanAnakProvider =
    FutureProvider.family<List<TagihanModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Tagihan')
      .select('*, Santri(*), Kelas(*), JenisTagihan(*)')
      .eq('santriId', santriId)
      .order('createdAt', ascending: false);
  return (res as List)
      .map((r) => _tagihanFromRow(r as Map<String, dynamic>))
      .toList();
});

TagihanModel _tagihanFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final jenis =
      (row['JenisTagihan'] ?? row['jenisTagihan']) as Map<String, dynamic>?;
  return TagihanModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (jenis != null) 'jenisTagihanCode': jenis['code'],
    if (jenis != null) 'jenisTagihanName': jenis['name'],
  });
}

// ---------------------------------------------------------------------------
// Payment history anak (recent 30)
// ---------------------------------------------------------------------------

final paymentAnakProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Payment')
      .select('*, Santri(*), Tagihan(*, JenisTagihan(*))')
      .eq('santriId', santriId)
      .order('paymentDate', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => _paymentFromRow(r as Map<String, dynamic>))
      .toList();
});

PaymentModel _paymentFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final tagihan = (row['Tagihan'] ?? row['tagihan']) as Map<String, dynamic>?;
  final jenis =
      tagihan?['JenisTagihan'] ?? tagihan?['jenisTagihan'];
  return PaymentModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (jenis != null) 'tagihanCode': jenis['code'],
  });
}

// ---------------------------------------------------------------------------
// Ujian peserta anak — list ujian yang diikuti anak
// ---------------------------------------------------------------------------

final ujianPesertaAnakProvider =
    FutureProvider.family<List<UjianPesertaModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('UjianPeserta')
      .select('*, Santri(*)')
      .eq('santriId', santriId)
      .order('createdAt', ascending: false);
  return (res as List)
      .map((r) => UjianPesertaModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'santriNis': (r['Santri'] ?? r['santri'])?['nis'],
          }))
      .toList();
});

/// Get ujian detail (with soal list) — for taking ujian.
/// Soal di-shuffle per santri (Fisher-Yates) di sisi server atau client.
final ujianDetailForWaliProvider =
    FutureProvider.family<UjianTakeData?, ({String ujianId, String santriId})>(
        (ref, p) async {
  final client = ref.watch(supabaseClientProvider);

  // Get ujian + soal list
  final ujianRes = await client
      .from('Ujian')
      .select('*, MataPelajaran(*), Kelas(*)')
      .eq('id', p.ujianId)
      .maybeSingle();
  if (ujianRes == null) return null;

  final ujian = UjianModel.fromJson({
    ...ujianRes as Map<String, dynamic>,
    'mapelName': ujianRes['MataPelajaran']?['name'],
    'kelasName': ujianRes['Kelas']?['name'],
  });

  // Get soal list (with BankSoal join)
  final soalRes = await client
      .from('UjianSoal')
      .select('*, BankSoal(*)')
      .eq('ujianId', p.ujianId)
      .order('urutan');
  final soalList = (soalRes as List).map((r) {
    final bankSoal = r['BankSoal'] as Map<String, dynamic>?;
    return UjianSoalModel.fromJson({
      ...r as Map<String, dynamic>,
      'question': bankSoal?['question'],
      'type': bankSoal?['type'],
      'options': bankSoal?['options'],
    });
  }).toList();

  // Get existing UjianSesi (kalau sudah mulai sebelumnya — for recovery)
  final sesiRes = await client
      .from('UjianSesi')
      .select()
      .eq('ujianId', p.ujianId)
      .eq('santriId', p.santriId)
      .order('createdAt', ascending: false)
      .limit(1)
      .maybeSingle();

  UjianSesiData? sesi;
  if (sesiRes != null) {
    sesi = UjianSesiData.fromJson(sesiRes as Map<String, dynamic>);
  }

  // Get existing answers (for recovery)
  List<UjianJawabanData> existingAnswers = [];
  if (sesi != null) {
    final jawabanRes = await client
        .from('UjianJawaban')
        .select()
        .eq('sesiId', sesi.id);
    existingAnswers = (jawabanRes as List)
        .map((r) => UjianJawabanData.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  return UjianTakeData(
    ujian: ujian,
    soalList: soalList,
    existingSesi: sesi,
    existingAnswers: existingAnswers,
  );
});

// ---------------------------------------------------------------------------
// Notifikasi wali (realtime)
// ---------------------------------------------------------------------------

final notifikasiWaliProvider = FutureProvider<List<NotifikasiWaliModel>>(
    (ref) async {
  ref.watch(realtimeRefreshTick);
  final session = ref.watch(waliSessionProvider);
  if (session == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Notifikasi')
      .select()
      .eq('waliId', session.wali.id)
      .order('createdAt', ascending: false)
      .limit(50);
  return (res as List)
      .map((r) => NotifikasiWaliModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Notifikasi untuk satu santri tertentu — dipakai di tab Notif per santri
/// di santri_detail_screen. Sebelumnya tab Notif menampilkan SEMUA notifikasi
/// wali (campur untuk semua anak) — sekarang filter by santriId.
final notifikasiAnakProvider =
    FutureProvider.family<List<NotifikasiWaliModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final session = ref.watch(waliSessionProvider);
  if (session == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Notifikasi')
      .select()
      .eq('waliId', session.wali.id)
      .eq('santriId', santriId)
      .order('createdAt', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => NotifikasiWaliModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Chat rooms wali + messages
// ---------------------------------------------------------------------------

final chatRoomsWaliProvider = FutureProvider<List<ChatRoomModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final session = ref.watch(waliSessionProvider);
  if (session == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('ChatRoom')
      .select('*, Wali(*), Guru(*, User(*)), Santri(*)')
      .eq('waliId', session.wali.id)
      .eq('isActive', true)
      .order('lastMessageAt', ascending: false);
  return (res as List)
      .map((r) => ChatRoomModel.fromJson({
            ...(r as Map<String, dynamic>),
            'waliName': r['Wali']?['name'],
            'guruName': r['Guru']?['User']?['name'] ?? r['Guru']?['name'],
            'santriName': r['Santri']?['name'],
          }))
      .toList();
});

/// Unread message count per chat room untuk wali.
/// Query ChatMessage where chatRoomId in rooms milik wali AND senderType != 'WALI'
/// (pesan dari guru/yang belum dibaca wali) AND isRead = false.
/// Return Map<roomId, count> untuk dipakai di chat list badge.
final chatUnreadCountWaliProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final session = ref.watch(waliSessionProvider);
  if (session == null) return {};

  final client = ref.watch(supabaseClientProvider);
  // Get list room IDs milik wali.
  final roomsRes = await client
      .from('ChatRoom')
      .select('id')
      .eq('waliId', session.wali.id)
      .eq('isActive', true);
  final roomIds = (roomsRes as List)
      .map((r) => (r as Map<String, dynamic>)['id'] as String)
      .toList();
  if (roomIds.isEmpty) return {};

  // Get unread messages (senderType != WALI, isRead = false).
  final msgRes = await client
      .from('ChatMessage')
      .select('chatRoomId')
      .inFilter('chatRoomId', roomIds)
      .neq('senderType', ChatSenderType.wali)
      .eq('isRead', false);
  final counts = <String, int>{};
  for (final r in msgRes as List) {
    final roomId = (r as Map<String, dynamic>)['chatRoomId'] as String;
    counts[roomId] = (counts[roomId] ?? 0) + 1;
  }
  return counts;
});

final chatMessagesWaliProvider =
    FutureProvider.family<List<ChatMessageModel>, String>((ref, roomId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('ChatMessage')
      .select()
      .eq('chatRoomId', roomId)
      .order('createdAt', ascending: false)
      .limit(100);
  final list = (res as List)
      .map((r) => ChatMessageModel.fromJson(r as Map<String, dynamic>))
      .toList();
  return list.reversed.toList();
});

// ---------------------------------------------------------------------------
// Pengumuman untuk wali (audience = ALL atau WALI)
// ---------------------------------------------------------------------------

final pengumumanWaliProvider =
    FutureProvider<List<AnnouncementModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Announcement')
      .select()
      .or('audience.eq.ALL,audience.eq.WALI')
      .order('publishedAt', ascending: false)
      .limit(20);
  return (res as List)
      .map((r) => AnnouncementModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Perkembangan anak (4 jenis)
// ---------------------------------------------------------------------------

final perkembanganQuranAnakProvider =
    FutureProvider.family<List<PerkembanganQuranModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('PerkembanganQuran')
      .select('*, Santri(*), Guru(*, User(*))')
      .eq('santriId', santriId)
      .order('pertemuanDate', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => PerkembanganQuranModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'guruName': (r['Guru'] ?? r['guru'])?['User']?['name'] ??
                (r['Guru'] ?? r['guru'])?['name'],
          }))
      .toList();
});

final hafalanKitabAnakProvider =
    FutureProvider.family<List<HafalanKitabModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('HafalanKitab')
      .select('*, Santri(*), Guru(*, User(*))')
      .eq('santriId', santriId)
      .order('pertemuanDate', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => HafalanKitabModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'guruName': (r['Guru'] ?? r['guru'])?['User']?['name'] ??
                (r['Guru'] ?? r['guru'])?['name'],
          }))
      .toList();
});

final akhlakAnakProvider =
    FutureProvider.family<List<AkhlakPenilaianModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('AkhlakPenilaian')
      .select('*, Santri(*), Guru(*, User(*))')
      .eq('santriId', santriId)
      .order('periodeDate', ascending: false)
      .limit(20);
  return (res as List)
      .map((r) => AkhlakPenilaianModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'guruName': (r['Guru'] ?? r['guru'])?['User']?['name'] ??
                (r['Guru'] ?? r['guru'])?['name'],
          }))
      .toList();
});

final pembinaanAnakProvider =
    FutureProvider.family<List<PembinaanModel>, String>(
        (ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Pembinaan')
      .select('*, Santri(*), Guru(*, User(*))')
      .eq('santriId', santriId)
      .order('createdAt', ascending: false)
      .limit(30);
  return (res as List)
      .map((r) => PembinaanModel.fromJson({
            ...(r as Map<String, dynamic>),
            'santriName': (r['Santri'] ?? r['santri'])?['name'],
            'guruName': (r['Guru'] ?? r['guru'])?['User']?['name'] ??
                (r['Guru'] ?? r['guru'])?['name'],
          }))
      .toList();
});

// ---------------------------------------------------------------------------
// Helper: invalidate semua providers wali
// ---------------------------------------------------------------------------

void invalidateWaliQueries(WidgetRef ref) {
  ref.invalidate(santriAnakProvider);
  ref.invalidate(notifikasiWaliProvider);
  ref.invalidate(notifikasiAnakProvider);
  ref.invalidate(chatRoomsWaliProvider);
  ref.invalidate(chatUnreadCountWaliProvider);
  ref.invalidate(pengumumanWaliProvider);
}

// ---------------------------------------------------------------------------
// Model classes (Phase 5 specific)
// ---------------------------------------------------------------------------

/// Session wali yang di-cache di memory setelah login.
/// Token + data wali + list santri (denormalized, tanpa join di setiap query).
class TypedWaliSession {
  const TypedWaliSession({
    required this.token,
    required this.wali,
    required this.santriList,
  });

  final String token;
  final WaliModel wali;
  final List<SantriModel> santriList;
}

/// Notifikasi untuk wali — port dari Prisma Notifikasi model.
class NotifikasiWaliModel {
  const NotifikasiWaliModel({
    required this.id,
    required this.waliId,
    this.santriId,
    required this.type,
    required this.title,
    required this.message,
    this.priority = 'NORMAL',
    this.isRead = false,
    this.readAt,
    this.entityType,
    this.entityId,
    this.isEmailSent = false,
    this.isPushSent = false,
    required this.createdAt,
  });

  final String id;
  final String waliId;
  final String? santriId;
  final String type;
  final String title;
  final String message;
  final String priority;
  final bool isRead;
  final DateTime? readAt;
  final String? entityType;
  final String? entityId;
  final bool isEmailSent;
  final bool isPushSent;
  final DateTime createdAt;

  factory NotifikasiWaliModel.fromJson(Map<String, dynamic> j) =>
      NotifikasiWaliModel(
        id: j['id'] as String,
        waliId: j['waliId'] as String,
        santriId: j['santriId'] as String?,
        type: j['type'] as String,
        title: j['title'] as String,
        message: j['message'] as String,
        priority: (j['priority'] as String?) ?? 'NORMAL',
        isRead: (j['isRead'] as bool?) ?? false,
        readAt: j['readAt'] is String
            ? DateTime.parse(j['readAt'] as String)
            : null,
        entityType: j['entityType'] as String?,
        entityId: j['entityId'] as String?,
        isEmailSent: (j['isEmailSent'] as bool?) ?? false,
        isPushSent: (j['isPushSent'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// Data yang dibutuhkan untuk take ujian.
class UjianTakeData {
  const UjianTakeData({
    required this.ujian,
    required this.soalList,
    this.existingSesi,
    this.existingAnswers = const [],
  });

  final UjianModel ujian;
  final List<UjianSoalModel> soalList;
  final UjianSesiData? existingSesi;
  final List<UjianJawabanData> existingAnswers;
}

/// UjianSesi — port dari Prisma (sesi ujian per santri).
class UjianSesiData {
  const UjianSesiData({
    required this.id,
    required this.ujianId,
    required this.santriId,
    this.startTime,
    this.endTime,
    this.durationUsed,
    this.score,
    required this.status,
    this.soalOrder, // JSON string with array of ujianSoalId
    this.isAutoCorrected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ujianId;
  final String santriId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationUsed;
  final double? score;
  final String status;
  final String? soalOrder;
  final bool isAutoCorrected;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UjianSesiData.fromJson(Map<String, dynamic> j) => UjianSesiData(
        id: j['id'] as String,
        ujianId: j['ujianId'] as String,
        santriId: j['santriId'] as String,
        startTime: j['startTime'] is String
            ? DateTime.parse(j['startTime'] as String)
            : null,
        endTime: j['endTime'] is String
            ? DateTime.parse(j['endTime'] as String)
            : null,
        durationUsed: (j['durationUsed'] as num?)?.toInt(),
        score: (j['score'] as num?)?.toDouble(),
        status: j['status'] as String,
        soalOrder: j['soalOrder'] as String?,
        isAutoCorrected: (j['isAutoCorrected'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

/// UjianJawaban — jawaban santri untuk satu soal.
class UjianJawabanData {
  const UjianJawabanData({
    required this.id,
    required this.sesiId,
    required this.ujianSoalId,
    required this.santriId,
    this.answer,
    this.optionOrder, // JSON string with shuffled option indices
    this.isCorrect,
    this.score,
    this.isAutoCorrected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sesiId;
  final String ujianSoalId;
  final String santriId;
  final String? answer;
  final String? optionOrder;
  final bool? isCorrect;
  final double? score;
  final bool isAutoCorrected;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UjianJawabanData.fromJson(Map<String, dynamic> j) => UjianJawabanData(
        id: j['id'] as String,
        sesiId: j['sesiId'] as String,
        ujianSoalId: j['ujianSoalId'] as String,
        santriId: j['santriId'] as String,
        answer: j['answer'] as String?,
        optionOrder: j['optionOrder'] as String?,
        isCorrect: (j['isCorrect'] as bool?),
        score: (j['score'] as num?)?.toDouble(),
        isAutoCorrected: (j['isAutoCorrected'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}
