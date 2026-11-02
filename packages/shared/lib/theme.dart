// ============================================================================
// SIM MADIN — Theme Constants
// ============================================================================
// Islamic theme: kubah masjid (green) + bintang & buku (gold).
// Sumber: packages/shared/src/theme.ts di proyek lama.
// ============================================================================

import 'package:flutter/material.dart';

/// Warna brand SIM MADIN.
///
/// Konvensi:
/// - [primary] = hijau Islamic (kubah masjid) — untuk header, tombol, tab aktif
/// - [gold] = emas (bintang & buku di logo) — untuk accent, badge, highlight
/// - [background] = putih-offscreen untuk body
/// - [card] = putih murni untuk card
class AppColors {
  AppColors._();

  // ── Primary — Islamic Green (kubah masjid & shield) ──
  static const Color primary = Color(0xFF0D7A4F);
  static const Color primaryDark = Color(0xFF0A5C38);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // ── Gold Accent (bintang & buku di logo) ──
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFEF3C7);

  // ── Neutrals ──
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color white = Color(0xFFFFFFFF);

  // ── Semantic ──
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
}

/// Status badge style per status absensi/tagihan/dll.
class StatusStyles {
  StatusStyles._();

  /// Status kehadiran (Absensi).
  static const Map<String, StatusStyle> absensi = {
    'HADIR': StatusStyle(label: 'Hadir', color: AppColors.success, bg: AppColors.successLight),
    'SAKIT': StatusStyle(label: 'Sakit', color: AppColors.warning, bg: AppColors.warningLight),
    'IZIN': StatusStyle(label: 'Izin', color: AppColors.info, bg: AppColors.infoLight),
    'ALFA': StatusStyle(label: 'Alfa', color: AppColors.danger, bg: AppColors.dangerLight),
  };

  /// Status pembayaran tagihan.
  static const Map<String, StatusStyle> tagihan = {
    'LUNAS': StatusStyle(label: 'Lunas', color: AppColors.success, bg: AppColors.successLight),
    'BELUM_BAYAR': StatusStyle(label: 'Belum Bayar', color: AppColors.danger, bg: AppColors.dangerLight),
    'CICIL': StatusStyle(label: 'Cicil', color: AppColors.warning, bg: AppColors.warningLight),
    'TUNGGAKAN': StatusStyle(label: 'Tunggakan', color: AppColors.danger, bg: AppColors.dangerLight),
  };

  /// Status pengumpulan tugas.
  static const Map<String, StatusStyle> tugas = {
    'SUBMITTED': StatusStyle(label: 'Terkumpul', color: AppColors.info, bg: AppColors.infoLight),
    'GRADED': StatusStyle(label: 'Dinilai', color: AppColors.success, bg: AppColors.successLight),
    'NOT_SUBMITTED': StatusStyle(label: 'Belum', color: AppColors.textMuted, bg: AppColors.border),
    'OVERDUE': StatusStyle(label: 'Terlambat', color: AppColors.danger, bg: AppColors.dangerLight),
  };

  /// Status verifikasi pembayaran.
  static const Map<String, StatusStyle> verify = {
    'PENDING': StatusStyle(label: 'Pending', color: AppColors.warning, bg: AppColors.warningLight),
    'VERIFIED': StatusStyle(label: 'Terverifikasi', color: AppColors.success, bg: AppColors.successLight),
    'REJECTED': StatusStyle(label: 'Ditolak', color: AppColors.danger, bg: AppColors.dangerLight),
  };

  /// Helper untuk dapat style berdasarkan status string.
  static StatusStyle? forStatus(Map<String, StatusStyle> map, String? status) {
    if (status == null) return null;
    return map[status.toUpperCase()];
  }
}

class StatusStyle {
  const StatusStyle({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;
}

/// Font families yang dipakai di seluruh app.
class AppFonts {
  AppFonts._();
  static const String sans = 'Inter';
  static const String serif = 'NotoSerifSC'; // Untuk ayat Quran / Arabic text
  static const String mono = 'JetBrainsMono';
}

/// Radius standar untuk corner card / button.
class AppRadius {
  AppRadius._();
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;
}

/// Spacing scale (kelipatan 4).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Light theme untuk admin & mobile apps.
ThemeData get appThemeLight => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.background,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
