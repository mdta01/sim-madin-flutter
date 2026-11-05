// ============================================================================
// SIM MADIN — Query Providers (Phase 6 — admin_desktop)
// ============================================================================
// Riverpod providers untuk query data admin:
//   - userListProvider (search + pagination)
//   - userByIdProvider.family<String>
//   - roleListProvider
//   - permissionListProvider (60 codes)
//   - systemSettingsProvider (key-value pairs)
//   - adminDashboardStatsProvider (KPI: total santri/guru/kelas/payment)
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'query_providers.dart' show realtimeRefreshTick;

// ---------------------------------------------------------------------------
// User list (admin only — paginated, with search)
// ---------------------------------------------------------------------------

final userListProvider =
    FutureProvider.family<List<UserModel>, UserListParams>((ref, params) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  // Apply filter BEFORE order+range (Supabase SDK constraint — filter
  // methods are on FilterBuilder, transform methods on TransformBuilder).
  var q = client.from('User').select();
  if (params.search != null && params.search!.isNotEmpty) {
    q = q.or(
        'email.ilike.%${params.search}%,name.ilike.%${params.search}%,username.ilike.%${params.search}%');
  }
  if (params.isActiveOnly) {
    q = q.eq('isActive', true);
  }
  final res = await q
      .order('createdAt', ascending: false)
      .range(params.offset, params.offset + params.limit - 1);
  return (res as List)
      .map((r) => _userFromRow(r as Map<String, dynamic>))
      .toList();
});

class UserListParams {
  const UserListParams({
    this.search,
    this.limit = 50,
    this.offset = 0,
    this.isActiveOnly = false,
  });
  final String? search;
  final int limit;
  final int offset;
  final bool isActiveOnly;
}

UserModel _userFromRow(Map<String, dynamic> row) {
  return UserModel.fromJson(row);
}

final userByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('User')
      .select('*, UserRole(*, Role(*))')
      .eq('id', id)
      .maybeSingle();
  if (res == null) return null;
  return _userFromRow(res);
});

/// Count total users (untuk pagination info).
/// Catatan: supabase_flutter v2.8 tidak expose FetchOptions/CountOption
/// dengan cara yang sama dengan v2.x terbaru. Pakai select-all + count
/// manual untuk simplicity. Untuk dataset besar, ganti dengan RPC count.
final userCountProvider = FutureProvider.family<int, String?>((ref, search) async {
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('User').select('id');
  if (search != null && search.isNotEmpty) {
    q = q.or(
        'email.ilike.%$search%,name.ilike.%$search%,username.ilike.%$search%');
  }
  final res = await q;
  return (res as List).length;
});

// ---------------------------------------------------------------------------
// Role list (all roles)
// ---------------------------------------------------------------------------

final roleListProvider = FutureProvider<List<RoleModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Role').select().order('sortOrder');
  return (res as List)
      .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

final roleByIdProvider =
    FutureProvider.family<RoleModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Role')
      .select('*, RolePermission(*, Permission(*))')
      .eq('id', id)
      .maybeSingle();
  if (res == null) return null;
  return RoleModel.fromJson(res);
});

// ---------------------------------------------------------------------------
// Permission list (all permissions — 60 codes from constants.dart)
// ---------------------------------------------------------------------------

