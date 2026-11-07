// ============================================================================
// SIM MADIN — Supabase write helpers
// ============================================================================
// Semua tabel SIM MADIN dibuat oleh Prisma. Prisma mengisi `id` (cuid),
// `createdAt`, dan `updatedAt` di sisi aplikasi — kolomnya NOT NULL di
// database TANPA DEFAULT. Artinya setiap INSERT dari Flutter WAJIB
// mengirimkan kolom tersebut, kalau tidak Postgres menolak dengan:
//
//   null value in column "createdAt" of relation "X" violates not-null
//   constraint
//
// TAPI tidak semua tabel punya ketiga kolom. Contoh nyata:
//   - Notifikasi, ChatMessage, UjianSoal, AuditLog, QRScan, SantriWali,
//     Permission, UserRole, RolePermission  → tidak punya `updatedAt`
//   - SystemSetting, PhoneChangeLog         → tidak punya `createdAt`
// Mengirim kolom yang tidak ada juga error (`column "X" does not exist`),
// jadi helper di bawah ini membaca `kTableCaps` (generated dari DDL asli)
// dan hanya menyertakan kolom yang memang ada.
//
// Cara pakai:
//   await client.from('Kas').insert(rowFor('Kas', {...}));
//   await client.from('Kas').update(patchFor('Kas', {...})).eq('id', id);
//
// Alias `insertRow` / `updateRow` / `softDeleteRow` dipertahankan supaya
// pemanggilan lama tetap kompatibel.
// ============================================================================

import 'package:uuid/uuid.dart';

import 'table_columns.dart';

const _uuid = Uuid();

/// Waktu sekarang dalam UTC, format ISO-8601 (aman untuk kolom `timestamptz`).
String nowIso() => DateTime.now().toUtc().toIso8601String();

/// Generate primary key baru (UUID v4 — menggantikan `cuid()` milik Prisma).
///
/// Kolom `id` bertipe `text`, jadi UUID valid dan tidak akan bertabrakan
/// dengan cuid lama yang sudah ada di database.
String newId() => _uuid.v4();

/// Kapabilitas kolom untuk [table]; tabel tak dikenal dianggap punya kolom
/// standar supaya tetap kompatibel (lebih baik gagal eksplisit di DB daripada
/// diam-diam tidak mengirim timestamp).
TableColumnCaps capsFor(String table) =>
    kTableCaps[table] ??
    const TableColumnCaps(
      hasId: true,
      hasCreatedAt: true,
      hasUpdatedAt: true,
      hasDeletedAt: true,
    );

/// Bangun payload INSERT lengkap untuk [table].
///
/// Hanya menambahkan `id` / `createdAt` / `updatedAt` bila kolom tersebut
/// benar-benar ada di tabel. Nilai di [data] selalu menang, jadi pemanggil
/// tetap bisa meng-override `id` atau timestamp (mis. saat import data).
Map<String, dynamic> rowFor(String table, Map<String, dynamic> data) {
  final caps = capsFor(table);
  return <String, dynamic>{
    if (caps.hasId) 'id': (data['id'] as String?) ?? newId(),
    if (caps.hasCreatedAt) 'createdAt': nowIso(),
    if (caps.hasUpdatedAt) 'updatedAt': nowIso(),
    ...data,
  };
}

/// Bangun payload UPDATE untuk [table] — selalu menyegarkan `updatedAt`
/// bila kolomnya ada.
Map<String, dynamic> patchFor(String table, Map<String, dynamic> data) {
  return <String, dynamic>{
    if (capsFor(table).hasUpdatedAt) 'updatedAt': nowIso(),
    ...data,
  };
}

/// Soft delete untuk [table]: isi `deletedAt` + segarkan `updatedAt`.
///
/// Melempar [ArgumentError] kalau tabel tidak punya kolom `deletedAt`,
/// supaya tidak ada hard delete yang tidak sengaja.
Map<String, dynamic> softDeleteFor(String table) {
  final caps = capsFor(table);
  if (!caps.hasDeletedAt) {
    throw ArgumentError.value(
      table,
      'table',
      'Tabel ini tidak punya kolom deletedAt — pakai delete() biasa.',
    );
  }
  final now = nowIso();
  return <String, dynamic>{
    'deletedAt': now,
    if (caps.hasUpdatedAt) 'updatedAt': now,
  };
}

// ---------------------------------------------------------------------------
// Alias kompatibilitas (pemanggilan lama tanpa nama tabel)
// ---------------------------------------------------------------------------

/// Lihat [rowFor]. Tanpa nama tabel dianggap punya kolom standar lengkap —
/// hanya dipakai di tempat yang tabelnya sudah pasti (mis. update mutation).
Map<String, dynamic> insertRow(
  Map<String, dynamic> data, {
  String? id,
  bool withTimestamps = true,
}) {
  return <String, dynamic>{
    'id': id ?? (data['id'] as String?) ?? newId(),
    if (withTimestamps) ...{
      'createdAt': nowIso(),
      'updatedAt': nowIso(),
    },
    ...data,
  };
}

/// Lihat [patchFor].
Map<String, dynamic> updateRow(Map<String, dynamic> data) {
  return <String, dynamic>{
    'updatedAt': nowIso(),
    ...data,
  };
}

/// Soft delete generik (tabel diasumsikan punya `deletedAt`).
Map<String, dynamic> softDeleteRow() => <String, dynamic>{
      'deletedAt': nowIso(),
      'updatedAt': nowIso(),
    };
