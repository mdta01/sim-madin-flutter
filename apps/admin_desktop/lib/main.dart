// ============================================================================
// SIM MADIN - Admin Desktop (Flutter)
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
    child: const Admin_desktopApp(),
  ));
}

class Admin_desktopApp extends ConsumerWidget {
  const Admin_desktopApp({super.key});

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
      title: 'SIM MADIN - Admin Desktop',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
