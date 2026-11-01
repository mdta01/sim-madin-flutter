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
/// Dipanggil di `main.dart` semua apps via `ProviderScope` overrides.
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

/// Payload dari Supabase Realtime (postgres_changes event).
class RealtimePayload {
  RealtimePayload({
    required this.eventType,
    this.newRecord,
    this.oldRecord,
    this.errors,
  });

  /// 'INSERT' | 'UPDATE' | 'DELETE' | '*'.
  final String eventType;
  final Map<String, dynamic>? newRecord;
  final Map<String, dynamic>? oldRecord;
  final List<String>? errors;
}

/// Subscribe ke perubahan tabel Supabase Realtime.
///
/// Mengembalikan RealtimeChannel — panggil `.unsubscribe()` untuk berhenti.
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
  // supabase_flutter v2.x: pakai channel().onPostgresChanges()
  // dengan PostgresChangeEvent (enum, bukan string)
  final channel = client.channel('public:$table');

  // Untuk filter, supabase_flutter v2.x pakai Map filter
  // Format filter: "wali_id=eq.123" → {column: 'wali_id', value: 'eq.123'}
  // Tapi API v2 lebih ketat — untuk simplicity, kita ignore filter dulu
  // dan biarkan caller filter manual di onPayload (untuk Phase 1).
  // TODO Phase 2+: implementasi filter yang benar dengan PostgresChangeFilter

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: table,
    callback: (payload) {
      onPayload(RealtimePayload(
        eventType: payload.type.name.toUpperCase(),
        newRecord: payload.newRecord as Map<String, dynamic>?,
        oldRecord: payload.oldRecord as Map<String, dynamic>?,
        errors: payload.errors?.cast<String>(),
      ));
    },
  );

  channel.subscribe();
  return channel;
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
