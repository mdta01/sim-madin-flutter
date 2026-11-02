// ============================================================================
// SIM MADIN — Mutation Providers (Phase 3 — mobile_bendahara)
// ============================================================================
// Riverpod providers untuk MUTATION (POST/PUT/PATCH/DELETE) ke Supabase.
//
// Pattern yang dipakai:
//   - Provider expose AsyncNotifier/Notifier yang wrap Supabase call.
//   - Setelah mutasi sukses, invalidate dependent read providers supaya
//     UI auto-refresh.
//   - Tidak ada optimistic update dulu (data keuangan sensitif, kalau
//     gagal revert bisa rumit). Pakai loading state saja.
//
// Catatan: Bulk transaction (multi-row insert) di Phase 3 masih sederhana
// (single-row per call). Kalau nanti butuh bulk (generate tagihan massal
// dari admin desktop Phase 6), bisa pakai Supabase `insert(list)`.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'query_providers.dart';

// ---------------------------------------------------------------------------
// Tagihan by Santri (untuk form input pembayaran)
// ---------------------------------------------------------------------------

/// Tagihan belum lunas untuk santri tertentu. Dipakai di form input
/// pembayaran supaya user bisa pilih tagihan yang akan dibayar.
final tagihanBySantriProvider =
    FutureProvider.family<List<TagihanModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Tagihan')
      .select('*, Santri(*), Kelas(*), JenisTagihan(*)')
      .eq('santriId', santriId)
      .neq('status', TagihanStatus.lunas)
      .order('dueDate', ascending: true);
  return (res as List)
      .map((r) => _tagihanFromRowPublic(r as Map<String, dynamic>))
      .toList();
});

