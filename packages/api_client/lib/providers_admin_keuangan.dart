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
    return NotifikasiAdminModel(id: row['id'].toString(), waliName: (row['Wali'] ?? row['wali'])?['name'] ?? '-', title: row['title'].toString(), message: row['message'].toString(), type: row['type'].toString(), priority: row['priority']?.toString() ?? 'NORMAL', isRead: (row['isRead'] as bool?) ?? false, createdAt: DateTime.parse(row['createdAt'].toString()));
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
    return SuratAdminModel(id: row['id'].toString(), nomorSurat: row['nomorSurat'] as String? ?? '-', type: row['type']?.toString() ?? '-', title: row['title'].toString(), santriName: santri?['name'] ?? '-', status: row['status'] as String? ?? '-', tanggalSurat: row['tanggalSurat'] is String ? DateTime.parse(row['tanggalSurat'] as String) : null);
  }).toList();
});

class SuratAdminModel {
  const SuratAdminModel({required this.id, required this.nomorSurat, required this.type, required this.title, required this.santriName, required this.status, this.tanggalSurat});
  final String id;
  final String nomorSurat;
  final String type;
  final String title;
  final String santriName;
  final String status;
  final DateTime? tanggalSurat;
}

Future<void> adminDeleteSurat(WidgetRef ref, String id) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Surat').delete().eq('id', id);
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
    return AlumniAdminModel(id: row['id'].toString(), santriName: santri?['name'] ?? '-', santriNis: santri?['nis'] ?? '-', tahunLulus: (row['tahunLulus'] as num?)?.toInt() ?? 0, statusKelulusan: (row['statusKelulusan'] as String?) ?? '-', pekerjaan: (row['pekerjaan'] as String?) ?? '-', domisiliKota: (row['domisiliKota'] as String?) ?? '-');
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
    return ChatRoomAdminModel(id: row['id'].toString(), type: row['type'].toString(), waliName: (row['Wali'] ?? row['wali'])?['name'] ?? '-', guruName: (row['Guru'] ?? row['guru'])?['name'] ?? '-', santriName: (row['Santri'] ?? row['santri'])?['name'] ?? '-', lastMessage: row['lastMessage'] as String?, lastMessageAt: row['lastMessageAt'] is String ? DateTime.parse(row['lastMessageAt'] as String) : null);
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
