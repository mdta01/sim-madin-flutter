// ============================================================================
// SIM MADIN — Supabase Query Providers (Phase 2)
// ============================================================================
// Riverpod providers untuk query Supabase Postgres. Dipakai oleh mobile_kepala
// (read-only monitors) — juga reusable untuk mobile_guru/bendahara/wali di fase
// berikutnya.
//
// Catatan: di TS app lama, queries ini dipanggil ke Next.js API routes
// (`/api/admin/santri`, dll). Di Flutter, kita query Supabase Postgres langsung
// (RLS akan aman karena Supabase Auth sudah set session token).
//
// Untuk aggregate dashboard (chart keuangan, distribusi per kelas, top santri,
// persentase hadir), kita fetch raw rows lalu compute client-side. Volume data
// per madrasah hanya ratusan santri → aman untuk komputasi client.
//
// Saat Serverpod siap di fase berikutnya, providers ini bisa diganti dengan
// endpoint RPC yang compute server-side — signature provider tetap sama.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Helper: parse Santri row + nested relations
// ---------------------------------------------------------------------------

SantriModel _santriFromRow(Map<String, dynamic> row) {
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final wali = (row['Wali'] ?? row['wali']) as Map<String, dynamic>?;
  return SantriModel.fromJson({
    ...row,
    if (kelas != null) 'kelasName': kelas['name'],
    if (kelas != null) 'kelasCode': kelas['code'],
    if (wali != null) 'waliName': wali['name'],
    if (wali != null) 'waliPhone': wali['phone'],
  });
}

AbsensiModel _absensiFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  return AbsensiModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (kelas != null) 'kelasCode': kelas['code'],
  });
}

NilaiModel _nilaiFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final mapel =
      (row['MataPelajaran'] ?? row['mapel']) as Map<String, dynamic>?;
  return NilaiModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (mapel != null) 'mapelName': mapel['name'],
    if (mapel != null) 'mapelKkm': mapel['kkm'],
  });
}

TagihanModel _tagihanFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final kelas = (row['Kelas'] ?? row['kelas']) as Map<String, dynamic>?;
  final jenis =
      (row['JenisTagihan'] ?? row['jenisTagihan']) as Map<String, dynamic>?;
  return TagihanModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (kelas != null) 'kelasName': kelas['name'],
    if (jenis != null) 'jenisTagihanCode': jenis['code'],
    if (jenis != null) 'jenisTagihanName': jenis['name'],
  });
}

PaymentModel _paymentFromRow(Map<String, dynamic> row) {
  final santri = (row['Santri'] ?? row['santri']) as Map<String, dynamic>?;
  final tagihan = (row['Tagihan'] ?? row['tagihan']) as Map<String, dynamic>?;
  final jenis =
      tagihan?['JenisTagihan'] ?? tagihan?['jenisTagihan'];
  return PaymentModel.fromJson({
    ...row,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (jenis != null) 'tagihanCode': jenis['code'],
  });
}

HonorGuruModel _honorGuruFromRow(Map<String, dynamic> row) {
  final guru = (row['Guru'] ?? row['guru']) as Map<String, dynamic>?;
  return HonorGuruModel.fromJson({
    ...row,
    if (guru != null) 'guruName': guru['name'],
    if (guru != null) 'guruSpecialization': guru['specialization'],
  });
}

// ---------------------------------------------------------------------------
// Reference data (FK lookups) — cached for app lifetime
// ---------------------------------------------------------------------------

final kelasListProvider = FutureProvider<List<KelasModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Kelas')
      .select()
      .filter('deletedAt', 'is', null)
      .order('sortOrder');
  return (res as List).map((r) => KelasModel.fromJson(r as Map<String, dynamic>)).toList();
});

final mapelListProvider = FutureProvider<List<MataPelajaranModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('MataPelajaran')
      .select()
      .filter('deletedAt', 'is', null)
      .order('sortOrder');
  return (res as List)
      .map((r) => MataPelajaranModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

final tahunAjaranActiveProvider = FutureProvider<TahunAjaranModel?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('TahunAjaran')
      .select()
      .eq('isActive', true)
      .limit(1)
      .maybeSingle();
  if (res == null) return null;
  return TahunAjaranModel.fromJson(res as Map<String, dynamic>);
});

final semesterActiveProvider = FutureProvider<SemesterModel?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Semester')
      .select()
      .eq('isActive', true)
      .limit(1)
      .maybeSingle();
  if (res == null) return null;
  return SemesterModel.fromJson(res as Map<String, dynamic>);
});

