// ============================================================================
// SIM MADIN — Keuangan + Lainnya Providers (Phase 6d — admin_desktop)
// ============================================================================
// 12 modul: Siklus, Tagihan, Pembayaran, Kas, HonorGuru, Pengumuman,
// Notifikasi, Surat, Alumni, Chat, QR, AuditLog
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'query_providers.dart';
import 'query_providers_admin.dart';
import 'storage_service.dart';

// ===========================================================================
// TAGIHAN
// ===========================================================================

final tagihanListAdminProvider =
    FutureProvider.family<List<TagihanModel>, String?>((ref, status) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Tagihan').select('*, Santri(name, nis, Kelas(name)), JenisTagihan(name, code)');
  if (status != null && status != 'ALL') q = q.eq('status', status!);
  final res = await q.order('createdAt', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final santri = row['Santri'] as Map<String, dynamic>?;
    final kelas = santri?['Kelas'] as Map<String, dynamic>?;
    final jenis = row['JenisTagihan'] as Map<String, dynamic>?;
    return TagihanModel.fromJson({...row, 'santriName': santri?['name'], 'santriNis': santri?['nis'], 'kelasName': kelas?['name'], 'jenisTagihanCode': jenis?['code'], 'jenisTagihanName': jenis?['name']});
  }).toList();
});

Future<void> adminDeleteTagihan(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Tagihan').delete().eq('id', id);
  ref.invalidate(tagihanListAdminProvider);
}

/// Create tagihan untuk satu santri.
Future<TagihanModel> adminCreateTagihan(
  WidgetRef ref, {
  required String santriId,
  required String jenisTagihanId,
  required double amount,
  String? description,
  DateTime? dueDate,
  String? tahunAjaranId,
  String? semesterId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final taId = tahunAjaranId ?? (await ref.read(tahunAjaranActiveProvider.future))?.id;
  final body = {
    'santriId': santriId,
    'jenisTagihanId': jenisTagihanId,
    'amount': amount,
    'paidAmount': 0.0,
    'status': TagihanStatus.belumBayar,
    if (description != null) 'description': description,
    if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    if (taId != null) 'tahunAjaranId': taId,
    if (semesterId != null) 'semesterId': semesterId,
  };
  final res = await client.from('Tagihan').insert(body).select('*, Santri(name, nis, Kelas(name)), JenisTagihan(name, code)').single();
  final row = res as Map<String, dynamic>;
  final santri = row['Santri'] as Map<String, dynamic>?;
  final kelas = santri?['Kelas'] as Map<String, dynamic>?;
  final jenis = row['JenisTagihan'] as Map<String, dynamic>?;
  ref.invalidate(tagihanListAdminProvider);
  return TagihanModel.fromJson({...row, 'santriName': santri?['name'], 'santriNis': santri?['nis'], 'kelasName': kelas?['name'], 'jenisTagihanCode': jenis?['code'], 'jenisTagihanName': jenis?['name']});
}

/// Bulk create tagihan untuk semua santri di satu kelas.
/// Dipakai untuk generate tagihan syahriyah/uang ujian per kelas.
Future<int> adminCreateTagihanBulk(
  WidgetRef ref, {
  required String kelasId,
  required String jenisTagihanId,
  required double amount,
  String? description,
  DateTime? dueDate,
  String? tahunAjaranId,
  String? semesterId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final taId = tahunAjaranId ?? (await ref.read(tahunAjaranActiveProvider.future))?.id;

  // Get all santri in kelas
  final santriRes = await client.from('Santri').select('id').eq('kelasId', kelasId).eq('status', SantriStatus.aktif).filter('deletedAt', 'is', null);
  final santriIds = (santriRes as List).map((r) => (r as Map<String, dynamic>)['id'] as String).toList();
  if (santriIds.isEmpty) return 0;

  // Build rows
  final rows = santriIds.map((sid) => {
    'santriId': sid,
    'jenisTagihanId': jenisTagihanId,
    'amount': amount,
    'paidAmount': 0.0,
    'status': TagihanStatus.belumBayar,
    if (description != null) 'description': description,
    if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    if (taId != null) 'tahunAjaranId': taId,
    if (semesterId != null) 'semesterId': semesterId,
  }).toList();

  await client.from('Tagihan').insert(rows);
  ref.invalidate(tagihanListAdminProvider);
  return santriIds.length;
}

/// Update tagihan (edit amount, dueDate, status).
Future<void> adminUpdateTagihan(
  WidgetRef ref, {
  required String tagihanId,
  double? amount,
  double? paidAmount,
  String? status,
  String? description,
  DateTime? dueDate,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (amount != null) 'amount': amount,
    if (paidAmount != null) 'paidAmount': paidAmount,
    if (status != null) 'status': status,
    if (description != null) 'description': description,
    if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
  await client.from('Tagihan').update(body).eq('id', tagihanId);
  ref.invalidate(tagihanListAdminProvider);
}

// ===========================================================================
// PEMBAYARAN
// ===========================================================================

final pembayaranListAdminProvider =
    FutureProvider.family<List<PaymentModel>, String?>((ref, status) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Payment').select('*, Santri(name, nis), Tagihan(*, JenisTagihan(code))');
  if (status != null && status != 'ALL') q = q.eq('status', status!);
  final res = await q.order('paymentDate', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final santri = row['Santri'] as Map<String, dynamic>?;
    final tagihan = row['Tagihan'] as Map<String, dynamic>?;
    final jenis = tagihan?['JenisTagihan'] as Map<String, dynamic>?;
    return PaymentModel.fromJson({...row, 'santriName': santri?['name'], 'santriNis': santri?['nis'], 'tagihanCode': jenis?['code']});
  }).toList();
});

Future<void> adminVerifyPayment(WidgetRef ref, String paymentId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Payment').update({'status': PaymentStatus.verified}).eq('id', paymentId);
  ref.invalidate(pembayaranListAdminProvider);
}

Future<void> adminRejectPayment(WidgetRef ref, String paymentId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Payment').update({'status': PaymentStatus.rejected}).eq('id', paymentId);
  ref.invalidate(pembayaranListAdminProvider);
}

Future<void> adminDeletePayment(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Payment').delete().eq('id', id);
  ref.invalidate(pembayaranListAdminProvider);
}

// ===========================================================================
// KAS
// ===========================================================================

final kasListAdminProvider = FutureProvider<List<KasModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Kas').select().eq('isActive', true).order('createdAt');
  return (res as List).map((r) => KasModel.fromJson(r as Map<String, dynamic>)).toList();
});

