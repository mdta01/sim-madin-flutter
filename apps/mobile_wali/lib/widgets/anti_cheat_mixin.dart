// Anti-cheat observer — deteksi app background/tab switch saat ujian.
// Pakai WidgetsBindingObserver untuk monitor AppLifecycleState.

import 'package:flutter/widgets.dart';

/// Mixin untuk monitor app lifecycle. Mix ke StatefulWidget yang
/// menjalankan ujian take screen.
///
/// Cara pakai:
/// ```dart
/// class _UjianTakeScreenState extends State<UjianTakeScreen>
///     with WidgetsBindingObserver, AntiCheatMixin {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(this);
///   }
///
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(this);
///     super.dispose();
///   }
///
///   @override
///   void didChangeAppLifecycleState(AppLifecycleState state) {
///     onAppLifecycleChanged(state); // dari AntiCheatMixin
///   }
/// }
/// ```
mixin AntiCheatMixin<T extends StatefulWidget> on State<T> {
  int _violationCount = 0;
  DateTime? _lastViolationAt;
  static const _maxViolations = 3;

  /// Dipanggil saat ada violation (app background/tab switch).
  /// Override di host class untuk customize behavior (mis. show dialog,
  /// auto-submit, dll).
  void onViolation(String reason) {
    _violationCount++;
    _lastViolationAt = DateTime.now();
    debugPrint('🚨 Anti-cheat violation #$_violationCount: $reason');

    if (_violationCount >= _maxViolations) {
      onCheatDetected('Terlalu banyak keluar app ($_violationCount)x). '
          'Ujian akan di-submit otomatis.');
    } else {
      onWarning('Peringatan: $_violationCount/$_maxViolations — $reason. '
          'Keluar app sekali lagi akan meng-submit ujian otomatis.');
    }
  }

  /// Default no-op. Override di host untuk show dialog.
  void onWarning(String message) {
    debugPrint('⚠️ Anti-cheat warning: $message');
  }

  /// Default no-op. Override di host untuk auto-submit + close ujian.
  void onCheatDetected(String reason) {
    debugPrint('🚨🚨 Cheat detected: $reason');
  }

  /// Helper — call from didChangeAppLifecycleState.
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App di-background atau user switch app
      onViolation('App di-background (${state.name})');
    }
  }

  int get violationCount => _violationCount;
  DateTime? get lastViolationAt => _lastViolationAt;
  void resetViolations() => _violationCount = 0;
}
