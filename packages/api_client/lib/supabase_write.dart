// ============================================================================
// SIM MADIN — Supabase write helpers
// ============================================================================
// Semua tabel SIM MADIN dibuat oleh Prisma. Prisma mengisi `id` (cuid),
// `createdAt`, dan `updatedAt` di sisi aplikasi — kolomnya NOT NULL di
// database TANPA DEFAULT. Artinya setiap INSERT dari Flutter WAJIB
// mengirimkan ketiga kolom tersebut, kalau tidak Postgres menolak dengan:
//
//   null value in column "createdAt" of relation "X" violates not-null
//   constraint
//
// Helper di file ini memusatkan kontrak tersebut supaya tidak ada lagi
// insert yang lupa `createdAt`/`updatedAt` (bug yang sebelumnya membuat
// create user, create role, create jadwal, create ujian, create kas,
// create pengumuman, kirim chat, dst. gagal di production).
//
// Cara pakai:
//   await client.from('Kas').insert(
//     insertRow({'code': code, 'name': name, 'balance': 0}),
//   );
//
//   await client.from('Kas').update(
//     updateRow({'balance': newBalance}),
//   ).eq('id', id);
// ============================================================================

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Waktu sekarang dalam UTC, format ISO-8601 (aman untuk kolom `timestamptz`).
String nowIso() => DateTime.now().toUtc().toIso8601String();

/// Generate primary key baru (UUID v4 — menggantikan `cuid()` milik Prisma).
///
/// Kolom `id` bertipe `text`, jadi UUID valid dan tidak akan bertabrakan
/// dengan cuid lama yang sudah ada di database.
String newId() => _uuid.v4();

/// Bangun payload INSERT yang lengkap: `id`, `createdAt`, `updatedAt`
/// (bisa dimatikan lewat parameter kalau tabel tidak punya kolom itu).
///
/// Nilai di [data] menang atas nilai otomatis, jadi pemanggil tetap bisa
/// meng-override `id` (mis. saat migrasi data) atau timestamp (mis. import).
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

/// Bangun payload UPDATE yang selalu menyegarkan `updatedAt`.
///
/// Dipakai untuk semua `.update(...)` supaya kolom `updatedAt` (NOT NULL)
/// dan trigger audit tetap konsisten.
Map<String, dynamic> updateRow(Map<String, dynamic> data) {
  return <String, dynamic>{
    'updatedAt': nowIso(),
    ...data,
  };
}

/// Versi insert untuk tabel yang memakai composite key tanpa kolom `id`
/// (mis. tabel pivot `SantriWali`), sehingga hanya timestamp yang disuntik.
Map<String, dynamic> insertRowNoId(
  Map<String, dynamic> data, {
  bool withTimestamps = true,
}) {
  return <String, dynamic>{
    if (withTimestamps) ...{
      'createdAt': nowIso(),
      'updatedAt': nowIso(),
    },
    ...data,
  };
}

/// Soft delete: set `deletedAt` + segarkan `updatedAt`.
Map<String, dynamic> softDeleteRow() => <String, dynamic>{
      'deletedAt': nowIso(),
      'updatedAt': nowIso(),
    };
