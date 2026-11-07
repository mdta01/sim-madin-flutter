// ============================================================================
// SIM MADIN — Mutation Providers (Phase 5 — mobile_wali)
// ============================================================================
// Mutations untuk wali santri:
//   - loginWali(phone, pin) — verify PIN + return token + wali + santriList
//   - requestOtp(phone, type) — generate OTP + (TODO: send via WA)
//   - verifyOtp(phone, otpCode) — verify OTP + return verifyToken
//   - setPin(verifyToken, pin) — set new PIN
//   - markNotifikasiRead(notifikasiId)
//   - sendChatMessageAsWali(roomId, message)
//   - startUjianSesi(ujianId, santriId) — start or resume sesi + shuffle soal
//   - submitUjianJawaban(sesiId, santriId, answers) — submit jawaban + compute
//
// Catatan security:
//   - PIN verification proper pakai bcrypt server-side (di backend Next.js
//     lama). Phase 5 Flutter port menggunakan simplified approach:
//     * Untuk dev/test: PIN plain text compare di RPC function.
//     * Untuk production: perlu Postgres RPC function dengan bcrypt verify.
//   - OTP send via WhatsApp membutuhkan WA Business API (Fonnte/Twilio/dll).
//     Phase 5 dev: OTP hanya di-log ke console + return devOtp ke client
//     (mirip TS app lama yang pakai `devOtp` field saat dev mode).
// ============================================================================


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import everything from query_providers.dart (supabaseClientProvider,
// realtimeRefreshTick, etc), query_providers_wali.dart (TypedWaliSession,
// waliSessionProvider, invalidateWaliQueries, etc).
import 'query_providers.dart';
import 'supabase_write.dart';
import 'query_providers_wali.dart';
// authStorageProvider is defined in api_client.dart (the barrel file).
// Dart handles circular imports for top-level declarations gracefully.
import 'api_client.dart';

/// Validate PIN — 6 digit + tidak di blacklist.
/// Throws dengan pesan user-friendly kalau invalid.
void _validatePin(String pin) {
  if (pin.length != 6) {
    throw Exception('PIN harus 6 digit');
  }
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
    throw Exception('PIN harus 6 digit angka');
  }
  if (kBlacklistedPins.contains(pin)) {
    throw Exception('PIN terlalu lemah (umum dipakai). Pilih PIN lain.');
  }
}

/// Validate phone — minimal 10 digit, format Indonesia.
void _validatePhone(String phone) {
  final normalized = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (normalized.length < 10 || normalized.length > 15) {
    throw Exception('Nomor WhatsApp tidak valid');
  }
}

// ---------------------------------------------------------------------------
// Login WA + PIN
// ---------------------------------------------------------------------------

