// ============================================================================
// SIM MADIN — Mutation Providers (Phase 6 — admin_desktop)
// ============================================================================
// Mutations untuk admin:
//   - createUser, updateUser, deleteUser (soft), restoreUser
//   - assignRoleToUser, removeRoleFromUser
//   - createRole, updateRole, deleteRole
//   - createPermission (kalau belum ada)
//   - grantPermissionToRole, revokePermissionFromRole
//   - upsertSystemSetting, deleteSystemSetting
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'providers_admin_masterdata.dart';
import 'query_providers.dart';
import 'query_providers_admin.dart';
import 'supabase_write.dart';

// ---------------------------------------------------------------------------
// User CRUD
// ---------------------------------------------------------------------------

/// Create user (admin creates new user via Supabase Auth admin API +
/// insert ke tabel User). Catatan: butuh service_role key untuk
/// create user di Supabase Auth. Phase 6a dev: insert langsung ke
/// tabel User + link ke existing Supabase Auth user.
Future<UserModel> createUser(
  WidgetRef ref, {
  required String email,
  required String username,
  required String name,
  String? phone,
  String? firebaseUid, // Supabase Auth user ID (kalau sudah ada di auth.users)
  bool isActive = true,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = {
    'email': email,
    'username': username,
    'name': name,
    // passwordHash sengaja tidak diisi: kredensial dikelola Supabase Auth.
    // Migration 19 membuat kolom ini nullable (sebelumnya NOT NULL ->
    // pembuatan user selalu gagal).
    if (phone != null) 'phone': phone,
    if (firebaseUid != null) 'firebaseUid': firebaseUid,
    'isActive': isActive,
  };
  final res =
      await client.from('User').insert(rowFor('User', body)).select().single();
  ref.invalidate(userListProvider);
  ref.invalidate(userCountProvider);
  return UserModel.fromJson(res);
}

/// Update user (admin edit).
Future<UserModel> updateUser(
  WidgetRef ref, {
  required String userId,
  String? email,
  String? username,
  String? name,
  String? phone,
  String? avatarUrl,
  bool? isActive,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (email != null) 'email': email,
    if (username != null) 'username': username,
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (isActive != null) 'isActive': isActive,
  };
  final res = await client
      .from('User')
      .update(body)
      .eq('id', userId)
      .select()
      .single();
  ref.invalidate(userListProvider);
  ref.invalidate(userByIdProvider(userId));
  return UserModel.fromJson(res);
}

/// Soft delete user (set deletedAt).
Future<void> softDeleteUser(WidgetRef ref, String userId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('User').update({
    'deletedAt': DateTime.now().toIso8601String(),
    'isActive': false,
  }).eq('id', userId);
  ref.invalidate(userListProvider);
  ref.invalidate(userCountProvider);
}

/// Restore soft-deleted user.
Future<void> restoreUser(WidgetRef ref, String userId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('User').update({
    'deletedAt': null,
    'isActive': true,
  }).eq('id', userId);
  ref.invalidate(userListProvider);
}

// ---------------------------------------------------------------------------
// Role assignment
// ---------------------------------------------------------------------------

/// Assign role to user (create UserRole record).
Future<void> assignRoleToUser(
  WidgetRef ref, {
  required String userId,
  required String roleId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('UserRole').insert(rowFor('UserRole', {
    'userId': userId,
    'roleId': roleId,
    'isActive': true,
  }));
  ref.invalidate(userListProvider);
  ref.invalidate(userByIdProvider(userId));
}

/// Remove role from user (delete UserRole record or set isActive=false).
Future<void> removeRoleFromUser(
  WidgetRef ref, {
  required String userId,
  required String roleId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client
      .from('UserRole')
      .delete()
      .eq('userId', userId)
      .eq('roleId', roleId);
  ref.invalidate(userListProvider);
  ref.invalidate(userByIdProvider(userId));
}

// ---------------------------------------------------------------------------
// Role CRUD
// ---------------------------------------------------------------------------

Future<RoleModel> createRole(
  WidgetRef ref, {
  required String code,
  required String name,
  String? description,
  int sortOrder = 99,
}) async {
  final client = ref.read(supabaseClientProvider);
  final res = await client.from('Role').insert(rowFor('Role', {
    'code': code,
    'name': name,
    if (description != null) 'description': description,
    'sortOrder': sortOrder,
  })).select().single();
  ref.invalidate(roleListProvider);
  return RoleModel.fromJson(res);
}

Future<RoleModel> updateRole(
  WidgetRef ref, {
  required String roleId,
  String? name,
  String? description,
  int? sortOrder,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (sortOrder != null) 'sortOrder': sortOrder,
  };
  final res = await client
      .from('Role')
      .update(body)
      .eq('id', roleId)
      .select()
      .single();
  ref.invalidate(roleListProvider);
  ref.invalidate(roleByIdProvider(roleId));
  return RoleModel.fromJson(res);
}

Future<void> deleteRole(WidgetRef ref, String roleId) async {
  final client = ref.read(supabaseClientProvider);
  // Catatan: kalau role masih dipakai oleh user, FK constraint akan block.
  // Best practice: reassign users ke role lain dulu sebelum delete.
  await client.from('Role').delete().eq('id', roleId);
  ref.invalidate(roleListProvider);
  ref.invalidate(allRolePermissionsProvider);
}

// ---------------------------------------------------------------------------
// Permission management
// ---------------------------------------------------------------------------

/// Grant permission to role (create RolePermission record).
Future<void> grantPermissionToRole(
  WidgetRef ref, {
  required String roleId,
  required String permissionId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('RolePermission').insert(rowFor('RolePermission', {
    'roleId': roleId,
    'permissionId': permissionId,
  }));
  ref.invalidate(rolePermissionsMatrixProvider(roleId));
  ref.invalidate(allRolePermissionsProvider);
  ref.invalidate(roleByIdProvider(roleId));
}

/// Revoke permission from role.
Future<void> revokePermissionFromRole(
  WidgetRef ref, {
  required String roleId,
  required String permissionId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client
      .from('RolePermission')
      .delete()
      .eq('roleId', roleId)
      .eq('permissionId', permissionId);
  ref.invalidate(rolePermissionsMatrixProvider(roleId));
  ref.invalidate(allRolePermissionsProvider);
  ref.invalidate(roleByIdProvider(roleId));
}

/// Bulk grant/revoke permissions for a role (untuk matrix editor).
/// `permissions` is a Map<permissionId, granted> — true=grant, false=revoke.
Future<void> bulkUpdateRolePermissions(
  WidgetRef ref, {
  required String roleId,
  required Map<String, bool> permissions,
}) async {
  final client = ref.read(supabaseClientProvider);
  // Get current permissions
  final currentRes = await client
      .from('RolePermission')
      .select('permissionId')
      .eq('roleId', roleId);
  final currentIds = (currentRes as List)
      .map((r) => (r as Map<String, dynamic>)['permissionId'] as String)
      .toSet();

  // Compute diff
  final toAdd = <Map<String, dynamic>>[];
  final toRemove = <String>[];
  for (final entry in permissions.entries) {
    final permId = entry.key;
    final granted = entry.value;
    if (granted && !currentIds.contains(permId)) {
      toAdd.add({'roleId': roleId, 'permissionId': permId});
    } else if (!granted && currentIds.contains(permId)) {
      toRemove.add(permId);
    }
  }

  // Execute
  if (toAdd.isNotEmpty) {
    await client.from('RolePermission').insert(
      toAdd.map((row) => insertRow(row)).toList(),
    );
  }
  for (final permId in toRemove) {
    await client
        .from('RolePermission')
        .delete()
        .eq('roleId', roleId)
        .eq('permissionId', permId);
  }

  ref.invalidate(rolePermissionsMatrixProvider(roleId));
  ref.invalidate(allRolePermissionsProvider);
  ref.invalidate(roleByIdProvider(roleId));
}

// ---------------------------------------------------------------------------
// System Setting CRUD
// ---------------------------------------------------------------------------

Future<SystemSettingModel> upsertSystemSetting(
  WidgetRef ref, {
  required String key,
  required String value,
  String? description,
  String type = 'STRING',
  bool isPublic = false,
}) async {
  final client = ref.read(supabaseClientProvider);
  // Try update first, then insert kalau tidak ada.
  final existing = await client
      .from('SystemSetting')
      .select('id')
      .eq('key', key)
      .maybeSingle();

  if (existing != null) {
    final res = await client.from('SystemSetting').update({
      'value': value,
      if (description != null) 'description': description,
      'type': type,
      'isPublic': isPublic,
    }).eq('key', key).select().single();
    ref.invalidate(systemSettingsProvider);
    ref.invalidate(systemSettingByKeyProvider(key));
    return SystemSettingModel.fromJson(res);
  } else {
    final res = await client.from('SystemSetting').insert(rowFor('SystemSetting', {
      'key': key,
      'value': value,
      'description': description,
      'type': type,
      'isPublic': isPublic,
    })).select().single();
    ref.invalidate(systemSettingsProvider);
    ref.invalidate(systemSettingByKeyProvider(key));
    return SystemSettingModel.fromJson(res);
  }
}

Future<void> deleteSystemSetting(WidgetRef ref, String key) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('SystemSetting').delete().eq('key', key);
  ref.invalidate(systemSettingsProvider);
  ref.invalidate(systemSettingByKeyProvider(key));
}

// ---------------------------------------------------------------------------
// Manajemen akun staf (tambah / hapus) — lewat RPC SECURITY DEFINER
// ---------------------------------------------------------------------------
// Kenapa RPC, bukan insert biasa:
//   * membuat akun login butuh menulis ke schema auth.users (service_role)
//   * menghapus akun harus ikut menghapus auth.users, kalau tidak akun yang
//     sudah "dihapus" masih bisa login ke aplikasi mobile
// Klien hanya boleh memanggil RPC; keduanya menolak selain admin.

/// Buat akun staf (email + password) sekaligus peran & profil guru.
///
/// [roles] berisi kode peran, mis. `['KEPALA']`, `['BENDAHARA']`, `['GURU']`.
Future<AdminAccountResult> adminCreateStaffAccount(
  WidgetRef ref, {
  required String email,
  required String password,
  required String name,
  required List<String> roles,
  String? phone,
  String? username,
  String? guruNip,
  String? specialization,
}) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('admin_create_staff_account', params: {
    'p_email': email.trim(),
    'p_password': password,
    'p_name': name.trim(),
    'p_roles': roles,
    'p_phone': phone?.trim(),
    'p_username': username?.trim(),
    'p_guru_nip': guruNip?.trim(),
    'p_specialization': specialization?.trim(),
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  final result = AdminAccountResult(
    success: map['success'] == true,
    message: (map['message'] as String?) ?? 'Tanpa pesan dari server',
  );

  if (!result.success) {
    throw Exception(result.message);
  }

  _invalidateUserCaches(ref);
  return result;
}

/// Hapus akun: kredensial login dihapus sehingga akun TIDAK BISA lagi masuk.
///
/// Data historis (absensi, nilai, pembayaran) dipertahankan; baris `User`
/// hanya dihapus permanen bila [hardDelete] dan tidak punya jejak historis.
Future<AdminAccountResult> adminDeleteAccount(
  WidgetRef ref, {
  required String email,
  bool hardDelete = false,
}) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('admin_delete_account', params: {
    'p_email': email.trim(),
    'p_hard_delete': hardDelete,
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  final result = AdminAccountResult(
    success: map['success'] == true,
    message: (map['message'] as String?) ?? 'Tanpa pesan dari server',
  );

  if (!result.success) {
    throw Exception(result.message);
  }

  _invalidateUserCaches(ref);
  return result;
}

/// Aktifkan kembali akun yang terlanjur dihapus/dinonaktifkan.
Future<AdminAccountResult> adminRestoreAccount(
  WidgetRef ref, {
  required String email,
}) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client.rpc<dynamic>('admin_restore_account', params: {
    'p_email': email.trim(),
  });

  final map = (res as Map?)?.cast<String, dynamic>() ?? const {};
  final result = AdminAccountResult(
    success: map['success'] == true,
    message: (map['message'] as String?) ?? 'Tanpa pesan dari server',
  );

  if (!result.success) {
    throw Exception(result.message);
  }

  _invalidateUserCaches(ref);
  return result;
}

void _invalidateUserCaches(WidgetRef ref) {
  ref.invalidate(userListProvider);
  ref.invalidate(userCountProvider);
  ref.invalidate(guruListProvider);
  ref.invalidate(guruListAdminProvider);
  ref.invalidate(waliListAdminProvider);
}

/// Hasil operasi manajemen akun.
class AdminAccountResult {
  const AdminAccountResult({required this.success, required this.message});

  final bool success;
  final String message;
}
