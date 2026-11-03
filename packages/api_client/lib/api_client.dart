// ============================================================================
// SIM MADIN — API Client (Dio + Serverpod-generated client)
// ============================================================================
// Wrapper untuk komunikasi dengan backend Serverpod.
// Untuk Phase 1 (foundation), hanya berisi:
//   - Dio HTTP client dengan auth interceptor
//   - Wali session storage (SecureStore)
//   - Riverpod providers (auth state, current user)
//
// Phase 2+ tambahan: lihat `query_providers.dart` — Riverpod FutureProviders
// untuk query Supabase Postgres langsung (Santri, Absensi, Nilai, Tagihan,
// Payment, HonorGuru, TransaksiKas, Kas). Saat Serverpod siap, providers ini
// bisa diganti dengan endpoint RPC — signature tetap sama.
//
// Phase 3+ tambahan: lihat `mutation_providers.dart` — MUTATION providers
// (createPembayaran, verifyPembayaran, rejectPembayaran, createTransaksiKas,
// updateHonorGuruStatus, generateHonorGuruBulk) + laporanKeuanganProvider
// (compute-on-read aggregate).
//
// Phase 4+ tambahan: lihat `query_providers_guru.dart` + `mutation_providers_guru.dart`
// — Riverpod providers untuk mobile_guru (Jadwal, Materi, Tugas, Pertemuan,
// Ujian, BankSoal, Perkembangan, Chat) + mutations (bulkCreateAbsensi,
// bulkCreateNilai, createMateri/Tugas/Pertemuan/Ujian, gradePengumpulan,
// createPerkembanganQuran/Kitab/Akhlak/Pembinaan, sendChatMessage).
//
// Phase 5+ tambahan: lihat `query_providers_wali.dart` + `mutation_providers_wali.dart`
// — Riverpod providers untuk mobile_wali (santriAnak, absensiAnak, nilaiAnak,
// tagihanAnak, ujianPesertaAnak, notifikasiWali, chatRoomsWali, pengumumanWali,
// perkembanganAnak, ujianDetailForWali) + mutations (loginWali, requestOtp,
// verifyOtp, setNewPin, markNotifikasiRead, sendChatMessageAsWali,
// startUjianSesi, submitUjianJawaban).
// ============================================================================

export 'query_providers.dart';
export 'mutation_providers.dart';
export 'query_providers_guru.dart';
export 'mutation_providers_guru.dart';
export 'query_providers_wali.dart';
export 'mutation_providers_wali.dart';
export 'query_providers_admin.dart';
export 'mutation_providers_admin.dart';
export 'providers_admin_masterdata.dart';
export 'providers_admin_akademik.dart';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared/shared.dart';

/// Konfigurasi dasar untuk Dio HTTP client.
class ApiClientConfig {
  const ApiClientConfig({
    this.baseUrl = 'http://localhost:8080',
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
  });
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}

/// Provider konfigurasi API client.
/// Override di main.dart untuk setiap app (admin desktop vs mobile).
final apiClientConfigProvider = Provider<ApiClientConfig>((ref) {
  return const ApiClientConfig(
    baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080'),
  );
});

/// Provider Dio HTTP client dengan auth interceptor.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiClientConfigProvider);
  final dio = Dio(BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  // Auth interceptor: tambahkan Authorization header untuk setiap request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Cek token admin (Supabase) atau wali (custom JWT)
      final token = await ref.read(authTokenProvider.future);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) async {
      // Auto-logout kalau 401
      if (err.response?.statusCode == 401) {
        await ref.read(authStorageProvider).clear();
        ref.invalidate(currentUserProvider);
      }
      handler.next(err);
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[DIO] $obj'),
    ));
  }

  return dio;
});

/// Secure storage untuk token & session data.
final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

/// Storage untuk auth state (Supabase admin token ATAU wali custom JWT).
class AuthStorage {
  AuthStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_data';
  static const _waliTokenKey = 'wali_token';
  static const _waliDataKey = 'wali_data';
  static const _waliSantriKey = 'wali_santri_list';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveAdminToken(String token, Map<String, dynamic> userData) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  Future<String?> getAdminToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<Map<String, dynamic>?> getAdminUserData() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWaliSession({
    required String token,
    required Map<String, dynamic> wali,
    required List<Map<String, dynamic>> santriList,
  }) async {
    await _storage.write(key: _waliTokenKey, value: token);
    await _storage.write(key: _waliDataKey, value: jsonEncode(wali));
    await _storage.write(key: _waliSantriKey, value: jsonEncode(santriList));
  }