// Re-export _tagihanFromRow dari query_providers.dart (private di sana).
// Untuk simplicity, kita redefine publik di sini.
TagihanModel _tagihanFromRowPublic(Map<String, dynamic> row) {
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

// ---------------------------------------------------------------------------
// Pembayaran mutations
// ---------------------------------------------------------------------------

/// Result pembayaran create — berisi payment yang baru dibuat + invoiceNo.
class PembayaranCreateResult {
  const PembayaranCreateResult({required this.payment});
  final PaymentModel payment;
}

/// Input pembayaran baru. Catatan:
///   - `tagihanId` nullable: bisa bayar tanpa tagihan (donasi/umum).
///   - Server akan auto-generate `invoiceNo` (sequence DB).
///   - Setelah insert, server-side trigger bisa update `paidAmount` di
///     tagihan terkait (kalau ada). Di sini kita invalidate saja.
Future<PembayaranCreateResult> createPembayaran(
  WidgetRef ref, {
  required String santriId,
  String? tagihanId,
  required double amount,
  required String paymentMethod,
  String? note,
  String? kasId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final user = client.auth.currentUser;
  final body = <String, dynamic>{
    'santriId': santriId,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'status': PaymentStatus.pending, // default butuh verifikasi
    if (tagihanId != null) 'tagihanId': tagihanId,
    if (note != null && note.isNotEmpty) 'note': note,
    if (kasId != null) 'kasId': kasId,
    if (user != null) 'recordedById': user.id,
    'paymentDate': DateTime.now().toIso8601String(),
  };

  final res = await client
      .from('Payment')
      .insert(body)
      .select('*, Santri(*), Tagihan(*, JenisTagihan(*))')
      .single();
  final payment = _paymentFromRowPublic(res as Map<String, dynamic>);

  // Invalidate read providers supaya UI refresh.
  ref.invalidate(paymentRecentProvider);
  ref.invalidate(tagihanListProvider);
  ref.invalidate(tagihanBySantriProvider);

  return PembayaranCreateResult(payment: payment);
}

PaymentModel _paymentFromRowPublic(Map<String, dynamic> row) {
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

/// Verifikasi pembayaran (PENDING → VERIFIED). Update status + link ke kas.
/// Setelah verify, server trigger seharusnya update balance kas + paidAmount
/// tagihan. Di sini kita invalidate saja.
Future<void> verifyPembayaran(
  WidgetRef ref,
  String paymentId, {
  String? kasId,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('Payment').update({
    'status': PaymentStatus.verified,
    if (kasId != null && kasId.isNotEmpty) 'kasId': kasId,
  }).eq('id', paymentId);

  ref.invalidate(paymentRecentProvider);
  ref.invalidate(kasListProvider);
  ref.invalidate(tagihanListProvider);
}

/// Tolak pembayaran (PENDING → REJECTED).
Future<void> rejectPembayaran(WidgetRef ref, String paymentId) async {
  final client = ref.read(supabaseClientProvider);
  await client
      .from('Payment')
      .update({'status': PaymentStatus.rejected}).eq('id', paymentId);

  ref.invalidate(paymentRecentProvider);
}

// ---------------------------------------------------------------------------
// Transaksi Kas mutations
// ---------------------------------------------------------------------------

/// Buat transaksi kas baru (PEMASUKAN atau PENGELUARAN).
///
/// Catatan: Update balance kas manual di sini (read current balance, add/sub,
/// write back). Server-side trigger akan handle ini di Phase 6+ production,
/// untuk sekarang optimistic di client dulu.
Future<TransaksiKasModel> createTransaksiKas(
  WidgetRef ref, {
  required String kasId,
  required String type, // TransaksiKasType.*
  required String category,
  required double amount,
  required String description,
  String? reference,
}) async {
  final client = ref.read(supabaseClientProvider);
  final user = client.auth.currentUser;

  // Insert transaksi
  final body = <String, dynamic>{
    'kasId': kasId,
    'type': type,
    'category': category,
    'amount': amount,
    'description': description,
    if (reference != null && reference.isNotEmpty) 'reference': reference,
    if (user != null) 'recordedById': user.id,
    'transaksiDate': DateTime.now().toIso8601String(),
  };
  final res = await client
      .from('TransaksiKas')
      .insert(body)
      .select('*, Kas(*)')
      .single();
  final transaksi = _transaksiFromRowPublic(res as Map<String, dynamic>);

  // Update balance kas (delta = +amount untuk pemasukan, -amount untuk pengeluaran)
  final delta = type == TransaksiKasType.pemasukan ? amount : -amount;
  await _updateKasBalance(client, kasId, delta);

  ref.invalidate(kasListProvider);
  ref.invalidate(transaksiKasByPeriodProvider);

  return transaksi;
}

TransaksiKasModel _transaksiFromRowPublic(Map<String, dynamic> row) {
  final kas = (row['Kas'] ?? row['kas']) as Map<String, dynamic>?;
  return TransaksiKasModel.fromJson({
    ...row,
    if (kas != null) 'kasName': kas['name'],
    if (kas != null) 'kasCode': kas['code'],
  });
}

Future<void> _updateKasBalance(
  SupabaseClient client,
  String kasId,
  double delta,
) async {
  // Read current balance, compute new, write back.
  // Catatan: Tidak atomic — race condition bisa terjadi kalau 2 transaksi
  // bersamaan. Untuk Phase 3 (single bendahara per madrasah) acceptable.
  // Phase 6+ production: pakai Postgres function `update_kas_balance()`
  // yang pakai SELECT ... FOR UPDATE.
  final current = await client
      .from('Kas')
      .select('balance')
      .eq('id', kasId)
      .single();
  final currentBalance =
      ((current['balance'] as num?)?.toDouble() ?? 0.0);
  final newBalance = currentBalance + delta;
  await client.from('Kas').update({'balance': newBalance}).eq('id', kasId);
}

// ---------------------------------------------------------------------------
// Laporan Keuangan aggregate (compute-on-read)
// ---------------------------------------------------------------------------

/// Laporan keuangan per bulan. Mengembalikan:
///   - pemasukan total
///   - pengeluaran total
///   - pemasukan per kategori
///   - pengeluaran per kategori
///   - list transaksi periode
class LaporanKeuangan {
  const LaporanKeuangan({
    required this.month,
    required this.year,
    required this.pemasukan,
    required this.pengeluaran,
    required this.pemasukanPerKategori,
    required this.pengeluaranPerKategori,
    required this.transaksi,
  });

  final int month;
  final int year;
  final double pemasukan;
  final double pengeluaran;
  final Map<String, double> pemasukanPerKategori;
  final Map<String, double> pengeluaranPerKategori;
  final List<TransaksiKasModel> transaksi;

  double get saldo => pemasukan - pengeluaran;
}

final laporanKeuanganProvider =
    FutureProvider.family<LaporanKeuangan, ({int month, int year})>(
        (ref, range) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);

  // Range: awal bulan → akhir bulan
  final start = DateTime(range.year, range.month, 1);
  final end = DateTime(range.year, range.month + 1, 1);

  final res = await client
      .from('TransaksiKas')
      .select('*, Kas(*)')
      .gte('transaksiDate', start.toIso8601String())
      .lt('transaksiDate', end.toIso8601String())
      .order('transaksiDate', ascending: false);

  final list = (res as List)
      .map((r) => _transaksiFromRowPublic(r as Map<String, dynamic>))
      .toList();

  // Compute aggregates
  final pemasukan = list
      .where((t) => t.type == TransaksiKasType.pemasukan)
      .fold<double>(0, (s, t) => s + t.amount);
  final pengeluaran = list
      .where((t) => t.type == TransaksiKasType.pengeluaran)
      .fold<double>(0, (s, t) => s + t.amount);

  final pemasukanPerKategori = <String, double>{};
  final pengeluaranPerKategori = <String, double>{};
  for (final t in list) {
    final cat = TransaksiKasCategory.label(t.category);
    if (t.type == TransaksiKasType.pemasukan) {
      pemasukanPerKategori[cat] =
          (pemasukanPerKategori[cat] ?? 0) + t.amount;
    } else {
      pengeluaranPerKategori[cat] =
          (pengeluaranPerKategori[cat] ?? 0) + t.amount;
    }
  }

  return LaporanKeuangan(
    month: range.month,
    year: range.year,
    pemasukan: pemasukan,
    pengeluaran: pengeluaran,
    pemasukanPerKategori: pemasukanPerKategori,
    pengeluaranPerKategori: pengeluaranPerKategori,
    transaksi: list,
  );
});

// ---------------------------------------------------------------------------
// Honor Guru approve / bayar mutations
// ---------------------------------------------------------------------------

/// Set status honor guru: DRAFT → DISETUJUI → DIBAYARKAN.
Future<void> updateHonorGuruStatus(
  WidgetRef ref,
  String honorId,
  String newStatus, {
  String? kasId,
}) async {
  final client = ref.read(supabaseClientProvider);
  final body = <String, dynamic>{
    'status': newStatus,
    if (newStatus == HonorGuruStatus.dibayarkan)
      'paidAt': DateTime.now().toIso8601String(),
    if (kasId != null && kasId.isNotEmpty) 'kasId': kasId,
  };
  await client.from('HonorGuru').update(body).eq('id', honorId);

  // Jika dibayarkan, kurangi saldo kas.
  if (newStatus == HonorGuruStatus.dibayarkan && kasId != null) {
    // Baca total honor dulu
    final honorRes = await client
        .from('HonorGuru')
        .select('totalHonor, honorMengajar, insentif, tunjangan, potongan')
        .eq('id', honorId)
        .single();
    final h = honorRes as Map<String, dynamic>;
    final total = (h['totalHonor'] as num?)?.toDouble() ??
        ((h['honorMengajar'] as num?)?.toDouble() ?? 0) +
            ((h['insentif'] as num?)?.toDouble() ?? 0) +
            ((h['tunjangan'] as num?)?.toDouble() ?? 0) -
            ((h['potongan'] as num?)?.toDouble() ?? 0);
    await _updateKasBalance(client, kasId, -total);
  }

  ref.invalidate(honorGuruListProvider);
  ref.invalidate(kasListProvider);
}

/// Generate honor guru bulk untuk semua guru aktif di periode tertentu.
/// Catatan: ini admin-level operation, dipanggil dari admin desktop Phase 6.
/// Disediakan di sini untuk completeness.
Future<int> generateHonorGuruBulk(
  WidgetRef ref, {
  required String tahunAjaranId,
  required String semesterId,
  required String periode, // "2025-10"
  required String periodeLabel, // "Oktober 2025"
  required List<String> guruIds,
  double defaultHonorMengajar = 0,
  double defaultInsentif = 0,
  double defaultTunjangan = 0,
  double defaultPotongan = 0,
}) async {
  final client = ref.read(supabaseClientProvider);
  final rows = guruIds.map((guruId) {
    final total = defaultHonorMengajar +
        defaultInsentif +
        defaultTunjangan -
        defaultPotongan;
    return {
      'tahunAjaranId': tahunAjaranId,
      'semesterId': semesterId,
      'guruId': guruId,
      'periode': periode,
      'periodeLabel': periodeLabel,
      'honorMengajar': defaultHonorMengajar,
      'insentif': defaultInsentif,
      'tunjangan': defaultTunjangan,
      'potongan': defaultPotongan,
      'totalHonor': total,
      'status': HonorGuruStatus.draft,
    };
  }).toList();

  final res = await client.from('HonorGuru').insert(rows).select();
  ref.invalidate(honorGuruListProvider);
  return (res as List).length;
}
