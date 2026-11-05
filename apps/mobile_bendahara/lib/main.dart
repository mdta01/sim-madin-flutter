// ============================================================================
// SIM MADIN - Bendahara (Flutter)
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
  // Token FCM user akan di-save saat login (getAndSaveToken).
  await container.read(notificationServiceProvider).initialize();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const Mobile_bendaharaApp(),
  ));
}

class Mobile_bendaharaApp extends ConsumerWidget {
  const Mobile_bendaharaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global auth state listener — auto-redirect ke /login saat session
    // expired atau signOut dari device lain. Tanpa ini, user tetap di
    // dashboard walau sesi sudah mati, dan semua fetch 401.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut ||
            authState.event == AuthChangeEvent.tokenRefreshFailed) {
          ref.read(appRouterProvider).go('/login');
        }
      });
    });
    return MaterialApp.router(
      title: 'SIM Bendahara',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
