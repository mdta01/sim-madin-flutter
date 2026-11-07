// ============================================================================
// SIM MADIN — Penampil error yang terlihat
// ============================================================================
// Di Flutter mode release, setiap exception saat build widget diganti dengan
// ErrorWidget: sebuah kotak abu-abu polos tanpa penjelasan apa pun.
//
// Akibatnya bug seperti "semua layar kosong abu-abu" tidak bisa didiagnosis
// dari perangkat pengguna. Helper di file ini menggantinya dengan tampilan
// yang memuat pesan error asli, konteks, dan library asalnya.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Pasang pengganti ErrorWidget + logger error global.
///
/// Panggil sekali di `main()` masing-masing aplikasi setelah
/// `WidgetsFlutterBinding.ensureInitialized()`.
void installVisibleErrorHandler() {
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      VisibleErrorWidget(details: details);

  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('  di: ${details.library} — ${details.context}');
    if (details.stack != null) debugPrintStack(stackTrace: details.stack);
    previous?.call(details);
  };
}

/// Pengganti kotak abu-abu: pesan error asli yang bisa dibaca & disalin.
class VisibleErrorWidget extends StatelessWidget {
  const VisibleErrorWidget({super.key, required this.details});

  final FlutterErrorDetails details;

  String get _message {
    final e = details.exceptionAsString();
    return e.length > 900 ? '${e.substring(0, 900)}…' : e;
  }

  @override
  Widget build(BuildContext context) {
    // Widget dasar tanpa tema/Provider: harus tetap tampil walau tema atau
    // container provider sedang bermasalah.
    return Material(
      color: const Color(0xFFFFF3F3),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Color(0xFFB3261E)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terjadi kesalahan pada tampilan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                _message,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
              if (details.context != null) ...[
                const SizedBox(height: 6),
                SelectableText(
                  'Konteks: ${details.context}',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF555555)),
                ),
              ],
              if (details.library != null) ...[
                const SizedBox(height: 4),
                SelectableText(
                  'Library: ${details.library}',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF555555)),
                ),
              ],
              const SizedBox(height: 12),
              const SelectableText(
                'Screenshot pesan di atas lalu kirim ke pengembang.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
