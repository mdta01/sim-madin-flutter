// User, Role — port dari Prisma `User`, `Role`
// Plain Dart (no freezed/codegen) — read-only Phase 2 tidak butuh copyWith.
// Dipakai untuk Auth context + audit display name Payment.recordedBy.

import 'package:shared/shared.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.firebaseUid, // Supabase Auth UID (kolom asli di DB: `firebaseUid`)
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String email;
  final String username;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? firebaseUid;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        email: j['email'] as String,
        username: j['username'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        firebaseUid: j['firebaseUid'] as String?,
        isActive: (j['isActive'] as bool?) ?? true,
        lastLoginAt: _parseDate(j['lastLoginAt']),
        createdAt: _parseDate(j['createdAt'])!,
        updatedAt: _parseDate(j['updatedAt'])!,
        deletedAt: _parseDate(j['deletedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'firebaseUid': firebaseUid,
        'isActive': isActive,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  /// Inisial untuk avatar fallback (memakai helper getInitials di utils.dart).
  String get initials => getInitials(name);
}

class RoleModel {
  const RoleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String code; // SUPER_ADMIN, ADMIN, KEPALA, GURU, BENDAHARA, WALI
  final String name;
  final String? description;
  final DateTime createdAt;

  factory RoleModel.fromJson(Map<String, dynamic> j) => RoleModel(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        createdAt: _parseDate(j['createdAt'])!,
      );
}

/// Helper parsing DateTime dari string Postgres / Supabase.
/// Bisa ISO8601 string atau null. Tidak throw — return null kalau null/empty.
DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}