Future<KasModel> adminCreateKas(WidgetRef ref, {required String code, required String name, required String type, String? accountNumber, String? bankName}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Kas').insert({'code': code, 'name': name, 'type': type, if (accountNumber != null) 'accountNumber': accountNumber, if (bankName != null) 'bankName': bankName}).select().single();
  ref.invalidate(kasListAdminProvider);
  return KasModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeleteKas(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Kas').update({'isActive': false}).eq('id', id);
  ref.invalidate(kasListAdminProvider);
}

// ===========================================================================
// HONOR GURU
// ===========================================================================

final honorGuruListAdminProvider =
    FutureProvider.family<List<HonorGuruModel>, String?>((ref, status) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('HonorGuru').select('*, Guru(name, specialization)');
  if (status != null && status != 'ALL') q = q.eq('status', status!);
  final res = await q.order('createdAt', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final guru = row['Guru'] as Map<String, dynamic>?;
    return HonorGuruModel.fromJson({...row, 'guruName': guru?['name'], 'guruSpecialization': guru?['specialization']});
  }).toList();
});

Future<void> adminDeleteHonorGuru(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('HonorGuru').delete().eq('id', id);
  ref.invalidate(honorGuruListAdminProvider);
}

/// Generate honor guru bulk untuk semua guru aktif di periode tertentu.
/// Dipanggil oleh admin dari admin_desktop.
Future<int> adminGenerateHonorGuruBulk(
  WidgetRef ref, {
  required String tahunAjaranId,
  required String semesterId,
  required String periode, // "2025-10"
  required String periodeLabel, // "Oktober 2025"
  double defaultHonorMengajar = 500000,
  double defaultInsentif = 100000,
  double defaultTunjangan = 50000,
  double defaultPotongan = 0,
}) async {
  final client = ref.read(supabaseClientProvider);

  // Get all active guru
  final guruRes = await client.from('Guru').select('id').eq('status', GuruStatus.aktif).filter('deletedAt', 'is', null);
  final guruIds = (guruRes as List).map((r) => (r as Map<String, dynamic>)['id'] as String).toList();
  if (guruIds.isEmpty) return 0;

  // Check if already generated for this periode
  final existing = await client.from('HonorGuru').select('id').eq('periode', periode);
  if ((existing as List).isNotEmpty) {
    throw Exception('Honor untuk periode $periode sudah pernah di-generate');
  }

  final total = defaultHonorMengajar + defaultInsentif + defaultTunjangan - defaultPotongan;
  final rows = guruIds.map((guruId) => {
    'tahunAjaranId': tahunAjaranId,
    'semesterId': semesterId,
    'guruId': guruId,
    'periode': periode,
    'periodeLabel': periodeLabel,
    'honorMengajar': defaultHonorMengajar,
    'insentif': defaultInsentif,
    'tunjangan': defaultTunjangan,
    'potongan': defaultPotongan,
    'totalHonor': total,
    'status': HonorGuruStatus.draft,
  }).toList();

  await client.from('HonorGuru').insert(rows);
  ref.invalidate(honorGuruListAdminProvider);
  return guruIds.length;
}

