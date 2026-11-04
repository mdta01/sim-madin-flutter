// ============================================================================
// SIM MADIN — Theme Constants
// ============================================================================
// Islamic theme: kubah masjid (green) + bintang & buku (gold).
// Modern Material 3 design dengan elevation tints, gradients, dan responsive
// breakpoints.
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
  static const Color primaryContainer = Color(0xFF047857);

  // ── Gold Accent (bintang & buku di logo) ──
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color goldDark = Color(0xFFB45309);

  // ── Neutrals ──
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Semantic ──
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerDark = Color(0xFF991B1B);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // ── Modern Gradients ──
  /// Gradient utama: primary → primaryDark. Untuk header, hero cards.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Gradient Islamic: primary → gold. Untuk splash, login branding.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer, gold],
    stops: [0.0, 0.6, 1.0],
  );

  /// Gradient untuk success cards (pemasukan).
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, primary],
  );

  /// Gradient untuk danger cards (tunggakan).
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [danger, goldDark],
  );

  /// Gradient untuk warning cards (pending).
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, gold],
  );

  /// Gradient untuk info cards.
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [info, primaryContainer],
  );

  // ── Modern Elevation Shadows ──
  /// Shadow untuk card level 1 (default).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Shadow untuk card level 2 (elevated, floating).
  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Shadow untuk FAB / button prominent.
  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
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
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
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

/// Typography scale — modern heading + body styles.
/// Pakai Inter font family untuk konsistensi.
class AppTextStyles {
  AppTextStyles._();

  // Display (large hero text)
  static const TextStyle display1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle display2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static const TextStyle body1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Captions & labels
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );
}

/// Responsive breakpoints — adaptasi layout untuk phone / tablet / desktop.
/// Dipakai via MediaQuery di build method.
class Breakpoints {
  Breakpoints._();

  /// Phone (default) — width < 600
  static const double phone = 600;

  /// Tablet — 600 ≤ width < 900
  static const double tablet = 900;

  /// Desktop — width ≥ 900
  static const double desktop = 1200;

  /// Cek apakah device adalah phone.
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < phone;

  /// Cek apakah device adalah tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= phone &&
      MediaQuery.of(context).size.width < tablet;

  /// Cek apakah device adalah desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Jumlah kolom untuk grid berdasarkan lebar device.
  /// Phone = 1, Tablet = 2, Desktop = 3 atau 4.
  static int gridColumns(BuildContext context, {int desktopCols = 3}) {
    final width = MediaQuery.of(context).size.width;
    if (width < phone) return 1;
    if (width < tablet) return 2;
    return desktopCols;
  }

  /// Max content width untuk center-aligned layout di desktop.
  /// Phone/tablet = full width, Desktop = terbatas supaya tidak terlalu lebar.
  static double? maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return null; // phone = full width
  }

  /// Padding horizontal adaptive — lebih besar di tablet/desktop.
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }
}

/// Light theme untuk admin & mobile apps.
/// Material 3 dengan komponen modern (FilledButton, dll).
ThemeData get appThemeLight => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.background,
        error: AppColors.danger,
        onPrimary: AppColors.white,
        onSecondary: AppColors.black,
        onSurface: AppColors.text,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      // AppBar: pakai primary color dengan elevation 0 (modern flat design).
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.danger, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
    );
