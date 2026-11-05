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

import 'dart:convert';

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
import 'query_providers_wali.dart';
// authStorageProvider is defined in api_client.dart (the barrel file).
// Dart handles circular imports for top-level declarations gracefully.
import 'api_client.dart';

/// Blacklist 50 PIN lemah — tidak boleh dipakai.
/// Port dari packages/shared/lib/constants.dart kBlacklistedPins.
/// Contoh: 000000, 111111, 123456, 654321, 258000, dll.
const _kBlacklistedPins = kBlacklistedPins; // re-export dari constants

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

  // Query wali by phone
  final waliRes = await client
      .from('Wali')
      .select()
      .eq('phone', normalizedPhone)
      .filter('deletedAt', 'is', null)
      .maybeSingle();

  if (waliRes == null) {
    throw Exception('Nomor WhatsApp tidak terdaftar');
  }

  final wali = WaliModel.fromJson(waliRes);

  // Check auto-lock
  if (wali.activationStatus == WaliActivationStatus.suspended) {
    throw Exception('Akun Anda dinonaktifkan. Hubungi admin madrasah.');
  }
  // Hanya wali dengan status ACTIVE yang boleh login.
  // PENDING / PENDING_NO_PHONE harus di-approve admin dulu.
  if (wali.activationStatus != WaliActivationStatus.active) {
    throw Exception(
        'Akun belum aktif (status: ${wali.activationStatus}). Hubungi admin madrasah untuk aktivasi.');
  }
  if (wali.lockedUntil != null &&
      wali.lockedUntil!.isAfter(DateTime.now())) {
    final remaining = wali.lockedUntil!.difference(DateTime.now()).inMinutes;
    throw Exception(
        'Akun terkunci. Coba lagi dalam $remaining menit.');
  }

  // Phase 5 DEV: PIN plain text comparison.
  // Production: ganti dengan bcrypt-verify via RPC function.
  // Untuk testing, admin dapat set PIN manual di DB: UPDATE "Wali" SET "pinHash" = '123456' WHERE phone = '...'
  if (wali.pinHash != pin) {
    // Increment failed attempts
    final newAttempts = (wali.failedLoginAttempts ?? 0) + 1;
    final shouldLock = newAttempts >= 5;
    await client.from('Wali').update({
      'failedLoginAttempts': newAttempts,
      if (shouldLock)
        'lockedUntil': DateTime.now()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
    }).eq('id', wali.id);

    if (shouldLock) {
      throw Exception(
          'Akun terkunci 15 menit karena 5x salah PIN. Coba lagi nanti.');
    }
    throw Exception(
        'PIN salah. Sisa percobaan: ${5 - newAttempts}');
  }

  // Login berhasil — reset failed attempts + update lastLoginAt
  await client.from('Wali').update({
    'failedLoginAttempts': 0,
    'lockedUntil': null,
    'lastLoginAt': DateTime.now().toIso8601String(),
  }).eq('id', wali.id);

  // CRITICAL: Sign in to Supabase Auth with linked User's email
  // so that auth.uid() is available for RLS policies.
  // Phase dev: password is 'admin123' for all seed users.
  // Production: use RPC function with service_role to create proper JWT.
  String? authToken;
  if (wali.email != null && wali.email!.isNotEmpty) {
    try {
      final authRes = await client.auth.signInWithPassword(
        email: wali.email!,
        password: 'admin123', // Phase dev — production: use proper auth
      );
      authToken = authRes.session?.accessToken;
    } catch (e) {
      // If Supabase Auth sign-in fails, continue with anon session
      // (wali can still see basic data via anon, but RLS will block
      // wali-specific queries).
      debugPrint('Wali Supabase Auth sign-in failed: $e');
    }
  }

  // Get santri list via SantriWali join.
  // Client is authenticated after signInWithPassword (if email existed).
  final santriRes = await client
      .from('SantriWali')
      .select('*, Santri(*, Kelas(*))')
      .eq('waliId', wali.id)
      .eq('canAccess', true);
  final santriList = (santriRes as List)
      .map((r) {
        final santri = (r as Map<String, dynamic>)['Santri']
            as Map<String, dynamic>?;
        if (santri == null) return null;
        final kelas = santri['Kelas'] as Map<String, dynamic>?;
        return SantriModel.fromJson({
          ...santri,
          if (kelas != null) 'kelasName': kelas['name'],
          if (kelas != null) 'kelasCode': kelas['code'],
        });
      })
      .where((s) => s != null)
      .cast<SantriModel>()
      .toList();

  // Use Supabase Auth access token (proper JWT) if available.
  // Fall back to pseudo-token if Supabase Auth sign-in failed.
  final token = authToken ?? '${wali.id}:${DateTime.now().millisecondsSinceEpoch}';

  final session = TypedWaliSession(
    token: token,
    wali: wali,
    santriList: santriList,
  );

  // Save ke secure storage + set provider.
  // CRITICAL: Simpan flattened Santri map (dengan nested Kelas di-merge ke
  // top-level), BUKAN raw SantriWali row. Kalau tidak, splash_screen gagal
  // parse SantriModel.fromJson (yang butuh 'name','nis','gender','entryDate'
  // di top-level) → catch block redirect ke /login setiap app restart.
  final santriMapsForStorage = (santriRes as List)
      .map((r) {
        final santri =
            (r as Map<String, dynamic>)['Santri'] as Map<String, dynamic>?;
        if (santri == null) return null;
        final kelas = santri['Kelas'] as Map<String, dynamic>?;
        return <String, dynamic>{
          ...santri,
          if (kelas != null) 'kelasName': kelas['name'],
          if (kelas != null) 'kelasCode': kelas['code'],
        };
      })
      .whereType<Map<String, dynamic>>()
      .toList();

  await ref.read(authStorageProvider).saveWaliSession(
        token: token,
        wali: waliRes,
        santriList: santriMapsForStorage,
      );
  ref.read(waliSessionProvider.notifier).state = session;

  // Save FCM token untuk push notification (kalau wali punya userId link)
  // Wali yang login via WA+PIN belum tentu punya Supabase Auth user.
  // Kalau ada (via admin link), simpan FCM token ke User.fcmToken.
  if (wali.userId != null && wali.userId!.isNotEmpty) {
    try {
      await _saveFcmTokenForWali(ref, wali.userId!);
    } catch (_) {
      // Best-effort — jangan fail login kalau FCM token gagal disimpan.
    }
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
// Forgot PIN — OTP flow
// ---------------------------------------------------------------------------

/// Request OTP untuk reset PIN.
///
/// Phase 5 simplified: OTP di-generate random 6 digit, disimpan di
/// Wali.otpCode + otpExpiresAt (5 menit). OTP dikirim via WA gateway
/// (Fonnte/Twilio) di production. Untuk dev, return OTP di response
/// supaya bisa di-test tanpa WA.
///
/// Rate limit: max 5 OTP per jam per phone.
Future<String> requestOtp(
  WidgetRef ref, {
  required String phone,
  String type = 'FORGOT_PIN',
}) async {
  _validatePhone(phone);
  final client = ref.read(supabaseClientProvider);
  final normalizedPhone = normalizeWhatsApp(phone) ?? phone;

  // Query wali by phone
  final waliRes = await client
      .from('Wali')
      .select()
      .eq('phone', normalizedPhone)
      .filter('deletedAt', 'is', null)
      .maybeSingle();
  if (waliRes == null) {
    throw Exception('Nomor WhatsApp tidak terdaftar');
  }
  final wali = WaliModel.fromJson(waliRes);

  // Check rate limit (5 per jam)
  final now = DateTime.now();
  final resetAt = wali.otpRequestResetAt;
  final currentCount = wali.otpRequestCount ?? 0;
  if (resetAt != null && now.isBefore(resetAt) && currentCount >= 5) {
    final remaining = resetAt.difference(now).inMinutes;
    throw Exception(
        'Terlalu banyak request OTP. Coba lagi dalam $remaining menit.');
  }

  // Generate OTP
  final otp = generateOtp();
  final newCount = (resetAt != null && now.isBefore(resetAt))
      ? currentCount + 1
      : 1;
  final newResetAt = newCount == 1
      ? now.add(const Duration(hours: 1))
      : resetAt;

  // Save OTP + reset attempts
  await client.from('Wali').update({
    'otpCode': otp,
    'otpExpiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
    'otpAttempts': 0,
    'otpRequestCount': newCount,
    'otpRequestResetAt': newResetAt?.toIso8601String(),
  }).eq('id', wali.id);

  // TODO production: kirim OTP via WA gateway (Fonnte/Twilio).
  // Untuk dev: return OTP langsung supaya user bisa test tanpa WA.
  return otp;
}

/// Verify OTP + return verifyToken (untuk setPin selanjutnya).
///
/// Phase 5 simplified: verifyToken = base64(waliId + ':verified:' + timestamp).
/// Production: JWT proper dengan short expiry (5 menit).
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
  final normalizedPhone = normalizeWhatsApp(phone) ?? phone;

  final waliRes = await client
      .from('Wali')
      .select()
      .eq('phone', normalizedPhone)
      .filter('deletedAt', 'is', null)
      .maybeSingle();
  if (waliRes == null) {
    throw Exception('Nomor WhatsApp tidak terdaftar');
  }
  final wali = WaliModel.fromJson(waliRes);

  // Check OTP expiry
  if (wali.otpExpiresAt == null ||
      wali.otpExpiresAt!.isBefore(DateTime.now())) {
    throw Exception('OTP kedaluwarsa. Request OTP baru.');
  }

  // Check OTP attempts (max 5)
  final attempts = wali.otpAttempts ?? 0;
  if (attempts >= 5) {
    throw Exception('Terlalu banyak percobaan OTP salah. Request OTP baru.');
  }

  if (wali.otpCode != otpCode) {
    await client.from('Wali').update({
      'otpAttempts': attempts + 1,
    }).eq('id', wali.id);
    throw Exception('OTP salah. Sisa percobaan: ${5 - attempts - 1}');
  }

  // OTP valid — clear otpCode + generate verifyToken
  // CRITICAL: pakai proper base64 encode supaya token unik per wali + per
  // timestamp. Sebelumnya pakai Uri.dataFromString(...).toString().split(',')[0]
  // yang selalu return "data:;base64" (konstan untuk semua wali) — security hole.
  // TODO production: pakai proper signed JWT dengan HS256 + secret di env.
  final rawPayload =
      '${wali.id}:${DateTime.now().millisecondsSinceEpoch}';
  final verifyToken = base64Encode(utf8.encode(rawPayload));
  await client.from('Wali').update({
    'otpCode': null,
    'otpExpiresAt': null,
    'otpAttempts': 0,
  }).eq('id', wali.id);

  // Phase 5: simpan verifyToken ke state provider sementara.
  // Production: return signed JWT dengan expiry 5 menit.
  ref.read(otpVerifyTokenProvider.notifier).state =
      (waliId: wali.id, token: verifyToken, createdAt: DateTime.now());

  return verifyToken;
}