// ===========================================================================
// SIKLUS — simplified read-only overview (no complex auto-tagihan)
// ===========================================================================

final siklusOverviewProvider = FutureProvider<SiklusOverview>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final ta = await ref.watch(tahunAjaranActiveProvider.future);
  final santriCount = await client.from('Santri').select('id').filter('deletedAt', 'is', null).eq('status', SantriStatus.aktif);
  final tagihanCount = await client.from('Tagihan').select('id, amount, paidAmount').neq('status', TagihanStatus.lunas);
  final paymentCount = await client.from('Payment').select('id').eq('status', PaymentStatus.verified);
  final totalOutstanding = (tagihanCount as List).fold<double>(0, (s, t) {
    final amount = ((t as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0;
    final paid = (t['paidAmount'] as num?)?.toDouble() ?? 0;
    return s + (amount - paid).clamp(0.0, double.infinity);
  });
  return SiklusOverview(tahunAjaran: ta, totalSantri: (santriCount as List).length, totalTagihanOutstanding: totalOutstanding, totalPaymentsVerified: (paymentCount as List).length);
});

class SiklusOverview {
  const SiklusOverview({this.tahunAjaran, required this.totalSantri, required this.totalTagihanOutstanding, required this.totalPaymentsVerified});
  final TahunAjaranModel? tahunAjaran;
  final int totalSantri;
  final double totalTagihanOutstanding;
  final int totalPaymentsVerified;
}

// ===========================================================================
// PENGUMUMAN
// ===========================================================================

final pengumumanListAdminProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Announcement').select().order('publishedAt', ascending: false).limit(50);
  return (res as List).map((r) => AnnouncementModel.fromJson(r as Map<String, dynamic>)).toList();
});

Future<AnnouncementModel> adminCreatePengumuman(WidgetRef ref, {required String title, required String content, String priority = AnnouncementPriority.normal, String audience = AnnouncementAudience.all}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Announcement').insert({'title': title, 'content': content, 'priority': priority, 'audience': audience, 'publishedAt': DateTime.now().toIso8601String(), 'createdById': client.auth.currentUser?.id}).select().single();
  ref.invalidate(pengumumanListAdminProvider);
  return AnnouncementModel.fromJson(res as Map<String, dynamic>);
}

Future<void> adminDeletePengumuman(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Announcement').delete().eq('id', id);
  ref.invalidate(pengumumanListAdminProvider);
}

// ===========================================================================
// NOTIFIKASI
// ===========================================================================

final notifikasiListAdminProvider = FutureProvider<List<NotifikasiAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Notifikasi').select('*, Wali(name)').order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return NotifikasiAdminModel(id: row['id'].toString(), waliName: ((row['Wali'] ?? row['wali'])?['name'] as String?) ?? '-', title: row['title'].toString(), message: row['message'].toString(), type: row['type'].toString(), priority: row['priority']?.toString() ?? 'NORMAL', isRead: (row['isRead'] as bool?) ?? false, createdAt: DateTime.parse(row['createdAt'].toString()));
  }).toList();
});

class NotifikasiAdminModel {
  const NotifikasiAdminModel({required this.id, required this.waliName, required this.title, required this.message, required this.type, required this.priority, required this.isRead, required this.createdAt});
  final String id;
  final String waliName;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
}

Future<void> adminDeleteNotifikasi(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Notifikasi').delete().eq('id', id);
  ref.invalidate(notifikasiListAdminProvider);
}

