// ============================================================================
// SIM MADIN - Wali Santri (Flutter)
// ============================================================================
// Login via WhatsApp + PIN.
// Dashboard: list anak → detail (absensi, nilai, tagihan, ujian, chat, dll).
// Backend: Serverpod (Dart) — pakai api_client package.
// Realtime: Supabase Realtime untuk Notifikasi, Nilai, Absensi, Tagihan.
// ============================================================================

import 'package:api_client/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;

import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabase = await initSupabase();

  // Initialize Firebase untuk FCM push notification.
  await Firebase.initializeApp();

  // Buat ProviderContainer lebih awal supaya bisa init NotificationService
  // (butuh Ref untuk akses supabaseClientProvider) sebelum runApp.
  final container = ProviderContainer(
    overrides: [supabaseClientProvider.overrideWithValue(supabase)],
  );

  // Init notification service (Firebase + FCM + local notifications).
  // Catatan: untuk mobile_wali, getAndSaveToken() tidak dipanggil di sini —
  // wali tidak pakai Supabase Auth (pakai WA+PIN). Token FCM akan
  // didaftarkan ke DB setelah loginWali berhasil (di mutation_providers_wali.dart).
  await container.read(notificationServiceProvider).initialize();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SimMadinWaliApp(),
  ));
}

class SimMadinWaliApp extends ConsumerWidget {
  const SimMadinWaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auth state listener — redirect ke /login saat session expired.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          ref.read(appRouterProvider).go('/login');
        }
      });
    });
    return MaterialApp.router(
      title: 'SIM Wali',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
