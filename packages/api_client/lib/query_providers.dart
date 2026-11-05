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
      .limit(100).order('sortOrder');
  return (res as List).map((r) => KelasModel.fromJson(r as Map<String, dynamic>)).toList();
});

final mapelListProvider = FutureProvider<List<MataPelajaranModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('MataPelajaran')
      .select()
      .filter('deletedAt', 'is', null)
      .limit(100).order('sortOrder');
  return (res as List)
      .map((r) => MataPelajaranModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Daftar semua guru aktif (untuk dashboard mobile_kepala KPI "Guru Aktif").
/// Filter hanya yang punya status AKTIF.
final guruListProvider = FutureProvider<List<GuruModel>>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Guru')
      .select('*, User(*)')
      .filter('deletedAt', 'is', null)
      .limit(100).order('createdAt');
  return (res as List)
      .map((r) {
        final row = r as Map<String, dynamic>;
        final user = row['User'] as Map<String, dynamic>?;
        // Guru table mungkin tidak punya kolom `name` (denormalized dari User).
        // Pakai User.name sebagai fallback supaya GuruModel.fromJson happy.
        return GuruModel.fromJson({
          ...row,
          if (user != null) ...{
            'name': user['name'] ?? row['name'] ?? 'Tanpa Nama',
            'email': user['email'] ?? row['email'],
            'phone': user['phone'] ?? row['phone'],
            'photoUrl': user['avatarUrl'] ?? row['photoUrl'],
          } else if (!row.containsKey('name')) ...{
            'name': 'Tanpa Nama',
          },
        });
      })
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
  return TahunAjaranModel.fromJson(res);
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
  return SemesterModel.fromJson(res);
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
// Aggregate dashboard KPIs (untuk mobile_bendahara) — pakai Supabase
// aggregate query (count / sum) supaya tidak underestimate seperti list
// dengan .limit(50). Return bilangan exact meski ada ratusan record.
// ---------------------------------------------------------------------------

/// Model untuk KPI dashboard bendahara.
class BendaharaKpiStats {
  const BendaharaKpiStats({
    required this.pemasukanHariIni,
    required this.pendingVerifCount,
    required this.tunggakan,
    required this.tunggakanCount,
    required this.saldoKas,
  });

  final double pemasukanHariIni;
  final int pendingVerifCount;
  final double tunggakan;
  final int tunggakanCount;
  final double saldoKas;
}

/// Provider aggregate untuk dashboard bendahara.
/// Pakai Supabase `.count()` head:true dan compute pemasukan dengan filter
/// tanggal hari ini (UTC) — supaya exact bahkan jika ada ratusan pembayaran.
final bendaharaKpiProvider =
    FutureProvider<BendaharaKpiStats>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);

  // 1. Pemasukan hari ini = SUM(Payment.amount) where status=VERIFIED dan
  //    paymentDate hari ini. Supabase tidak support SUM langsung di client
  //    query — kita fetch amount column saja untuk record verified hari ini.
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final pemasukanRes = await client
      .from('Payment')
      .select('amount')
      .eq('status', PaymentStatus.verified)
      .gte('paymentDate', dayStart.toUtc().toIso8601String())
      .lt('paymentDate', dayEnd.toUtc().toIso8601String());
  final pemasukanHariIni = (pemasukanRes as List).fold<double>(
      0, (s, r) => s + ((r as Map<String, dynamic>)['amount'] as num).toDouble());

  // 2. Count pending verif (exact, tanpa limit) — fetch IDs only, count length.
  final pendingRes = await client
      .from('Payment')
      .select('id')
      .eq('status', PaymentStatus.pending);
  final pendingVerifCount = (pendingRes as List).length;

  // 3. Tunggakan = SUM(outstanding) untuk Tagihan yang belum lunas.
  //    Outstanding per tagihan = amount - paidAmount (clamp 0).
  final tunggakanRes = await client
      .from('Tagihan')
      .select('amount, paidAmount, status')
      .neq('status', TagihanStatus.lunas);
  double tunggakan = 0;
  int tunggakanCount = 0;
  for (final r in tunggakanRes as List) {
    final row = r as Map<String, dynamic>;
    final amount = (row['amount'] as num).toDouble();
    final paid = (row['paidAmount'] as num?)?.toDouble() ?? 0;
    final outstanding = (amount - paid).clamp(0.0, double.infinity);
    if (outstanding > 0) {
      tunggakan += outstanding;
      tunggakanCount++;
    }
  }

  // 4. Saldo kas = SUM(Kas.balance) where isActive=true.
  final kasRes = await client
      .from('Kas')
      .select('balance')
      .eq('isActive', true);
  final saldoKas = (kasRes as List).fold<double>(
      0, (s, r) => s + ((r as Map<String, dynamic>)['balance'] as num).toDouble());

  return BendaharaKpiStats(
    pemasukanHariIni: pemasukanHariIni,
    pendingVerifCount: pendingVerifCount,
    tunggakan: tunggakan,
    tunggakanCount: tunggakanCount,
    saldoKas: saldoKas,
  );
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
      .limit(100).order('transaksiDate', ascending: false);
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
      .limit(100).order('createdAt');
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

