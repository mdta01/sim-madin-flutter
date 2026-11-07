// ============================================================================
// SIM MADIN — Kapabilitas kolom per tabel (GENERATED)
// ============================================================================
// AUTO-GENERATED oleh tool/gen_table_caps.py dari
// supabase/migrations/20231231000000_baseline_schema.sql
//
// JANGAN edit manual. Regenerate dengan:
//   python3 tool/gen_table_caps.py
//
// Dipakai oleh supabase_write.dart supaya payload INSERT/UPDATE hanya
// menyertakan kolom yang benar-benar ada. Ini mencegah error
// `column "X" does not exist` pada tabel yang tidak punya createdAt /
// updatedAt (mis. Notifikasi, ChatMessage, UjianSoal, SantriWali).
// ============================================================================

/// Kapabilitas kolom standar untuk sebuah tabel.
class TableColumnCaps {
  const TableColumnCaps({
    required this.hasId,
    required this.hasCreatedAt,
    required this.hasUpdatedAt,
    required this.hasDeletedAt,
  });

  final bool hasId;
  final bool hasCreatedAt;
  final bool hasUpdatedAt;
  final bool hasDeletedAt;
}

/// Peta nama tabel -> kapabilitas kolomnya (53 tabel).
const Map<String, TableColumnCaps> kTableCaps = <String, TableColumnCaps>{
  'Absensi': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'AkhlakPenilaian': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Alumni': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Announcement': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'AuditLog': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'BankSoal': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'CatatanWaliKelas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'ChatMessage': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'ChatRoom': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Guru': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'HafalanKitab': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'HonorGuru': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Jadwal': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'JenisTagihan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Kas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Kelas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'Kompetensi': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'MataPelajaran': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'Materi': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'Nilai': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Notifikasi': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Payment': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Pembinaan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'PengumpulanTugas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'PerkembanganQuran': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Permission': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Pertemuan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'PhoneChangeLog': TableColumnCaps(hasId: true, hasCreatedAt: false, hasUpdatedAt: false, hasDeletedAt: false),
  'QRScan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Rapor': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'RaporCatatan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'RaporMapel': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Role': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'RolePermission': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Santri': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'SantriWali': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Semester': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Surat': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'SystemSetting': TableColumnCaps(hasId: true, hasCreatedAt: false, hasUpdatedAt: true, hasDeletedAt: false),
  'Tagihan': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'TahunAjaran': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'TransaksiKas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'Tugas': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'Ujian': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'UjianJawaban': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'UjianNilai': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'UjianPeserta': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'UjianSesi': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: false),
  'UjianSoal': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'User': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'UserRole': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'Wali': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: true, hasDeletedAt: true),
  'WaliActivation': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
  'WaliPinReset': TableColumnCaps(hasId: true, hasCreatedAt: true, hasUpdatedAt: false, hasDeletedAt: false),
};