/// Login wali dengan phone + PIN.
///
/// Phase 5 simplified flow:
/// 1. Query Wali by phone.
/// 2. Compare PIN plain text (UNTUK DEV SAJA — production pakai bcrypt).
/// 3. Check auto-lock (failedLoginAttempts >= 5 dan lockedUntil > now).
/// 4. Get list santri via SantriWali join.
/// 5. Generate pseudo-token (base64 of waliId + timestamp — bukan JWT proper).
/// 6. Save ke secure storage via AuthStorage.
/// 7. Return WaliSession + set waliSessionProvider.
///
/// TODO production:
/// - Pakai Postgres RPC `wali_login(phone, pin)` yang bcrypt-verify di server.
/// - Pakai proper JWT dengan HS256 signature.
/// - Implement rate limiting (5 attempts per 15 menit).
Future<TypedWaliSession> loginWali(
  WidgetRef ref, {
  required String phone,
  required String pin,
}) async {
  _validatePhone(phone);
  _validatePin(pin);

  final client = ref.read(supabaseClientProvider);
  final normalizedPhone = normalizeWhatsApp(phone) ?? phone;

  // === Production: call wali_login RPC (bcrypt PIN verify server-side) ===
  // RPC returns: { success, wali: {...}, santriList: [...] }
  // atau { success: false, message: "..." }
  // Normalisasi nomor di server juga (fungsi normalize_phone, migration 20),
  // jadi wali bisa login dengan format '0812...', '+62812...', atau '62812...'
  // apa pun format yang tersimpan di database.
  final rpcResult = await client.rpc<dynamic>('wali_login', params: {
    'p_phone': normalizedPhone,
    'p_pin': pin,
  });

  if (rpcResult == null) {
    throw Exception('Login gagal: response null dari server');
  }

  final result = rpcResult as Map<String, dynamic>;
  if (result['success'] != true) {
    throw Exception(result['message'] ?? 'Login gagal');
  }

  final waliData = result['wali'] as Map<String, dynamic>;
  final santriData = result['santriList'] as List<dynamic>;

  final wali = WaliModel.fromJson(waliData);
  final santriList = santriData
      .map((s) => SantriModel.fromJson(s as Map<String, dynamic>))
      .toList();

  // Sign in to Supabase Auth using per-wali random authPassword returned
  // by wali_login RPC (after PIN verify). This password is unique per wali
  // and stored in Wali.authPassword column (only accessible after PIN verify).
  String? authToken;
  final authPassword = waliData['authPassword'] as String?;
  if (wali.email != null && wali.email!.isNotEmpty && authPassword != null) {
    try {
      final authRes = await client.auth.signInWithPassword(
        email: wali.email!,
        password: authPassword,
      );
      authToken = authRes.session?.accessToken;
    } catch (e) {
      debugPrint('Wali Supabase Auth sign-in failed: $e');
    }
  }

  final token = authToken ??
      '${wali.id}:${DateTime.now().millisecondsSinceEpoch}';

  final session = TypedWaliSession(
    token: token,
    wali: wali,
    santriList: santriList,
  );

  // Save ke secure storage
  await ref.read(authStorageProvider).saveWaliSession(
        token: token,
        wali: waliData,
        santriList: santriData.cast<Map<String, dynamic>>().toList(),
      );
  ref.read(waliSessionProvider.notifier).state = session;

  // Save FCM token
  if (wali.userId != null && wali.userId!.isNotEmpty) {
    try {
      await _saveFcmTokenForWali(ref, wali.userId!);
    } catch (_) {}
  }

  return session;
}

/// Helper: save FCM token ke User table untuk wali.
/// Pakai SupabaseClient langsung (bukan NotificationService) karena
/// wali auth berbeda dari Supabase Auth.
Future<void> _saveFcmTokenForWali(WidgetRef ref, String userId) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null) return;

    final client = ref.read(supabaseClientProvider);
    await client.from('User').update({
      'fcmToken': token,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // Listen token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      await client.from('User').update({
        'fcmToken': newToken,
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    });
  } catch (_) {
    // Best-effort.
  }
}

// ---------------------------------------------------------------------------
// Forgot PIN — OTP flow (verifikasi sepenuhnya di server)
// ---------------------------------------------------------------------------
// Sebelumnya OTP di-generate & dibandingkan di CLIENT, OTP dikembalikan ke
// pemanggil, disimpan plain-text di `Wali.otpCode`, dan `wali_set_pin()`
// bisa dipanggil anon hanya dengan wali id (bypass autentikasi).
//
// Sekarang semua verifikasi ada di RPC Postgres (lihat migration 20):
//   wali_request_otp(phone)        -> OTP di-hash bcrypt, tidak dikembalikan
//                                     (kecuali SystemSetting OTP_DEBUG=true)
//   wali_verify_otp(phone, otp)    -> terbitkan reset token sekali pakai
//   wali_reset_pin(token, pin)     -> set PIN baru setelah token valid
// ---------------------------------------------------------------------------

/// Hasil permintaan OTP.
///
/// [debugOtp] hanya terisi kalau admin menyalakan `SystemSetting.OTP_DEBUG`.
/// Di production nilainya harus null — UI tidak boleh menampilkannya.
class OtpRequestResult {
  const OtpRequestResult({required this.message, this.debugOtp});
  final String message;
  final String? debugOtp;
}