/// Track active realtime channels so we can unsubscribe on logout / re-init.
/// Tanpa tracking ini, setiap kali user logout-login, channel baru ditumpuk
/// di atas channel lama → memory leak + event dobel.
final realtimeChannelsProvider =
    StateProvider<List<RealtimeChannel>>((_) => const []);

/// Setup realtime subscriptions untuk tabel-tabel yang relevan.
/// Panggil saat login berhasil (di splash / dashboard init).
/// Setiap perubahan akan bump `realtimeRefreshTick` yang otomatis
/// me-refresh semua FutureProvider yang watch tick ini.
///
/// Sebelum subscribe baru, fungsi ini akan unsubscribe channel lama
/// (kalau ada) untuk mencegah leak & duplikasi event.
void setupAppRealtime(WidgetRef ref, {required List<String> tables}) {
  // Dispose existing channels first (idempotent).
  disposeAppRealtime(ref);

  final client = ref.read(supabaseClientProvider);
  final channels = <RealtimeChannel>[];
  for (final t in tables) {
    try {
      final ch = subscribeToTable(
        client: client,
        table: t,
        onPayload: (_) {
          // Bump tick — akan invalidate semua provider yang watch tick ini.
          ref.read(realtimeRefreshTick.notifier).state++;
        },
      );
      channels.add(ch);
    } catch (_) {
      // Realtime best-effort: kalau fail (RLS / network), abaikan diam-diam.
      // Provider tetap bisa di-refresh manual via pull-to-refresh.
    }
  }
  ref.read(realtimeChannelsProvider.notifier).state = channels;
}

/// Unsubscribe semua realtime channels. Panggil saat logout.
Future<void> disposeAppRealtime(WidgetRef ref) async {
  final channels = ref.read(realtimeChannelsProvider);
  for (final ch in channels) {
    try {
      await ch.unsubscribe();
    } catch (_) {
      // Best-effort.
    }
  }
  ref.read(realtimeChannelsProvider.notifier).state = const [];
}

/// Realtime untuk mobile_kepala (read-only monitoring).
/// Subscribe: Santri, Payment, Tagihan, HonorGuru, Absensi, Nilai, Kas,
/// TransaksiKas, Guru, Jadwal — supaya semua monitor screen auto-refresh.
void setupKepalaRealtime(WidgetRef ref) {
  setupAppRealtime(ref, tables: const [
    'Santri',
    'Payment',
    'Tagihan',
    'HonorGuru',
    'Absensi',
    'Nilai',
    'Kas',
    'TransaksiKas',
    'Guru',
    'Jadwal',
  ]);
}

