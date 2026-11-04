// ============================================================================
// SIM MADIN - Kepala Madrasah (Flutter)
// ============================================================================
// Login via supabase.
// Backend: Serverpod (Dart) — pakai api_client package.
// ============================================================================

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
  runApp(ProviderScope(
    overrides: [supabaseClientProvider.overrideWithValue(supabase)],
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
        if (authState.event == AuthChangeEvent.signedOut ||
            authState.event == AuthChangeEvent.tokenRefreshFailed) {
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
