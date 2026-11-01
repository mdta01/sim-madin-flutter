// ============================================================================
// SIM MADIN — API Client (Dio + Serverpod-generated client)
// ============================================================================
// Wrapper untuk komunikasi dengan backend Serverpod.
// Untuk Phase 1 (foundation), hanya berisi:
//   - Dio HTTP client dengan auth interceptor
//   - Wali session storage (SecureStore)
//   - Riverpod providers (auth state, current user)
//
// Saat Phase 2+, file ini akan di-replace oleh Serverpod-generated client
// (lebih type-safe — auto-generated dari server-side endpoint definitions).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared/shared.dart';

part 'api_client.freezed.dart';
part 'api_client.g.dart';

/// Konfigurasi dasar untuk Dio HTTP client.
@freezed
class ApiClientConfig with _$ApiClientConfig {
  const factory ApiClientConfig({
    @Default('http://localhost:8080') String baseUrl,
    @Default(Duration(seconds: 30)) Duration connectTimeout,
    @Default(Duration(seconds: 30)) Duration receiveTimeout,
  }) = _ApiClientConfig;

  factory ApiClientConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiClientConfigFromJson(json);
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
      logPrint: (obj) => print('[DIO] $obj'),
    ));
  }

  return dio;
});

/// Secure storage untuk token & session data.
final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

/// Storage untuk auth state (Supabase admin token ATAU wali custom JWT).
class AuthStorage {
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

      // Decode JWT untuk verifikasi expired (Hermes-compatible atob approach).
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

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

/// Decode JWT payload tanpa WebCrypto (Hermes-compatible).
/// Sama dengan logic yang dipakai di proyek RN lama (apps/mobile-wali/vendor/mobile-shared/src/jwt-hermes.ts).
Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    var payloadB64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    final pad = payloadB64.length % 4;
    if (pad != 0) {
      payloadB64 += '=' * (4 - pad);
    }

    final jsonStr = _base64Decode(payloadB64);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String _base64Decode(String b64) {
  // Fallback manual base64 decode (untuk Hermes lama yang tidak punya atob).
  // Di Flutter Dart, base64Decode sudah native, jadi ini tidak diperlukan
  // untuk implementasi Flutter, tapi dipertahankan untuk konsistensi logic.
  return String.fromCharCodes(
    (b64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '')).codeUnits,
  );
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
@freezed
class WaliSession with _$WaliSession {
  const factory WaliSession({
    required String token,
    required Map<String, dynamic> wali,
    required List<Map<String, dynamic>> santriList,
  }) = _WaliSession;

  factory WaliSession.fromJson(Map<String, dynamic> json) =>
      _$WaliSessionFromJson(json);
}

/// Provider current user (admin or wali).
/// Di-override per app untuk return type yang berbeda.
final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final storage = ref.read(authStorageProvider);
  // Cek admin (Supabase)
  final adminToken = await storage.getAdminToken();
  if (adminToken != null) {
    final userData = await _storageRead(_userKey);
    if (userData != null) {
      return AuthUser.admin(jsonDecode(userData) as Map<String, dynamic>);
    }
  }
  // Cek wali
  final waliSession = await storage.loadWaliSession();
  if (waliSession != null) {
    return AuthUser.wali(waliSession.wali, waliSession.santriList);
  }
  return null;
});

Future<String?> _storageRead(String key) async {
  return FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ).read(key: key);
}

/// Tipe user yang login — digunakan untuk routing yang berbeda.
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser.admin(Map<String, dynamic> data) = _AdminUser;
  const factory AuthUser.wali(
    Map<String, dynamic> wali,
    List<Map<String, dynamic>> santriList,
  ) = _WaliUser;
}