/// Set new PIN (after OTP verified).
Future<void> setNewPin(
  WidgetRef ref, {
  required String verifyToken,
  required String newPin,
}) async {
  _validatePin(newPin);

  // Verify token match (Phase 5 simplified — production: JWT verify)
  final stored = ref.read(otpVerifyTokenProvider);
  if (stored == null || stored.token != verifyToken) {
    throw Exception('Token verifikasi tidak valid. Ulangi dari awal.');
  }
  // Check token age (max 5 menit)
  if (DateTime.now().difference(stored.createdAt).inMinutes > 5) {
    throw Exception('Token verifikasi kedaluwarsa. Ulangi dari awal.');
  }

  final client = ref.read(supabaseClientProvider);
  // Phase 5 DEV: simpan PIN plain text di kolom pinHash.
  // Production: hash dengan bcrypt sebelum simpan.
  await client.from('Wali').update({
    'pinHash': newPin, // TODO production: bcrypt.hash(newPin)
  }).eq('id', stored.waliId);

  // Clear verifyToken
  ref.read(otpVerifyTokenProvider.notifier).state = null;
}

/// Provider untuk menyimpan verifyToken sementara (setelah OTP verify).
/// Production: ganti dengan JWT yang self-contained (tidak butuh state).
final otpVerifyTokenProvider =
    StateProvider<({String waliId, String token, DateTime createdAt})?>(
        (_) => null);

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
  await client.from('ChatMessage').insert({
    'chatRoomId': roomId,
    'senderType': ChatSenderType.wali,
    'senderWaliId': session.wali.id,
    'message': message,
    'isRead': false,
  });

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
Future<UjianSesiData> startUjianSesi(
  WidgetRef ref, {
  required String ujianId,
  required String santriId,
}) async {
  final client = ref.read(supabaseClientProvider);

  // Check existing sesi yang belum finished
  final existingRes = await client
      .from('UjianSesi')
      .select()
      .eq('ujianId', ujianId)
      .eq('santriId', santriId)
      .neq('status', 'FINISHED')
      .order('createdAt', ascending: false)
      .limit(1)
      .maybeSingle();

  if (existingRes != null) {
    // Resume existing sesi
    return UjianSesiData.fromJson(existingRes);
  }

  // Get soal list untuk shuffle
  final soalRes = await client
      .from('UjianSoal')
      .select('id')
      .eq('ujianId', ujianId)
      .order('urutan');
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
      .insert(body)
      .select()
      .single();
  return UjianSesiData.fromJson(res);
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