/// Minta kode OTP reset PIN untuk [phone].
///
/// Tidak melempar exception untuk nomor yang tidak terdaftar — server sengaja
/// memberi pesan seragam supaya penyerang tidak bisa memakai endpoint ini
/// untuk menebak nomor mana yang terdaftar (user enumeration).
Future<OtpRequestResult> requestOtp(
  WidgetRef ref, {
  required String phone,
  String type = 'FORGOT_PIN',
}) async {
  _validatePhone(phone);
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('wali_request_otp', params: {
    'p_phone': normalizeWhatsApp(phone) ?? phone,
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  if (map['success'] != true) {
    throw Exception(map['message'] ?? 'Gagal mengirim OTP');
  }
  return OtpRequestResult(
    message: (map['message'] as String?) ?? 'Kode OTP dikirim.',
    debugOtp: map['otp'] as String?,
  );
}

/// Verifikasi OTP dan kembalikan reset token sekali pakai.
///
/// Token diterbitkan & disimpan (dalam bentuk hash) oleh server, jadi proses
/// reset tetap jalan walaupun aplikasi sempat di-restart.
Future<String> verifyOtp(
  WidgetRef ref, {
  required String phone,
  required String otpCode,
}) async {
  _validatePhone(phone);
  if (otpCode.length != 6) {
    throw Exception('OTP harus 6 digit');
  }
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('wali_verify_otp', params: {
    'p_phone': normalizeWhatsApp(phone) ?? phone,
    'p_otp': otpCode,
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  if (map['success'] != true) {
    throw Exception(map['message'] ?? 'OTP salah');
  }
  final token = map['resetToken'] as String?;
  if (token == null || token.isEmpty) {
    throw Exception('Server tidak mengembalikan token reset');
  }
  return token;
}

/// Set PIN baru memakai reset token dari [verifyOtp].
Future<void> setNewPin(
  WidgetRef ref, {
  required String verifyToken,
  required String newPin,
}) async {
  _validatePin(newPin);
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('wali_reset_pin', params: {
    'p_reset_token': verifyToken,
    'p_new_pin': newPin,
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  if (map['success'] != true) {
    throw Exception(map['message'] ?? 'Gagal mengubah PIN');
  }
}

// ---------------------------------------------------------------------------
// Logout
// ---------------------------------------------------------------------------

Future<void> logoutWali(WidgetRef ref) async {
  // Unsubscribe realtime channels (prevent leak + double-trigger).
  await disposeAppRealtime(ref);
  // Clear secure storage
  await ref.read(authStorageProvider).clear();
  // Clear session provider
  ref.read(waliSessionProvider.notifier).state = null;
  // Invalidate query providers
  invalidateWaliQueries(ref);
}

// ---------------------------------------------------------------------------
// Notifikasi mark as read
// ---------------------------------------------------------------------------

Future<void> markNotifikasiRead(
  WidgetRef ref,
  String notifikasiId,
) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Notifikasi').update({
    'isRead': true,
    'readAt': DateTime.now().toIso8601String(),
  }).eq('id', notifikasiId);
  ref.invalidate(notifikasiWaliProvider);
  // Invalidate juga notifikasiAnakProvider (family) supaya tab Notif per santri
  // ikut refresh — sebelumnya hanya invalidate notifikasiWaliProvider yang
  // tidak dipakai lagi di _NotifTab.
  ref.invalidate(notifikasiAnakProvider);
}

// ---------------------------------------------------------------------------
// Chat — send message as wali
// ---------------------------------------------------------------------------

Future<void> sendChatMessageAsWali(
  WidgetRef ref, {
  required String roomId,
  required String message,
}) async {
  final session = ref.read(waliSessionProvider);
  if (session == null) throw Exception('Sesi wali tidak ditemukan');

  final client = ref.read(supabaseClientProvider);
  await client.from('ChatMessage').insert(rowFor('ChatMessage', {
    'chatRoomId': roomId,
    'senderType': ChatSenderType.wali,
    'senderWaliId': session.wali.id,
    'message': message,
    'isRead': false,
  }));

  // Update lastMessage + lastMessageAt di ChatRoom
  await client.from('ChatRoom').update({
    'lastMessage': message,
    'lastMessageAt': DateTime.now().toIso8601String(),
  }).eq('id', roomId);

  ref.invalidate(chatMessagesWaliProvider(roomId));
  ref.invalidate(chatRoomsWaliProvider);
  // Invalidate juga unread count — supaya badge di chat list ikut update
  // (kalau pesan terakhir dari wali, semua unread dari guru tetap, tapi
  // kalau baru masuk room, mungkin ada perubahan status isRead).
  ref.invalidate(chatUnreadCountWaliProvider);
}

// ---------------------------------------------------------------------------
// Ujian — start/resume sesi
// ---------------------------------------------------------------------------

/// Start ujian sesi untuk santri. Kalau sudah ada sesi yang belum selesai,
/// resume sesi tersebut (untuk recovery — mis. app crash).
/// Pakai sesi ujian milik santri untuk ujian tertentu.
///
/// Recovery: kalau sudah ada sesi (mis. app tertutup di tengah ujian), sesi
/// itu dikembalikan APA ADANYA — termasuk `startTime` aslinya. Tanpa ini,
/// timer akan mulai dari nol setiap kali app dibuka ulang dan waktu ujian
/// bisa dipakai berulang kali (santri tinggal restart app untuk reset timer).
///
/// Catatan: urutan soal (soalOrder) yang tersimpan di sesi juga dipakai
/// kembali, jadi santri yang resume tidak mendapat urutan soal baru.
Future<UjianSesiData> startUjianSesi(
  WidgetRef ref, {
  required String ujianId,
  required String santriId,
}) async {
  final client = ref.read(supabaseClientProvider);

  // Sesi apapun yang sudah pernah dibuat (termasuk yang sudah FINISHED).
  // Kalau FINISHED, ujian sudah selesai dan tidak boleh dikerjakan ulang.
  final existingRes = await client
      .from('UjianSesi')
      .select()
      .eq('ujianId', ujianId)
      .eq('santriId', santriId)
      .order('createdAt', ascending: false)
      .limit(1)
      .maybeSingle();

  if (existingRes != null) {
    final existing = UjianSesiData.fromJson(existingRes as Map<String, dynamic>);
    if (existing.status == 'FINISHED') {
      throw Exception(
        'Ujian ini sudah Anda selesaikan dan tidak dapat dikerjakan ulang.',
      );
    }
    return existing; // resume
  }

  // Get soal list untuk shuffle
  final soalRes = await client
      .from('UjianSoal')
      .select('id')
      .eq('ujianId', ujianId)
      .limit(100).order('urutan');
  final soalIds = (soalRes as List)
      .map((r) => (r as Map<String, dynamic>)['id'] as String)
      .toList();

  // Fisher-Yates shuffle soal order (persist per santri — supaya kalau
  // resume, urutan soal tetap sama).
  final shuffledSoalIds = fisherYatesShuffle(soalIds);

  // Create new sesi
  final body = {
    'ujianId': ujianId,
    'santriId': santriId,
    'startTime': DateTime.now().toIso8601String(),
    'status': 'ONGOING',
    'soalOrder': shuffledSoalIds
        .map((id) => '"$id"')
        .join(','),
  };
  final res = await client
      .from('UjianSesi')
      .insert(rowFor('UjianSesi', body))
      .select()
      .single();
  return UjianSesiData.fromJson((res as Map<String, dynamic>));
}

/// Simpan jawaban sementara (draft) TANPA menutup sesi.
///
/// Sebelumnya jawaban hanya ada di memori sampai `submit_ujian` dipanggil.
/// Kalau aplikasi tertutup, HP mati, atau koneksi putus, seluruh pekerjaan
/// santri hilang. Autosave memanggil fungsi ini secara berkala.
///
/// Aman dipanggil berulang: upsert berdasarkan (sesiId, ujianSoalId).
Future<void> saveUjianAnswerDraft(
  WidgetRef ref, {
  required String sesiId,
  required String santriId,
  required List<UjianJawabanSubmit> answers,
}) async {
  final toSave = answers.where((a) => a.answer.trim().isNotEmpty).toList();
  if (toSave.isEmpty) return;

  final rows = toSave
      .map((a) => rowFor('UjianJawaban', {
            'sesiId': sesiId,
            'ujianSoalId': a.ujianSoalId,
            'santriId': santriId,
            'answer': a.answer,
            if (a.optionOrder != null) 'optionOrder': a.optionOrder,
            'isAutoCorrected': false,
          }))
      .toList();

  await ref
      .read(supabaseClientProvider)
      .from('UjianJawaban')
      .upsert(rows, onConflict: '"sesiId","ujianSoalId"');
}

/// Sisa waktu ujian menurut SERVER (otoritatif).
///
/// Timer di layar ujian hanya untuk tampilan; nilai yang mengikat adalah
/// hasil RPC ini karena jam perangkat bisa diubah santri. Mengembalikan
/// null kalau gagal, supaya layar bisa jatuh ke perhitungan lokal.
Future<int?> ujianRemainingSeconds(WidgetRef ref, String sesiId) async {
  try {
    final res = await ref
        .read(supabaseClientProvider)
        .rpc<dynamic>('ujian_remaining_seconds', params: {'p_sesi_id': sesiId});
    if (res is int) return res;
    if (res is num) return res.toInt();
    return null;
  } catch (_) {
    return null;
  }
}

/// Submit jawaban ujian + compute score (auto-correct untuk PG).
Future<double> submitUjianJawaban(
  WidgetRef ref, {
  required String sesiId,
  required String ujianId,
  required String santriId,
  required List<UjianJawabanSubmit> answers,
  bool auto = false,
}) async {
  final client = ref.read(supabaseClientProvider);

  // Insert/update jawaban (upsert by sesiId + ujianSoalId)
  final rows = answers.map((a) {
    return {
      'sesiId': sesiId,
      'ujianSoalId': a.ujianSoalId,
      'santriId': santriId,
      'answer': a.answer,
      if (a.optionOrder != null) 'optionOrder': a.optionOrder,
      'isAutoCorrected': false, // will be set true after auto-correct
    };
  }).toList();
  await client
      .from('UjianJawaban')
      .upsert(rows, onConflict: '"sesiId","ujianSoalId"');

  // Auto-correct: untuk PG, compare answer dengan BankSoal.correctAnswer.
  // Get soal list with BankSoal
  final soalRes = await client
      .from('UjianSoal')
      .select('id, bobot, BankSoal(type, correctAnswer)')
      .eq('ujianId', ujianId);
  final soalList = soalRes as List;

  double totalScore = 0;
  double totalBobot = 0;

  for (final soalRow in soalList) {
    final s = soalRow as Map<String, dynamic>;
    final soalId = s['id'] as String;
    final bobot = (s['bobot'] as num?)?.toDouble() ?? 1.0;
    totalBobot += bobot;

    final bankSoal = s['BankSoal'] as Map<String, dynamic>?;
    final type = bankSoal?['type'] as String?;
    final correctAnswer = bankSoal?['correctAnswer'] as String?;

    // Find submitted answer
    final submitted = answers.where((a) => a.ujianSoalId == soalId).firstOrNull;
    if (submitted == null || submitted.answer.isEmpty) continue;

    bool isCorrect = false;
    double score = 0;

    if (type == SoalType.pg) {
      // Auto-correct: compare answer letter
      if (correctAnswer != null &&
          correctAnswer.toUpperCase() == submitted.answer.toUpperCase()) {
        isCorrect = true;
        score = bobot;
      }
    }
    // For ISIAN/ESSAY: skip auto-correct (guru akan grade manual)

    totalScore += score;

    // Update jawaban with correction result
    if (type == SoalType.pg) {
      await client.from('UjianJawaban').update({
        'isCorrect': isCorrect,
        'score': score,
        'isAutoCorrected': true,
      }).eq('sesiId', sesiId).eq('ujianSoalId', soalId);
    }
  }

  // Convert to 0-100 scale
  final finalScore = totalBobot > 0
      ? ((totalScore / totalBobot) * 100).toDouble()
      : 0.0;

  // Update sesi: status FINISHED + score + endTime
  await client.from('UjianSesi').update({
    'status': 'FINISHED',
    'endTime': DateTime.now().toIso8601String(),
    'score': finalScore,
    'durationUsed': DateTime.now()
        .difference((await _getSesiStartTime(client, sesiId)))
        .inSeconds,
  }).eq('id', sesiId);

  // Create/update UjianNilai record
  await client.from('UjianNilai').upsert({
    'ujianId': ujianId,
    'santriId': santriId,
    'score': finalScore,
    'isAutoCorrect': true,
    'gradedAt': DateTime.now().toIso8601String(),
  }, onConflict: '"ujianId","santriId"');

  return finalScore;
}

Future<DateTime> _getSesiStartTime(
    SupabaseClient client, String sesiId) async {
  final res = await client
      .from('UjianSesi')
      .select('startTime')
      .eq('id', sesiId)
      .single();
  return DateTime.parse(res['startTime'] as String);
}

/// Submission payload for ujian jawaban.
class UjianJawabanSubmit {
  const UjianJawabanSubmit({
    required this.ujianSoalId,
    required this.answer,
    this.optionOrder,
  });

  final String ujianSoalId;
  final String answer;
  final String? optionOrder; // JSON string for shuffled option indices
}
