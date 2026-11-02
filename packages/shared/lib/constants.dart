// ============================================================================
// SIM MADIN — App Constants
// ============================================================================
// Sumber: packages/shared/src/constants.ts di proyek lama.
// ============================================================================

/// Nama hari (Senin-Sabtu). Index 0 = Senin.
const List<String> kDays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  // Minggu tidak termasuk — madrasah libur
];

/// Map index hari (0-6, Senin=0) ke label Indonesia.
const Map<int, String> kDayIndex = {
  0: 'Senin',
  1: 'Selasa',
  2: 'Rabu',
  3: 'Kamis',
  4: 'Jumat',
  5: 'Sabtu',
  6: 'Minggu',
};

/// Konfigurasi Supabase (singleton — sama untuk semua app).
class SupabaseConfig {
  SupabaseConfig._();

  /// URL proyek Supabase yang aktif (existing project).
  static const String url = 'https://ooglxextkliuhpequwme.supabase.co';

  /// Anon key (public — sudah aman di-embed di client).
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vZ2x4ZXh0a2xpdWhwZXF1d21lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMDYyNzUsImV4cCI6MjEwODc4MjI3NX0.os3Vbdo0TB6z4OrH4b3ZLFQqBpNY1pMN-8LKyhZaK2w';

  /// URL backend Serverpod (akan diisi setelah deploy).
  /// Untuk development: http://localhost:8080
  /// Untuk production: https://api.sim-madin.id (contoh).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Maksimal OTP attempts per jam (rate limit).
  static const int otpRateLimitPerHour = 5;

  /// Lock duration setelah 5x PIN salah.
  static const Duration pinLockDuration = Duration(minutes: 15);

  /// Maksimal PIN attempts sebelum lock.
  static const int maxPinAttempts = 5;

  /// Token expiry (7 hari).
  static const Duration tokenExpiry = Duration(days: 7);
}

/// Menu sidebar admin (34 menu — sesuai React app).
/// Dipakai di `apps/admin_desktop/lib/app_router.dart`.
class AdminMenu {
  AdminMenu._();

  static const List<AdminMenuItem> items = [
    AdminMenuItem(id: 'dashboard', label: 'Dashboard', icon: 'dashboard'),
    AdminMenuItem(id: 'santri', label: 'Santri', icon: 'people'),
    AdminMenuItem(id: 'wali', label: 'Wali Santri', icon: 'family_restroom'),
    AdminMenuItem(id: 'guru', label: 'Guru', icon: 'school'),
    AdminMenuItem(id: 'kelas', label: 'Kelas', icon: 'class'),
    AdminMenuItem(id: 'mapel', label: 'Mata Pelajaran', icon: 'menu_book'),
    AdminMenuItem(id: 'jadwal', label: 'Jadwal', icon: 'calendar_today'),
    AdminMenuItem(id: 'pertemuan', label: 'Pertemuan', icon: 'event_available'),
    AdminMenuItem(id: 'absensi', label: 'Absensi', icon: 'fact_check'),
    AdminMenuItem(id: 'nilai', label: 'Nilai', icon: 'grade'),
    AdminMenuItem(id: 'tahun-ajaran', label: 'Tahun Ajaran', icon: 'date_range'),
    AdminMenuItem(id: 'siklus', label: 'Siklus Akademik', icon: 'loop'),
    AdminMenuItem(id: 'tagihan', label: 'Tagihan', icon: 'receipt_long'),
    AdminMenuItem(id: 'pembayaran', label: 'Pembayaran', icon: 'payments'),
    AdminMenuItem(id: 'kas', label: 'Kas', icon: 'account_balance_wallet'),
    AdminMenuItem(id: 'honor-guru', label: 'Honor Guru', icon: 'work'),
    AdminMenuItem(id: 'tugas', label: 'Tugas', icon: 'assignment'),
    AdminMenuItem(id: 'materi', label: 'Materi', icon: 'menu_book'),
    AdminMenuItem(id: 'ujian', label: 'Ujian', icon: 'quiz'),
    AdminMenuItem(id: 'bank-soal', label: 'Bank Soal', icon: 'inventory_2'),
    AdminMenuItem(id: 'rapor', label: 'Rapor', icon: 'description'),
    AdminMenuItem(id: 'kompetensi', label: 'Kompetensi', icon: 'workspace_premium'),
    AdminMenuItem(id: 'pengumuman', label: 'Pengumuman', icon: 'campaign'),
    AdminMenuItem(id: 'notifikasi', label: 'Notifikasi', icon: 'notifications'),
    AdminMenuItem(id: 'surat', label: 'Surat', icon: 'mail'),
    AdminMenuItem(id: 'perkembangan', label: 'Perkembangan', icon: 'trending_up'),
    AdminMenuItem(id: 'alumni', label: 'Alumni', icon: 'school_outlined'),
    AdminMenuItem(id: 'chat', label: 'Chat', icon: 'chat'),
    AdminMenuItem(id: 'qr', label: 'QR Code', icon: 'qr_code'),
    AdminMenuItem(id: 'audit-log', label: 'Audit Log', icon: 'history'),
    AdminMenuItem(id: 'users', label: 'Users', icon: 'manage_accounts'),
    AdminMenuItem(id: 'roles', label: 'Roles', icon: 'shield'),
    AdminMenuItem(id: 'permissions', label: 'Permissions', icon: 'lock'),
    AdminMenuItem(id: 'settings', label: 'Settings', icon: 'settings'),
  ];
}

