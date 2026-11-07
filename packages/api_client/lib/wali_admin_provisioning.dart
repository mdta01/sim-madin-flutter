// ============================================================================
// SIM MADIN — Provisioning & diagnostik akun wali (admin)
// ============================================================================
// Login wali (WA + PIN) berhasil di RPC `wali_login`, lalu aplikasi
// menandatangani sesi Supabase Auth memakai email + `Wali.authPassword`.
// Sesi itulah yang membuat RLS bekerja, karena semua policy wali bergantung
// pada rantai:
//
//   auth.uid() -> User.firebaseUid -> User.id
//                 -> UserRole(WALI, isActive)
//                 -> Wali.userId -> SantriWali -> Santri
//
// Kalau salah satu mata rantai putus, wali tetap bisa login TAPI melihat
// dashboard kosong tanpa pesan error (RLS menyaring semua baris).
//
// Dua helper di bawah memanggil RPC dari migration 23 supaya admin bisa
// memperbaiki dan memeriksa kondisi tersebut dari UI.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_client/supabase_client.dart';

/// Satu baris hasil diagnostik keterhubungan akun wali.
class WaliLinkCheck {
  const WaliLinkCheck({
    required this.checkName,
    required this.ok,
    required this.detail,
  });

  final String checkName;
  final bool ok;
  final String detail;

  factory WaliLinkCheck.fromRow(Map<String, dynamic> row) => WaliLinkCheck(
        checkName: (row['check_name'] as String?) ?? '-',
        ok: (row['ok'] as bool?) ?? false,
        detail: (row['detail'] as String?) ?? '-',
      );
}

/// Provision akun Supabase Auth untuk wali tertentu (link User + role WALI).
///
/// Idempotent: aman dipanggil berulang. Mengembalikan pesan untuk ditampilkan
/// ke admin.
Future<String> provisionWaliAuth(WidgetRef ref, String waliId) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.rpc<dynamic>(
    'provision_wali_auth',
    params: {'p_wali_id': waliId},
  );
  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  if (map['success'] != true) {
    throw Exception(map['message'] ?? 'Provisioning gagal');
  }
  return (map['message'] as String?) ?? 'Berhasil';
}

/// Jalankan diagnostik rantai akses wali.
///
/// Mengembalikan daftar pemeriksaan; entri dengan `ok == false` adalah
/// penyebab layar kosong pada akun wali tersebut.
Future<List<WaliLinkCheck>> checkWaliLink(
  WidgetRef ref,
  String waliId,
) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.rpc<dynamic>(
    'check_wali_link',
    params: {'p_wali_id': waliId},
  );
  final list = (res as List?) ?? const [];
  return list
      .map((r) => WaliLinkCheck.fromRow((r as Map).cast<String, dynamic>()))
      .toList();
}
