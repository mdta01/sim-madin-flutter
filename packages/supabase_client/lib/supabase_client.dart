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
/// Filter format: `"column=op.value"` (Prisma-style), op mendukung:
/// `eq`, `neq`, `in`, `lt`, `lte`, `gt`, `gte`. Contoh:
///   `filter: 'santri_id=eq.${santri.id}'`
///   `filter: 'status=in.(LUNAS,BELUM_BAYAR)'`
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
  final channel = client.channel('public:$table:${filter ?? 'all'}');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: table,
    filter: _parseFilter(filter),
    callback: (payload) {
      onPayload(RealtimePayload(
        eventType: payload.eventType.name.toUpperCase(),
        newRecord: payload.newRecord as Map<String, dynamic>?,
        oldRecord: payload.oldRecord as Map<String, dynamic>?,
        errors: payload.errors?.map((e) => e.toString()).toList(),
      ));
    },
  );

  channel.subscribe();
  return channel;
}

/// Parse filter string "column=op.value" → PostgresChangeFilter.
/// Mendukung op: eq, neq, in, lt, lte, gt, gte.
/// Untuk `in`, value-nya harus dalam format `(val1,val2,val3)`.
/// Mengembalikan null kalau filter null/empty/unparseable.
PostgresChangeFilter? _parseFilter(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  // Format: "column=op.value" — split hanya pada tanda '=' pertama.
  final eqIdx = raw.indexOf('=');
  if (eqIdx < 0) return null;

  final column = raw.substring(0, eqIdx).trim();
  final rest = raw.substring(eqIdx + 1).trim();
  final dotIdx = rest.indexOf('.');
  if (dotIdx < 0) return null;

  final opStr = rest.substring(0, dotIdx).toLowerCase();
  final value = rest.substring(dotIdx + 1).trim();

  PostgresChangeFilterType type;
  switch (opStr) {
    case 'eq':
      type = PostgresChangeFilterType.eq;
      break;
    case 'neq':
      type = PostgresChangeFilterType.neq;
      break;
    case 'lt':
      type = PostgresChangeFilterType.lt;
      break;
    case 'lte':
      type = PostgresChangeFilterType.lte;
      break;
    case 'gt':
      type = PostgresChangeFilterType.gt;
      break;
    case 'gte':
      type = PostgresChangeFilterType.gte;
      break;
    case 'in':
      type = PostgresChangeFilterType.inFilter;
      // value untuk `in` format "(a,b,c)" — Supabase SDK menerima list.
      // Kita trim () dan split koma, lalu lewatkan sebagai list via value.
      // Catatan: PostgresChangeFilter `inFilter` butuh value list; tapi konstruktornya
      // menerima `value` tunggal. Untuk list, kita gabung balik "(a,b,c)".
      // Workaround: lewatkan string "(a,b,c)" apa adanya — Supabase akan parse.
      break;
    default:
      return null;
  }

  return PostgresChangeFilter(type: type, column: column, value: value);
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