class AdminMenuItem {
  const AdminMenuItem({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final String icon;
}

/// Permission codes (15 modul × 4 action = 60 codes).
/// Format: `{module}:{action}`.
class Permissions {
  Permissions._();

  static const List<String> all = [
    // Santri
    'santri:view', 'santri:create', 'santri:edit', 'santri:delete',
    // Wali
    'wali:view', 'wali:create', 'wali:edit', 'wali:delete',
    // Guru
    'guru:view', 'guru:create', 'guru:edit', 'guru:delete',
    // Kelas
    'kelas:view', 'kelas:create', 'kelas:edit', 'kelas:delete',
    // Mapel
    'mapel:view', 'mapel:create', 'mapel:edit', 'mapel:delete',
    // Absensi
    'absensi:view', 'absensi:create', 'absensi:edit', 'absensi:delete',
    // Nilai
    'nilai:view', 'nilai:create', 'nilai:edit', 'nilai:delete',
    // Tagihan
    'tagihan:view', 'tagihan:create', 'tagihan:edit', 'tagihan:delete',
    // Pembayaran
    'pembayaran:view', 'pembayaran:create', 'pembayaran:edit', 'pembayaran:delete',
    // Rapor
    'rapor:view', 'rapor:create', 'rapor:edit', 'rapor:delete',
    // Ujian
    'ujian:view', 'ujian:create', 'ujian:edit', 'ujian:delete',
    // Tugas
    'tugas:view', 'tugas:create', 'tugas:edit', 'tugas:delete',
    // Pengumuman
    'pengumuman:view', 'pengumuman:create', 'pengumuman:edit', 'pengumuman:delete',
    // Users & Roles
    'users:view', 'users:create', 'users:edit', 'users:delete',
  ];

  static const List<String> modules = [
    'santri', 'wali', 'guru', 'kelas', 'mapel',
    'absensi', 'nilai', 'tagihan', 'pembayaran', 'rapor',
    'ujian', 'tugas', 'pengumuman', 'users',
  ];

  static const List<String> actions = ['view', 'create', 'edit', 'delete'];
}

/// Role preset (sesuai existing schema).
class Roles {
  Roles._();
  static const String superAdmin = 'SUPER_ADMIN';
  static const String admin = 'ADMIN';
  static const String kepala = 'KEPALA';
  static const String guru = 'GURU';
  static const String bendahara = 'BENDAHARA';
  static const String wali = 'WALI';
}

/// Jenis tagihan (untuk auto-generate).
class JenisTagihan {
  JenisTagihan._();
  static const String spp = 'SPP';
  static const String gedung = 'GEDUNG';
  static const String seragam = 'SERAGAM';
  static const String buku = 'BUKU';
  static const String kegiatan = 'KEGIATAN';
  static const String lainnya = 'LAINNYA';
}

/// Status ujian.
class UjianStatus {
  UjianStatus._();
  static const String draft = 'DRAFT';
  static const String published = 'PUBLISHED';
  static const String ongoing = 'ONGOING';
  static const String finished = 'FINISHED';
  static const String cancelled = 'CANCELLED';

  /// Konversi kode status → label Indonesia untuk display.
  static String label(String? s) {
    switch (s) {
      case draft:
        return 'Draft';
      case published:
        return 'Terbit';
      case ongoing:
        return 'Berlangsung';
      case finished:
        return 'Selesai';
      case cancelled:
        return 'Dibatalkan';
      default:
        return s ?? '-';
    }
  }
}

/// Jenis soal ujian.
class SoalType {
  SoalType._();
  static const String pg = 'PG'; // Pilihan ganda
  static const String isian = 'ISIAN';
  static const String essay = 'ESSAY';
}

/// Persentase minimal kelulusan.
class PassingGrade {
  PassingGrade._();
  static const double kkm = 70.0; // Kriteria Ketuntasan Minimal
}

/// WhatsApp OTP rate limit (5/hour, lockout 15 min).
class OtpConfig {
  OtpConfig._();
  static const int rateLimitPerHour = 5;
  static const Duration lockDuration = Duration(minutes: 15);
  static const int otpLength = 6;
  static const Duration otpExpiry = Duration(minutes: 5);
}

/// 50 PIN lemah yang di-blacklist.
const Set<String> kBlacklistedPins = {
  '000000', '111111', '222222', '333333', '444444',
  '555555', '666666', '777777', '888888', '999999',
  '123456', '654321', '112233', '221100', '123123',
  '111222', '222333', '333444', '444555', '555666',
  '001122', '112244', '223344', '334455', '445566',
  '000111', '111000', '121212', '131313', '141414',
  '151515', '161616', '171717', '181818', '191919',
  '202020', '212121', '060606', '080808', '090909',
  '252525', '353535', '454545', '656565', '757575',
  '858585', '959595', '012345', '543210', '024680',
};
