// ============================================================================
// SIM MADIN — API Client (Supabase client + auth)
// ============================================================================
// Wrapper untuk komunikasi dengan backend Serverpod.
// Untuk Phase 1 (foundation), hanya berisi:
//   - Supabase client dengan auth interceptor
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
export 'providers_admin_keuangan.dart';
export 'chat_pagination.dart';
export 'supabase_rpc.dart';
export 'notification_service.dart';
export 'storage_service.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

/// Provider konfigurasi API client.
/// Override di main.dart untuk setiap app (admin desktop vs mobile).
/// (Removed — Dio was unused, Supabase client handles all HTTP.)
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

/// Verifikasi bahwa user yang sedang login (via Supabase Auth) memiliki
/// role tertentu (BENDAHARA / GURU / KEPALA / ADMIN / SUPER_ADMIN).
///
/// Memakai RPC `has_role(role_code)` yang sudah didefinisikan di migration
/// `00_rls_helper_functions.sql`. Fungsi itu join `UserRole` → `Role`
/// where `userId = current_user_id()` (yang join `User.firebaseUid = auth.uid()`).
///
/// Return true kalau user punya role tersebut dan UserRole.isActive = true.
/// Throw Exception kalau user belum login atau RPC gagal.
Future<bool> verifyUserRole(
  WidgetRef ref, {
  required String roleCode,
}) async {
  final client = ref.read(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) {
    throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
  }
  try {
    final res = await client.rpc('has_role', params: {'role_code': roleCode});
    return res == true;
  } catch (e) {
    // Fallback: kalau RPC gagal (mis. function belum di-migrate),
    // query manual UserRole → Role.
    try {
      final userRes = await client
          .from('User')
          .select('id')
          .eq('firebaseUid', user.id)
          .maybeSingle();
      if (userRes == null) return false;
      final userId = userRes['id'] as String;
      final urRes = await client
          .from('UserRole')
          .select('*, Role(*)')
          .eq('userId', userId)
          .eq('isActive', true);
      for (final ur in urRes as List) {
        final role = (ur as Map<String, dynamic>)['Role']
            as Map<String, dynamic>?;
        if (role?['code'] == roleCode) return true;
      }
      return false;
    } catch (_) {
      throw Exception('Gagal verifikasi role: $e');
    }
  }
}

/// Helper: setelah login Supabase Auth, verifikasi role user.
/// Kalau tidak match, signOut + throw Exception dengan pesan user-friendly.
/// Panggil di login screen setelah `signInWithPassword` sukses.
Future<void> ensureUserRoleOrSignOut(
  WidgetRef ref, {
  required String roleCode,
  required String roleLabel,
}) async {
  final client = ref.read(supabaseClientProvider);
  final hasRole = await verifyUserRole(ref, roleCode: roleCode);
  if (!hasRole) {
    await client.auth.signOut();
    throw Exception(
        'Akun ini tidak terdaftar sebagai $roleLabel. Hubungi admin madrasah.');
  }
}

/// Provider untuk dapatkan auth token aktif (admin atau wali).
/// Di-override per app (admin desktop vs wali mobile).
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
  // CRITICAL: Check Supabase Auth session FIRST (most reliable).
  // After signInWithPassword, session is stored by supabase_flutter automatically.
  final supaClient = ref.read(supabaseClientProvider);
  final session = supaClient.auth.currentSession;
  if (session != null) {
    final user = supaClient.auth.currentUser;
    if (user != null) {
      return AuthUser.admin({
        'id': user.id,
        'email': user.email ?? '',
        'name': user.userMetadata?['name'] ?? user.email ?? 'User',
      });
    }
  }

  // Fallback: check secure storage for admin token
  final storage = ref.read(authStorageProvider);
  final adminToken = await storage.getAdminToken();
  if (adminToken != null) {
    final userData = await storage.getAdminUserData();
    if (userData != null) {
      return AuthUser.admin(userData);
    }
  }

  // Check wali session (raw token, skip JWT verify for Phase 5 dev)
  final waliToken = await storage.getWaliToken();
  final waliData = await storage.getWaliData();
  final waliSantri = await storage.getWaliSantriList();
  if (waliToken != null && waliData != null && waliSantri != null) {
    return AuthUser.wali(waliData, waliSantri);
  }

  return null;
});

