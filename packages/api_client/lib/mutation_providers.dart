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

import 'query_providers.dart';
import 'supabase_rpc.dart';

// ---------------------------------------------------------------------------
// Tagihan by Santri (untuk form input pembayaran)
// ---------------------------------------------------------------------------

/// Tagihan belum lunas untuk santri tertentu. Dipakai di form input
/// pembayaran supaya user bisa pilih tagihan yang akan dibayar.
final tagihanBySantriProvider =
    FutureProvider.autoDispose.family<List<TagihanModel>, String>((ref, santriId) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Tagihan')
      .select('*, Santri(*), Kelas(*), JenisTagihan(*)')
      .eq('santriId', santriId)
      .neq('status', TagihanStatus.lunas)
      .limit(100).order('dueDate', ascending: true);
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
  String? proofUrl,
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
    if (proofUrl != null && proofUrl.isNotEmpty) 'proofUrl': proofUrl,
    if (user != null) 'recordedById': user.id,
    'paymentDate': DateTime.now().toIso8601String(),
  };

  final res = await client
      .from('Payment')
      .insert(body)
      .select('*, Santri(*), Tagihan(*, JenisTagihan(*))')
      .single();
  final payment = _paymentFromRowPublic(res);

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

/// Verifikasi pembayaran (PENDING → VERIFIED). Atomic via RPC function.
///
/// Pakai RPC `verify_payment()` (Postgres SECURITY DEFINER function) untuk
/// operasi atomic: update Payment + Kas balance + Tagihan paidAmount/status +
/// insert TransaksiKas. Tidak ada race condition.
///
/// Sebelumnya: client-side 3-step non-atomic (race condition bisa terjadi).
/// Sekarang: server-side single RPC call.
Future<void> verifyPembayaran(
  WidgetRef ref,
  String paymentId, {
  String? kasId,
}) async {
  final result = await SupabaseRpc.verifyPayment(ref,
      paymentId: paymentId, kasId: kasId);
  if (!result.success) {
    throw Exception(result.message);
  }
  // Invalidate providers supaya UI auto-refresh.
  ref.invalidate(paymentRecentProvider);
  ref.invalidate(kasListProvider);
  ref.invalidate(tagihanListProvider);
}

/// Tolak pembayaran (PENDING → REJECTED). Safe via RPC function.
Future<void> rejectPembayaran(WidgetRef ref, String paymentId) async {
  final result = await SupabaseRpc.rejectPayment(ref, paymentId: paymentId);
  if (!result.success) {
    throw Exception(result.message);
  }
  ref.invalidate(paymentRecentProvider);
}

// ---------------------------------------------------------------------------
// Transaksi Kas mutations
// ---------------------------------------------------------------------------

/// Buat transaksi kas baru (PEMASUKAN atau PENGELUARAN). Atomic via RPC function.
///
/// Pakai RPC `create_transaksi_kas()` untuk operasi atomic:
/// insert TransaksiKas + update Kas balance dalam satu transaksi.
/// Tidak ada race condition.
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

  // Call RPC create_transaksi_kas (atomic: insert + update Kas balance)
  final result = await SupabaseRpc.createTransaksiKas(
    ref,
    kasId: kasId,
    type: type,
    category: category,
    amount: amount,
    description: description,
    reference: reference,
    recordedBy: user?.id,
  );

  if (!result.success || result.transaksiId.isEmpty) {
    throw Exception('Gagal membuat transaksi kas');
  }

  // Fetch the created record for return
  final res = await client
      .from('TransaksiKas')
      .select('*, Kas(*)')
      .eq('id', result.transaksiId)
      .single();
  final transaksi = _transaksiFromRowPublic(res);

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
    FutureProvider.autoDispose.family<LaporanKeuangan, ({int month, int year})>(
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
      .limit(100).order('transaksiDate', ascending: false);

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
/// Update honor guru status. Atomic via RPC function.
///
/// Pakai RPC `update_honor_guru_status()` untuk operasi atomic:
/// update HonorGuru status + create TransaksiKas (jika DIBAYARKAN) +
/// update Kas balance. Tidak ada race condition.
///
/// Sebelumnya: client-side multi-step non-atomic.
/// Sekarang: server-side single RPC call.
Future<void> updateHonorGuruStatus(
  WidgetRef ref,
  String honorId,
  String newStatus, {
  String? kasId,
}) async {
  final result = await SupabaseRpc.updateHonorGuruStatus(
    ref,
    honorId: honorId,
    newStatus: newStatus,
    kasId: kasId,
  );

  if (!result.success) {
    throw Exception(result.message);
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