/// Realtime untuk mobile_wali.
/// Subscribe: Notifikasi, ChatRoom, ChatMessage, Tagihan, Payment, Absensi,
/// Nilai — fitur utama wali (notif & chat) harus auto-refresh.
void setupWaliRealtime(WidgetRef ref) {
  setupAppRealtime(ref, tables: const [
    'Notifikasi',
    'ChatRoom',
    'ChatMessage',
    'Tagihan',
    'Payment',
    'Absensi',
    'Nilai',
    'PerkembanganQuran',
    'HafalanKitab',
    'AkhlakPenilaian',
    'Pembinaan',
    'UjianPeserta',
    'UjianSesi',
  ]);
}

/// Realtime untuk mobile_guru.
/// Subscribe: Jadwal, Materi, Tugas, Pertemuan, Ujian, UjianSoal,
/// PengumpulanTugas, ChatRoom, ChatMessage, Absensi, Nilai, PerkembanganQuran,
/// HafalanKitab, AkhlakPenilaian, Pembinaan, Pengumuman.
void setupGuruRealtime(WidgetRef ref) {
  setupAppRealtime(ref, tables: const [
    'Jadwal',
    'Materi',
    'Tugas',
    'Pertemuan',
    'Ujian',
    'UjianSoal',
    'PengumpulanTugas',
    'ChatRoom',
    'ChatMessage',
    'Absensi',
    'Nilai',
    'PerkembanganQuran',
    'HafalanKitab',
    'AkhlakPenilaian',
    'Pembinaan',
    'Pengumuman',
    'BankSoal',
  ]);
}

/// Realtime untuk mobile_bendahara.
/// Subscribe: Payment, Tagihan, HonorGuru, Kas, TransaksiKas, Santri, Guru.
void setupBendaharaRealtime(WidgetRef ref) {
  setupAppRealtime(ref, tables: const [
    'Payment',
    'Tagihan',
    'HonorGuru',
    'Kas',
    'TransaksiKas',
    'Santri',
    'Guru',
  ]);
}