final jenisTagihanListProvider =
    FutureProvider<List<JenisTagihanModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('JenisTagihan').select().eq('isActive', true);
  return (res as List)
      .map((r) => JenisTagihanModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Santri list — read-only monitor
// ---------------------------------------------------------------------------

final santriListProvider =
    FutureProvider<List<SantriModel>>((ref) async {
  ref.watch(realtimeRefreshTick); // re-fetch on realtime event
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Santri')
      .select('*, Kelas(*), Wali(*)')
      .filter('deletedAt', 'is', null)
      .order('name')
      .limit(200);
  return (res as List)
      .map((r) => _santriFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Absensi monitor — recent absensi with optional date filter
// ---------------------------------------------------------------------------

final absensiRecentProvider =
    FutureProvider.family<List<AbsensiModel>, DateTime?>((ref, date) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Absensi').select('*, Santri(*), Kelas(*)');
  if (date != null) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    q = q
        .gte('date', dayStart.toIso8601String())
        .lt('date', dayEnd.toIso8601String());
  }
  final res = await q.order('date', ascending: false).limit(100);
  return (res as List)
      .map((r) => _absensiFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Nilai monitor — recent nilai with optional mapel filter
// ---------------------------------------------------------------------------

final nilaiRecentProvider =
    FutureProvider.family<List<NilaiModel>, String?>((ref, mapelId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('Nilai').select('*, Santri(*), Kelas(*), MataPelajaran(*)');
  if (mapelId != null) {
    q = q.eq('mapelId', mapelId);
  }
  final res = await q.order('assessmentDate', ascending: false).limit(100);
  return (res as List)
      .map((r) => _nilaiFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Tagihan monitor — outstanding tagihan
// ---------------------------------------------------------------------------

final tagihanListProvider =
    FutureProvider.family<List<TagihanModel>, String?>((ref, statusFilter) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client
      .from('Tagihan')
      .select('*, Santri(*), Kelas(*), JenisTagihan(*)');
  if (statusFilter != null && statusFilter != 'ALL') {
    q = q.eq('status', statusFilter);
  }
  final res = await q.order('createdAt', ascending: false).limit(100);
  return (res as List)
      .map((r) => _tagihanFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Payment monitor — recent verified + pending payments
// ---------------------------------------------------------------------------

final paymentRecentProvider = FutureProvider<List<PaymentModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Payment')
      .select('*, Santri(*), Tagihan(*, JenisTagihan(*))')
      .order('paymentDate', ascending: false)
      .limit(50);
  return (res as List)
      .map((r) => _paymentFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Honor Guru monitor — recent honor records
// ---------------------------------------------------------------------------

final honorGuruListProvider =
    FutureProvider.family<List<HonorGuruModel>, String?>((ref, statusFilter) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  var q = client.from('HonorGuru').select('*, Guru(*)');
  if (statusFilter != null && statusFilter != 'ALL') {
    q = q.eq('status', statusFilter);
  }
  final res = await q.order('createdAt', ascending: false).limit(100);
  return (res as List)
      .map((r) => _honorGuruFromRow(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Laporan keuangan — transaksi kas per periode (month)
// ---------------------------------------------------------------------------

final transaksiKasByPeriodProvider =
    FutureProvider.family<List<TransaksiKasModel>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('TransaksiKas')
      .select('*, Kas(*)')
      .gte('transaksiDate', range.start.toIso8601String())
      .lt('transaksiDate', range.end.toIso8601String())
      .order('transaksiDate', ascending: false);
  return (res as List)
      .map((r) => TransaksiKasModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

final kasListProvider = FutureProvider<List<KasModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Kas')
      .select()
      .eq('isActive', true)
      .order('createdAt');
  return (res as List)
      .map((r) => KasModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Realtime refresh — global tick counter that bumps when any monitored
// table changes. Screens listen via `ref.watch(realtimeRefreshTick)`
// to trigger refetch automatically.
// ---------------------------------------------------------------------------

final realtimeRefreshTick = StateProvider<int>((_) => 0);

/// Setup realtime subscriptions untuk mobile_kepala. Panggil sekali saat
/// login berhasil (di splash screen atau dashboard init).
///
/// Subscribe ke 4 tabel: Santri, Payment, Tagihan, HonorGuru.
/// Setiap perubahan akan bump `realtimeRefreshTick` yang otomatis
/// me-refresh semua FutureProvider di atas.
void setupKepalaRealtime(WidgetRef ref) {
  final client = ref.read(supabaseClientProvider);
  const tables = ['Santri', 'Payment', 'Tagihan', 'HonorGuru'];
  for (final t in tables) {
    try {
      subscribeToTable(
        client: client,
        table: t,
        onPayload: (_) {
          // Bump tick — akan invalidate semua provider yang watch tick ini.
          ref.read(realtimeRefreshTick.notifier).state++;
        },
      );
    } catch (_) {
      // Realtime best-effort: kalau fail (RLS / network), abaikan diam-diam.
      // Provider tetap bisa di-refresh manual via pull-to-refresh.
    }
  }
}

/// Invalidate semua query providers — panggil dari pull-to-refresh atau
/// setelah signOut untuk clear cache.
void invalidateAllQueries(WidgetRef ref) {
  ref.invalidate(santriListProvider);
  ref.invalidate(absensiRecentProvider);
  ref.invalidate(nilaiRecentProvider);
  ref.invalidate(tagihanListProvider);
  ref.invalidate(paymentRecentProvider);
  ref.invalidate(honorGuruListProvider);
  ref.invalidate(transaksiKasByPeriodProvider);
  ref.invalidate(kasListProvider);
}
