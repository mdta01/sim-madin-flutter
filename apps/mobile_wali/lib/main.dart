// ============================================================================
// SIM MADIN - Wali Santri (Flutter)
// ============================================================================
// Login via WhatsApp + PIN.
// Dashboard: list anak → detail (absensi, nilai, tagihan, ujian, chat, dll).
// Backend: Serverpod (Dart) — pakai api_client package.
// Realtime: Supabase Realtime untuk Notifikasi, Nilai, Absensi, Tagihan.
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
    child: const SimMadinWaliApp(),
  ));
}

class SimMadinWaliApp extends ConsumerWidget {
  const SimMadinWaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SIM MADIN - Wali Santri',
      debugShowCheckedModeBanner: !kReleaseMode,
      theme: appThemeLight,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