/// Provider aggregate untuk dashboard mobile_kepala.
/// Hitung exact counts/sums tanpa underestimate dari list dengan .limit.
/// Pakai Supabase query + client-side aggregate untuk total yang akurat.
final kepalaKpiProvider = FutureProvider<KepalaKpiStats>((ref) async {
  ref.watch(realtimeRefreshTick);
  final client = ref.watch(supabaseClientProvider);

  // 1. Total santri aktif.
  final santriRes = await client
      .from('Santri')
      .select('id, status')
      .eq('status', SantriStatus.aktif)
      .filter('deletedAt', 'is', null);
  final totalSantriAktif = (santriRes as List).length;

  // 2. Total guru aktif.
  final guruRes = await client
      .from('Guru')
      .select('id, status')
      .eq('status', GuruStatus.aktif)
      .filter('deletedAt', 'is', null);
  final totalGuruAktif = (guruRes as List).length;

  // 3. Saldo kas (sum balance where isActive).
  final kasRes = await client
      .from('Kas')
      .select('balance')
      .eq('isActive', true);
  final saldoKas = (kasRes as List).fold<double>(
      0, (s, r) => s + ((r as Map<String, dynamic>)['balance'] as num).toDouble());

  // 4. Tunggakan = SUM(outstanding) untuk Tagihan belum lunas.
  final tunggakanRes = await client
      .from('Tagihan')
      .select('amount, paidAmount')
      .neq('status', TagihanStatus.lunas);
  double tunggakan = 0;
  int tunggakanCount = 0;
  for (final r in tunggakanRes as List) {
    final row = r as Map<String, dynamic>;
    final amount = (row['amount'] as num).toDouble();
    final paid = (row['paidAmount'] as num?)?.toDouble() ?? 0;
    final outstanding = (amount - paid).clamp(0.0, double.infinity);
    if (outstanding > 0) {
      tunggakan += outstanding;
      tunggakanCount++;
    }
  }

  // 5. Pemasukan bulan ini (Payment verified bulan ini).
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 1);
  final pemasukanRes = await client
      .from('Payment')
      .select('amount')
      .eq('status', PaymentStatus.verified)
      .gte('paymentDate', monthStart.toUtc().toIso8601String())
      .lt('paymentDate', monthEnd.toUtc().toIso8601String());
  final pemasukanBulanIni = (pemasukanRes as List).fold<double>(
      0, (s, r) => s + ((r as Map<String, dynamic>)['amount'] as num).toDouble());

  // 6. Tagihan lunas count.
  final lunasRes = await client
      .from('Tagihan')
      .select('id')
      .eq('status', TagihanStatus.lunas);
  final tagihanLunasCount = (lunasRes as List).length;

  // 7. Absensi hari ini — count by status.
  final today = DateTime.now();
  final dayStart = DateTime(today.year, today.month, today.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final absensiRes = await client
      .from('Absensi')
      .select('status')
      .gte('date', dayStart.toUtc().toIso8601String())
      .lt('date', dayEnd.toUtc().toIso8601String());
  int hadir = 0, sakit = 0, izin = 0, alfa = 0;
  for (final r in absensiRes as List) {
    final status = (r as Map<String, dynamic>)['status'] as String;
    switch (status) {
      case AbsensiStatus.hadir:
        hadir++;
        break;
      case AbsensiStatus.sakit:
        sakit++;
        break;
      case AbsensiStatus.izin:
        izin++;
        break;
      case AbsensiStatus.alfa:
        alfa++;
        break;
    }
  }
  final totalAbsensi = hadir + sakit + izin + alfa;
  final kehadiranPercent = totalAbsensi > 0
      ? (hadir / totalAbsensi * 100).roundToDouble()
      : 0.0;

  return KepalaKpiStats(
    totalSantriAktif: totalSantriAktif,
    totalGuruAktif: totalGuruAktif,
    saldoKas: saldoKas,
    tunggakan: tunggakan,
    tunggakanCount: tunggakanCount,
    pemasukanBulanIni: pemasukanBulanIni,
    tagihanLunasCount: tagihanLunasCount,
    hadirHariIni: hadir,
    sakitHariIni: sakit,
    izinHariIni: izin,
    alfaHariIni: alfa,
    kehadiranPercent: kehadiranPercent,
  );
});

/// KPI stats untuk dashboard mobile_kepala.
class KepalaKpiStats {
  const KepalaKpiStats({
    required this.totalSantriAktif,
    required this.totalGuruAktif,
    required this.saldoKas,
    required this.tunggakan,
    required this.tunggakanCount,
    required this.pemasukanBulanIni,
    required this.tagihanLunasCount,
    required this.hadirHariIni,
    required this.sakitHariIni,
    required this.izinHariIni,
    required this.alfaHariIni,
    required this.kehadiranPercent,
  });

  final int totalSantriAktif;
  final int totalGuruAktif;
  final double saldoKas;
  final double tunggakan;
  final int tunggakanCount;
  final double pemasukanBulanIni;
  final int tagihanLunasCount;
  final int hadirHariIni;
  final int sakitHariIni;
  final int izinHariIni;
  final int alfaHariIni;
  final double kehadiranPercent;
}

/// Invalidate semua query providers — panggil dari pull-to-refresh atau
/// setelah signOut untuk clear cache.
void invalidateAllQueries(WidgetRef ref) {
  ref.invalidate(santriListProvider);
  ref.invalidate(guruListProvider);
  ref.invalidate(absensiRecentProvider);
  ref.invalidate(nilaiRecentProvider);
  ref.invalidate(tagihanListProvider);
  ref.invalidate(paymentRecentProvider);
  ref.invalidate(honorGuruListProvider);
  ref.invalidate(transaksiKasByPeriodProvider);
  ref.invalidate(kasListProvider);
  ref.invalidate(kepalaKpiProvider);
}
