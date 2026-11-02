// ============================================================================
// SIM MADIN - Bendahara (Flutter)
// ============================================================================
// Login via supabase.
// Backend: Serverpod (Dart) — pakai api_client package.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabase = await initSupabase();
  runApp(ProviderScope(
    overrides: [supabaseClientProvider.overrideWithValue(supabase)],
    child: const Mobile_bendaharaApp(),
  ));
}

class Mobile_bendaharaApp extends ConsumerWidget {
  const Mobile_bendaharaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SIM MADIN - Bendahara',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
