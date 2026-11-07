// ============================================================================
// SIM MADIN - Kepala Madrasah (Flutter)
// ============================================================================
// Login via supabase.
// Backend: Serverpod (Dart) — pakai api_client package.
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

/// Init Firebase tanpa mematikan aplikasi kalau config belum tersedia.
Future<void> _initFirebaseSafely() async {
  try {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  } catch (e, st) {
    // Push notification non-kritis: log saja dan lanjut.
    // Penyebab umum: google-services.json belum ditambahkan (lihat
    // docs/PRODUCTION-CHECKLIST.md bagian Firebase).
    debugPrint('Firebase init dilewati (push notification nonaktif): $e');
    if (kDebugMode) debugPrintStack(stackTrace: st);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabase = await initSupabase();

  // Initialize Firebase untuk FCM push notification.
  //
  // PENTING: Firebase.initializeApp() TIDAK boleh membuat app crash saat
  // startup. Di repo ini `google-services.json` / `GoogleService-Info.plist`
  // tidak di-commit (berisi kredensial project) dan di desktop tidak relevan,
  // jadi kalau file config belum ada, pemanggilan tanpa guard akan melempar
  // exception dan aplikasi langsung mati sebelum sempat menampilkan UI.
  //
  // Push notification bersifat opsional: kalau Firebase gagal init, aplikasi
  // tetap jalan penuh dan realtime Supabase (jalur utama sinkronisasi antar
  // aplikasi) tetap aktif.
  await _initFirebaseSafely();

  // Buat ProviderContainer lebih awal supaya bisa init NotificationService
  // (butuh Ref untuk akses supabaseClientProvider) sebelum runApp.
  final container = ProviderContainer(
    overrides: [supabaseClientProvider.overrideWithValue(supabase)],
  );

  // Init notification service (Firebase + FCM + local notifications).
  // Token FCM user akan di-save saat login (getAndSaveToken).
  await container.read(notificationServiceProvider).initialize();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const Mobile_kepalaApp(),
  ));
}

class Mobile_kepalaApp extends ConsumerWidget {
  const Mobile_kepalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global auth state listener — auto-redirect ke /login saat session
    // expired atau signOut dari device lain. Tanpa ini, user tetap di
    // dashboard walau sesi sudah mati, dan semua fetch 401.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          ref.read(appRouterProvider).go('/login');
        }
      });
    });
    return MaterialApp.router(
      title: 'SIM Kepala',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