  Future<WaliSession?> loadWaliSession() async {
    try {
      final token = await _storage.read(key: _waliTokenKey);
      final wali = await _storage.read(key: _waliDataKey);
      final santri = await _storage.read(key: _waliSantriKey);
      if (token == null || wali == null || santri == null) return null;

      // Decode JWT untuk verifikasi expired.
      // Catatan: signature verification dilakukan di server (Serverpod).
      final payload = _decodeJwtPayload(token);
      if (payload == null) return null;
      if (payload['exp'] != null) {
        final exp = (payload['exp'] as num).toInt();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now >= exp) return null; // token expired
      }

      return WaliSession(
        token: token,
        wali: jsonDecode(wali) as Map<String, dynamic>,
        santriList: (jsonDecode(santri) as List).cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get raw wali token dari storage (TANPA JWT verify).
  /// Dipakai untuk Phase 5 mobile_wali yang login pakai pseudo-token
  /// (bukan JWT proper). Production: ganti dengan JWT yang di-verify.
  Future<String?> getWaliToken() async {
    return _storage.read(key: _waliTokenKey);
  }

  /// Get raw wali data (Map) dari storage.
  Future<Map<String, dynamic>?> getWaliData() async {
    final raw = await _storage.read(key: _waliDataKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get raw santri list (List of Map) dari storage.
  Future<List<Map<String, dynamic>>?> getWaliSantriList() async {
    final raw = await _storage.read(key: _waliSantriKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

/// Decode JWT payload tanpa WebCrypto.
/// Sama dengan logic yang dipakai di proyek RN lama (jwt-hermes.ts).
/// Catatan: di Flutter Dart, base64Decode sudah native, jadi tidak perlu fallback.
Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    var payloadB64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    final pad = payloadB64.length % 4;
    if (pad != 0) {
      payloadB64 += '=' * (4 - pad);
    }

    // Pakai dart:convert base64Decode (native, tidak butuh WebCrypto)
    final jsonStr = utf8.decode(base64.decode(payloadB64));
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Provider untuk dapatkan auth token aktif (admin atau wali).
/// Di-override per app (admin desktop vs wali mobile).
final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.read(authStorageProvider);
  // Default: cek admin token dulu (admin/guru/bendahara/kepala)
  final adminToken = await storage.getAdminToken();
  if (adminToken != null) return adminToken;
  // Fallback: cek wali session
  final waliSession = await storage.loadWaliSession();
  return waliSession?.token;
});

/// Data session wali (untuk mobile_wali).
class WaliSession {
  const WaliSession({
    required this.token,
    required this.wali,
    required this.santriList,
  });
  final String token;
  final Map<String, dynamic> wali;
  final List<Map<String, dynamic>> santriList;
}

/// Provider current user (admin or wali).
/// Di-override per app untuk return type yang berbeda.
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final storage = ref.read(authStorageProvider);
  // Cek admin (Supabase)
  final adminToken = await storage.getAdminToken();
  if (adminToken != null) {
    final userData = await storage.getAdminUserData();
    if (userData != null) {
      return AuthUser.admin(userData);
    }
  }
  // Cek wali
  final waliSession = await storage.loadWaliSession();
  if (waliSession != null) {
    return AuthUser.wali(waliSession.wali, waliSession.santriList);
  }
  return null;
});

/// Tipe user yang login — digunakan untuk routing yang berbeda.
sealed class AuthUser {
  const AuthUser();

  factory AuthUser.admin(Map<String, dynamic> data) = AdminUser;
  factory AuthUser.wali(
    Map<String, dynamic> wali,
    List<Map<String, dynamic>> santriList,
  ) = WaliUser;
}

class AdminUser extends AuthUser {
  const AdminUser(this.data);
  final Map<String, dynamic> data;
}

class WaliUser extends AuthUser {
  const WaliUser(this.wali, this.santriList);
  final Map<String, dynamic> wali;
  final List<Map<String, dynamic>> santriList;
}