/// Provider untuk profil lengkap User dari tabel DB (bukan auth).
/// Query join User + UserRole + Role supaya dapat nama, role code, phone,
/// avatarUrl. Dipakai di profile_screen guru/bendahara/kepala supaya
/// tampilan profile tidak hanya email + hardcoded label.
final userProfileProvider =
    FutureProvider<UserProfileData?>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final authUser = client.auth.currentUser;
  if (authUser == null) return null;
  try {
    final res = await client
        .from('User')
        .select('*, UserRole(*, Role(*))')
        .eq('firebaseUid', authUser.id)
        .maybeSingle();
    if (res == null) return null;
    final row = res;
    final userRoles = (row['UserRole'] as List?) ?? [];
    final roleCodes = <String>[];
    final roleNames = <String>[];
    for (final ur in userRoles) {
      final urMap = ur as Map<String, dynamic>;
      final role = urMap['Role'] as Map<String, dynamic>?;
      if (urMap['isActive'] == true && role != null) {
        roleCodes.add(role['code'] as String);
        roleNames.add(role['name'] as String);
      }
    }
    return UserProfileData(
      id: row['id'] as String,
      email: row['email'] as String,
      username: row['username'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      avatarUrl: row['avatarUrl'] as String?,
      isActive: (row['isActive'] as bool?) ?? true,
      lastLoginAt: row['lastLoginAt'] is String
          ? DateTime.tryParse(row['lastLoginAt'] as String)
          : null,
      roleCodes: roleCodes,
      roleNames: roleNames,
    );
  } catch (_) {
    return null;
  }
});

/// Data profil user dari tabel DB (bukan auth).
class UserProfileData {
  const UserProfileData({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.lastLoginAt,
    this.roleCodes = const [],
    this.roleNames = const [],
  });

  final String id;
  final String email;
  final String username;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastLoginAt;
  final List<String> roleCodes;
  final List<String> roleNames;

  /// Inisial nama untuk avatar fallback.
  String get initials =>
      name.isEmpty ? '?' : name[0].toUpperCase();

  /// Label role utama (role pertama yang aktif).
  String get primaryRoleLabel =>
      roleNames.isNotEmpty ? roleNames.first : 'Pengguna';
}

/// Provider untuk profil Guru yang sedang login (join Guru + User).
/// Dipakai di mobile_guru profile_screen supaya bisa tampilkan nama lengkap,
/// NIP, specialization, joinDate, dst (bukan hanya email).
final currentGuruProfileProvider =
    FutureProvider<GuruModel?>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final authUser = client.auth.currentUser;
  if (authUser == null) return null;
  try {
    // CRITICAL: Guru.userId adalah FK ke User.id (cuid), BUKAN ke Supabase
    // Auth UID (authUser.id). Jadi kita tidak bisa langsung filter
    // `.eq('userId', authUser.id)`. Pakai nested filter PostgREST
    // `.eq('User.firebaseUid', authUser.id)` untuk join via User.firebaseUid.
    final res = await client
        .from('Guru')
        .select('*, User(*)')
        .eq('User.firebaseUid', authUser.id)
        .maybeSingle();
    if (res == null) return null;
    final row = res;
    final user = row['User'] as Map<String, dynamic>?;
    return GuruModel.fromJson({
      ...row,
      if (user != null) ...{
        'name': user['name'] ?? row['name'] ?? 'Guru',
        'email': user['email'] ?? row['email'],
        'phone': user['phone'] ?? row['phone'],
        'photoUrl': user['avatarUrl'] ?? row['photoUrl'],
      } else if (!row.containsKey('name')) ...{
        'name': 'Guru',
      },
    });
  } catch (_) {
    return null;
  }
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
