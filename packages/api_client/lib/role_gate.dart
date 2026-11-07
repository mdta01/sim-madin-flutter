// ============================================================================
// SIM MADIN — Gerbang peran (role gate)
// ============================================================================
// Aplikasi admin desktop hanya boleh dipakai staf madrasah. Sebelumnya cukup
// punya akun Supabase Auth yang valid untuk masuk — termasuk akun wali dan
// guru — karena RLS memang menyaring DATA, tetapi UI administratif (34 modul)
// tetap terbuka.
//
// Pemeriksaan ini dipakai di DUA tempat:
//   1. login_screen.dart  — setelah signInWithPassword berhasil
//   2. splash_screen.dart — saat sesi lama dipulihkan dari penyimpanan
//
// Kalau hanya di login, sesi yang sudah tersimpan sebelumnya (mis. wali yang
// pernah login di komputer yang sama) akan langsung masuk ke /dashboard tanpa
// pernah diperiksa.
//
// Prinsip: GAGAL MEMERIKSA = TOLAK. Kegagalan jaringan tidak boleh menjadi
// celah untuk masuk.
// ============================================================================

import 'package:supabase_client/supabase_client.dart';

/// Hasil pemeriksaan hak akses sebuah akun.
class AccountAccess {
  const AccountAccess({
    required this.allowed,
    this.message,
    this.roleCodes = const {},
  });

  /// True bila akun boleh memakai aplikasi.
  final bool allowed;

  /// Alasan penolakan (null bila diizinkan).
  final String? message;

  /// Kode peran yang dimiliki akun (aktif saja).
  final Set<String> roleCodes;

  const AccountAccess.denied(String this.message, {this.roleCodes = const {}})
      : allowed = false;
}

/// Peran yang boleh memakai aplikasi admin desktop.
const kAdminDesktopRoles = {'SUPER_ADMIN', 'ADMIN', 'KEPALA', 'BENDAHARA'};

/// Perannya guru (dipakai untuk memastikan aplikasi yang tepat).
const kGuruRoles = {'GURU', 'KEPALA', 'SUPER_ADMIN', 'ADMIN'};

/// Periksa apakah akun yang sedang login adalah staf madrasah.
///
/// Mengembalikan [AccountAccess] dengan `allowed == false` dan [message] yang
/// siap ditampilkan bila akun tidak berhak.
Future<AccountAccess> resolveAccountAccess(
  SupabaseClient client, {
  Set<String> requiredRoles = kAdminDesktopRoles,
}) async {
  final authUser = client.auth.currentUser;
  if (authUser == null) {
    return const AccountAccess.denied('Sesi tidak valid, silakan login ulang.');
  }

  final List<dynamic> rows;
  try {
    final res = await client
        .from('User')
        .select('id, isActive, UserRole(isActive, Role(code, name))')
        .eq('firebaseUid', authUser.id);
    rows = (res as List).cast<dynamic>();
  } catch (e) {
    return AccountAccess.denied('Gagal memverifikasi hak akses akun: $e');
  }

  if (rows.isEmpty) {
    return const AccountAccess.denied(
      'Akun ini belum terhubung ke data staf madrasah. Hubungi Super Admin.',
    );
  }

  final user = rows.first as Map<String, dynamic>;

  if (user['isActive'] == false) {
    return const AccountAccess.denied(
      'Akun Anda dinonaktifkan. Hubungi Super Admin.',
    );
  }

  final codeToName = <String, String>{};
  for (final raw in (user['UserRole'] as List?) ?? const []) {
    final ur = raw as Map<String, dynamic>;
    if (ur['isActive'] == false) continue;
    final role = ur['Role'] as Map<String, dynamic>?;
    final code = role?['code'] as String?;
    if (code != null) {
      codeToName[code] = (role?['name'] as String?) ?? code;
    }
  }

  final codes = codeToName.keys.toSet();
  if (codes.intersection(requiredRoles).isEmpty) {
    final label = codes.isEmpty
        ? 'belum punya peran'
        : codes.map((c) => codeToName[c] ?? c).join(', ');
    return AccountAccess.denied(
      'Aplikasi ini khusus staf madrasah. Akun Anda: $label.',
      roleCodes: codes,
    );
  }

  return AccountAccess(allowed: true, roleCodes: codes);
}