/// Create notifikasi manual (admin kirim push notification ke wali).
/// Notifikasi INSERT akan otomatis trigger FCM push via trigger.
Future<void> adminCreateNotifikasi(
  WidgetRef ref, {
  required String waliId,
  required String type,
  required String title,
  required String message,
  String? santriId,
  String priority = 'NORMAL',
  String? entityType,
  String? entityId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Notifikasi').insert({
    'waliId': waliId,
    'santriId': santriId,
    'type': type,
    'title': title,
    'message': message,
    'priority': priority,
    'entityType': entityType,
    'entityId': entityId,
    'isRead': false,
    'isPushSent': false,
  });
  ref.invalidate(notifikasiListAdminProvider);
}

/// Bulk create notifikasi untuk semua wali (broadcast).
Future<int> adminCreateNotifikasiBulk(
  WidgetRef ref, {
  required String type,
  required String title,
  required String message,
  String priority = 'NORMAL',
}) async {
  final client = ref.read(supabaseClientProvider);
  final waliRes = await client.from('Wali').select('id').filter('deletedAt', 'is', null).eq('activationStatus', 'ACTIVE');
  final waliIds = (waliRes as List).map((r) => (r as Map<String, dynamic>)['id'] as String).toList();
  if (waliIds.isEmpty) return 0;

  final rows = waliIds.map((wid) => {
    'waliId': wid,
    'type': type,
    'title': title,
    'message': message,
    'priority': priority,
    'isRead': false,
    'isPushSent': false,
  }).toList();

  await client.from('Notifikasi').insert(rows);
  ref.invalidate(notifikasiListAdminProvider);
  return waliIds.length;
}

// ===========================================================================
// SURAT — read-only list
// ===========================================================================

final suratListAdminProvider = FutureProvider<List<SuratAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Surat').select('*, Santri(name, nis)').order('tanggalSurat', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final santri = row['Santri'] as Map<String, dynamic>?;
    return SuratAdminModel(
      id: row['id'].toString(),
      nomorSurat: row['nomorSurat'] as String? ?? '-',
      type: row['type']?.toString() ?? '-',
      title: row['title'].toString(),
      santriName: (santri?['name'] as String?) ?? '-',
      status: row['status'] as String? ?? '-',
      tanggalSurat: row['tanggalSurat'] is String ? DateTime.parse(row['tanggalSurat'] as String) : null,
      fileUrl: row['fileUrl'] as String?,
      filePath: row['filePath'] as String?,
    );
  }).toList();
});

class SuratAdminModel {
  const SuratAdminModel({
    required this.id,
    required this.nomorSurat,
    required this.type,
    required this.title,
    required this.santriName,
    required this.status,
    this.tanggalSurat,
    this.fileUrl,
    this.filePath,
  });
  final String id;
  final String nomorSurat;
  final String type;
  final String title;
  final String santriName;
  final String status;
  final DateTime? tanggalSurat;
  /// Public/signed URL untuk PDF surat (di Supabase Storage bucket surat).
  final String? fileUrl;
  /// Path object PDF di Storage (untuk delete).
  final String? filePath;
}

Future<void> adminDeleteSurat(WidgetRef ref, String id) async {
  // Ambil filePath sebelum delete untuk hapus object di Storage
  final client = ref.read(supabaseClientProvider);
  final res = await client
      .from('Surat')
      .select('filePath')
      .eq('id', id)
      .maybeSingle();
  final filePath = res?['filePath'] as String?;
  if (filePath != null && filePath.isNotEmpty) {
    try {
      await ref.read(storageServiceProvider).delete(
            bucket: StorageBucket.surat,
            path: filePath,
          );
    } catch (_) {
      // Best-effort: tetap hapus DB row meski storage delete gagal
    }
  }
  await client.from('Surat').delete().eq('id', id);
  ref.invalidate(suratListAdminProvider);
}

/// Create surat (surat keterangan, surat pindah, dll).
Future<void> adminCreateSurat(
  WidgetRef ref, {
  required String santriId,
  required String type,
  required String title,
  String? nomorSurat,
  String? content,
  String status = 'DRAFT',
  DateTime? tanggalSurat,
  String? fileUrl,
  String? filePath,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Surat').insert({
    'santriId': santriId,
    'type': type,
    'title': title,
    if (nomorSurat != null) 'nomorSurat': nomorSurat,
    if (content != null) 'content': content,
    'status': status,
    'tanggalSurat': (tanggalSurat ?? DateTime.now()).toIso8601String(),
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (filePath != null) 'filePath': filePath,
  });
  ref.invalidate(suratListAdminProvider);
}

