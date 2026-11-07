// ============================================================================
// SIM MADIN - Admin Desktop (Flutter)
// ============================================================================
// Login via supabase.
// Backend: Serverpod (Dart) — pakai api_client package.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;
import 'package:window_manager/window_manager.dart';

import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tampilkan pesan error asli alih-alih kotak abu-abu kosong
  // (ErrorWidget bawaan Flutter di mode release).
  installVisibleErrorHandler();

  // WAJIB: intl tidak menyertakan data locale. Tanpa ini,
  // DateFormat(..., 'id_ID') / NumberFormat(locale: 'id_ID') melempar
  // LocaleDataException dan setiap layar yang menampilkan tanggal
  // akan menjadi kotak abu-abu kosong di mode release.
  await initializeDateFormatting('id_ID', null);
  markIndonesianLocaleReady();
  final supabase = await initSupabase();

  // Desktop window setup — set minimum size + title
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(1024, 600),
        title: 'SIM MADIN — Admin Desktop',
        center: true,
        titleBarStyle: TitleBarStyle.normal,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

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