final permissionListProvider = FutureProvider<List<PermissionModel>>(
    (ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('Permission').select().order('code');
  return (res as List)
      .map((r) => PermissionModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Permissions grouped by module (untuk matrix editor display).
/// Returns Map<module, List<PermissionModel>>.
final permissionsByModuleProvider =
    FutureProvider<Map<String, List<PermissionModel>>>((ref) async {
  final list = await ref.watch(permissionListProvider.future);
  final grouped = <String, List<PermissionModel>>{};
  for (final p in list) {
    final module = p.code.split(':')[0];
    grouped.putIfAbsent(module, () => []).add(p);
  }
  return grouped;
});

/// Role permissions matrix — Map<roleId, Set<permissionCode>>.
/// Dipakai di Roles screen untuk toggle permissions per role.
final rolePermissionsMatrixProvider =
    FutureProvider.family<Map<String, Set<String>>, String>((ref, roleId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('RolePermission')
      .select('permissionId, Permission(code)')
      .eq('roleId', roleId);
  final matrix = <String, Set<String>>{};
  for (final r in res as List) {
    final perm = r['Permission'] as Map<String, dynamic>?;
    if (perm != null) {
      final code = perm['code'] as String;
      matrix.putIfAbsent(roleId, () => {}).add(code);
    }
  }
  return matrix;
});

/// All role permissions (for matrix view across all roles).
final allRolePermissionsProvider =
    FutureProvider<Map<String, Set<String>>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('RolePermission')
      .select('roleId, Permission(code)');
  final matrix = <String, Set<String>>{};
  for (final r in res as List) {
    final roleId = r['roleId'] as String;
    final perm = r['Permission'] as Map<String, dynamic>?;
    if (perm != null) {
      final code = perm['code'] as String;
      matrix.putIfAbsent(roleId, () => {}).add(code);
    }
  }
  return matrix;
});

// ---------------------------------------------------------------------------
// System Settings (key-value pairs)
// ---------------------------------------------------------------------------

final systemSettingsProvider =
    FutureProvider<List<SystemSettingModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('SystemSetting').select().order('key');
  return (res as List)
      .map((r) => SystemSettingModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

final systemSettingByKeyProvider =
    FutureProvider.family<SystemSettingModel?, String>((ref, key) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('SystemSetting')
      .select()
      .eq('key', key)
      .maybeSingle();
  if (res == null) return null;
  return SystemSettingModel.fromJson(res);
});

// ---------------------------------------------------------------------------
// Admin Dashboard Stats (KPI cards)
// ---------------------------------------------------------------------------

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>(
    (ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);

  // Count queries (select all + count manual — FetchOptions tidak
  // tersedia di supabase_flutter v2.8 dengan API yang sama).
  final santriRes = await client
      .from('Santri')
      .select('id')
      .filter('deletedAt', 'is', null)
      .eq('status', SantriStatus.aktif);
  final guruRes = await client
      .from('Guru')
      .select('id')
      .filter('deletedAt', 'is', null)
      .eq('status', GuruStatus.aktif);
  final kelasRes = await client
      .from('Kelas')
      .select('id')
      .filter('deletedAt', 'is', null);
  final paymentRes = await client
      .from('Payment')
      .select('id')
      .eq('status', PaymentStatus.verified);
  final tagihanRes = await client
      .from('Tagihan')
      .select('amount, paidAmount')
      .neq('status', TagihanStatus.lunas);

  // Compute total verified payments this month
  final now = DateTime.now();
  final paymentsThisMonth = await client
      .from('Payment')
      .select('amount')
      .eq('status', PaymentStatus.verified)
      .gte('paymentDate',
          DateTime(now.year, now.month, 1).toIso8601String())
      .lt('paymentDate',
          DateTime(now.year, now.month + 1, 1).toIso8601String());
  final totalIncomeThisMonth = (paymentsThisMonth as List)
      .fold<double>(0, (s, p) => s + ((p['amount'] as num?) ?? 0).toDouble());

  // Compute total outstanding (tagihan belum lunas)
  final outstanding = (tagihanRes as List).fold<double>(0, (s, t) {
    final amount = ((t['amount'] as num?) ?? 0).toDouble();
    final paid = ((t['paidAmount'] as num?) ?? 0).toDouble();
    return s + (amount - paid).clamp(0.0, double.infinity);
  });

  return AdminDashboardStats(
    totalSantri: (santriRes as List).length,
    totalGuru: (guruRes as List).length,
    totalKelas: (kelasRes as List).length,
    totalPayments: (paymentRes as List).length,
    totalIncomeThisMonth: totalIncomeThisMonth,
    totalOutstanding: outstanding,
  );
});

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalSantri,
    required this.totalGuru,
    required this.totalKelas,
    required this.totalPayments,
    required this.totalIncomeThisMonth,
    required this.totalOutstanding,
  });

  final int totalSantri;
  final int totalGuru;
  final int totalKelas;
  final int totalPayments;
  final double totalIncomeThisMonth;
  final double totalOutstanding;
}

// ---------------------------------------------------------------------------
// Permission model (port dari Prisma)
// ---------------------------------------------------------------------------

class PermissionModel {
  const PermissionModel({
    required this.id,
    required this.code, // e.g. "santri:view"
    required this.name,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final DateTime createdAt;

  factory PermissionModel.fromJson(Map<String, dynamic> j) => PermissionModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// SystemSetting model (port dari Prisma)
// ---------------------------------------------------------------------------

class SystemSettingModel {
  const SystemSettingModel({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    this.type = 'STRING', // STRING | NUMBER | BOOLEAN | JSON
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String key;
  final String value;
  final String? description;
  final String type;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SystemSettingModel.fromJson(Map<String, dynamic> j) =>
      SystemSettingModel(
        id: j['id'] as String,
        key: j['key'] as String,
        value: j['value'] as String,
        description: j['description'] as String?,
        type: (j['type'] as String?) ?? 'STRING',
        isPublic: (j['isPublic'] as bool?) ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Helper: invalidate all admin providers
// ---------------------------------------------------------------------------

void invalidateAdminQueries(WidgetRef ref) {
  ref.invalidate(userListProvider);
  ref.invalidate(roleListProvider);
  ref.invalidate(permissionListProvider);
  ref.invalidate(permissionsByModuleProvider);
  ref.invalidate(allRolePermissionsProvider);
  ref.invalidate(systemSettingsProvider);
  ref.invalidate(adminDashboardStatsProvider);
}