// ===========================================================================
// ALUMNI
// ===========================================================================

final alumniListAdminProvider = FutureProvider<List<AlumniAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Alumni').select('*, Santri(name, nis)').order('tanggalLulus', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    final santri = row['Santri'] as Map<String, dynamic>?;
    return AlumniAdminModel(id: row['id'].toString(), santriName: (santri?['name'] as String?) ?? '-', santriNis: (santri?['nis'] as String?) ?? '-', tahunLulus: (row['tahunLulus'] as num?)?.toInt() ?? 0, statusKelulusan: (row['statusKelulusan'] as String?) ?? '-', pekerjaan: (row['pekerjaan'] as String?) ?? '-', domisiliKota: (row['domisiliKota'] as String?) ?? '-');
  }).toList();
});

class AlumniAdminModel {
  const AlumniAdminModel({required this.id, required this.santriName, required this.santriNis, required this.tahunLulus, required this.statusKelulusan, required this.pekerjaan, required this.domisiliKota});
  final String id;
  final String santriName;
  final String santriNis;
  final int tahunLulus;
  final String statusKelulusan;
  final String pekerjaan;
  final String domisiliKota;
}

Future<void> adminDeleteAlumni(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Alumni').delete().eq('id', id);
  ref.invalidate(alumniListAdminProvider);
}

// ===========================================================================
// CHAT — read-only list of chat rooms
// ===========================================================================

final chatRoomsListAdminProvider = FutureProvider<List<ChatRoomAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('ChatRoom').select('*, Wali(name), Guru(name), Santri(name)').eq('isActive', true).order('lastMessageAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return ChatRoomAdminModel(id: row['id'].toString(), type: row['type'].toString(), waliName: ((row['Wali'] ?? row['wali'])?['name'] as String?) ?? '-', guruName: ((row['Guru'] ?? row['guru'])?['name'] as String?) ?? '-', santriName: ((row['Santri'] ?? row['santri'])?['name'] as String?) ?? '-', lastMessage: row['lastMessage'] as String?, lastMessageAt: row['lastMessageAt'] is String ? DateTime.parse(row['lastMessageAt'] as String) : null);
  }).toList();
});

class ChatRoomAdminModel {
  const ChatRoomAdminModel({required this.id, required this.type, required this.waliName, required this.guruName, required this.santriName, this.lastMessage, this.lastMessageAt});
  final String id;
  final String type;
  final String waliName;
  final String guruName;
  final String santriName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
}

// ===========================================================================
// QR — read-only list of scans
// ===========================================================================

final qrScanListAdminProvider = FutureProvider<List<QRScanAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('QRScan').select().order('createdAt', ascending: false).limit(100);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return QRScanAdminModel(id: row['id'].toString(), qrType: row['qrType'] as String? ?? '-', scanType: row['scanType'] as String? ?? '-', result: row['result'] as String? ?? '-', message: row['message']?.toString() ?? '-', createdAt: DateTime.parse(row['createdAt'].toString()));
  }).toList();
});

class QRScanAdminModel {
  const QRScanAdminModel({required this.id, required this.qrType, required this.scanType, required this.result, this.message, required this.createdAt});
  final String id;
  final String qrType;
  final String scanType;
  final String result;
  final String? message;
  final DateTime createdAt;
}

// ===========================================================================
// AUDIT LOG — read-only list
// ===========================================================================

final auditLogListAdminProvider = FutureProvider<List<AuditLogAdminModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('AuditLog').select().order('createdAt', ascending: false).limit(200);
  return (res as List).map((r) {
    final row = r as Map<String, dynamic>;
    return AuditLogAdminModel(id: row['id'].toString(), action: row['action'] as String? ?? '-', entity: row['entity'] as String? ?? '-', entityId: row['entityId'] as String?, details: row['details'] as String?, userId: row['userId'] as String?, createdAt: DateTime.parse(row['createdAt'].toString()));
  }).toList();
});

class AuditLogAdminModel {
  const AuditLogAdminModel({required this.id, required this.action, required this.entity, this.entityId, this.details, this.userId, required this.createdAt});
  final String id;
  final String action;
  final String entity;
  final String? entityId;
  final String? details;
  final String? userId;
  final DateTime createdAt;
}
