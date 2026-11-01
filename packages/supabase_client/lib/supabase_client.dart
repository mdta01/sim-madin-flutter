// ============================================================================
// SIM MADIN — Supabase Client Wrapper
// ============================================================================
// Singleton Supabase client + helpers untuk realtime subscription.
// Dipakai oleh semua apps (admin_desktop & 4 mobile apps).
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider singleton SupabaseClient.
///
/// Dipanggil di `main.dart` semua apps via `ProviderScope` overrides:
/// ```dart
/// runApp(ProviderScope(
///   overrides: [supabaseClientProvider.overrideWithValue(...)],
///   child: MyApp(),
/// ));
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw UnimplementedError('Must override supabaseClientProvider in main.dart');
});

/// Inisialisasi Supabase client (harus dipanggil di main sebelum runApp).
Future<SupabaseClient> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
  );
  return Supabase.instance.client;
}

/// Helper untuk subscribe ke perubahan tabel Supabase Realtime.
///
/// Mengembalikan fungsi unsubscribe. Filter opsional (e.g. "wali_id=eq.123").
///
/// Contoh:
/// ```dart
/// final channel = subscribeToTable(
///   client: supabase,
///   table: 'Notifikasi',
///   filter: 'wali_id=eq.${wali.id}',
///   onPayload: (payload) {
///     if (payload.eventType == 'INSERT') {
///       showNotification(payload.newRecord);
///     }
///   },
/// );
/// // nanti: channel.unsubscribe();
/// ```
RealtimeChannel subscribeToTable({
  required SupabaseClient client,
  required String table,
  String? filter,
  required void Function(RealtimePayload payload) onPayload,
}) {
  final channel = client.channel('public:$table');

  channel.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(event: '*', schema: 'public', table: table, filter: filter),
    (payload, [ref]) {
      final typed = RealtimePayload.fromJson(payload as Map<String, dynamic>);
      onPayload(typed);
    },
  );

  channel.subscribe();
  return channel;
}

/// Payload dari Supabase Realtime.
class RealtimePayload {
  RealtimePayload({
    required this.eventType,
    this.newRecord,
    this.oldRecord,
    this.errors,
  });

  factory RealtimePayload.fromJson(Map<String, dynamic> json) {
    return RealtimePayload(
      eventType: json['eventType'] as String? ?? '',
      newRecord: json['new'] as Map<String, dynamic>?,
      oldRecord: json['old'] as Map<String, dynamic>?,
      errors: json['errors'] as List<dynamic>?.cast<String>(),
    );
  }

  /// 'INSERT' | 'UPDATE' | 'DELETE'.
  final String eventType;
  final Map<String, dynamic>? newRecord;
  final Map<String, dynamic>? oldRecord;
  final List<String>? errors;
}

/// Provider untuk auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield* client.auth.onAuthStateChange;
});

/// Helper: dapatkan current user ID (admin/guru/bendahara/kepala).
/// Untuk wali, pakai custom JWT (lihat api_client.dart).
String? currentAdminUid(WidgetRef ref) {
  final client = ref.read(supabaseClientProvider);
  return client.auth.currentUser?.id;
}
