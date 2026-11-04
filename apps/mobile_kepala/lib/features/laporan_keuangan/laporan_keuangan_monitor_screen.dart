// Laporan Keuangan monitor — read-only. Transaksi kas per periode.
// Filter by month (default bulan ini) + chart distribusi pemasukan vs pengeluaran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_views.dart';

class LaporanKeuanganMonitorScreen extends ConsumerStatefulWidget {
  const LaporanKeuanganMonitorScreen({super.key});

  @override
  ConsumerState<LaporanKeuanganMonitorScreen> createState() =>
      _LaporanKeuanganMonitorScreenState();
}

class _LaporanKeuanganMonitorScreenState
    extends ConsumerState<LaporanKeuanganMonitorScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  ({DateTime start, DateTime end}) get _range {
    final start = _selectedMonth;
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    return (start: start, end: end);
  }

  String get _monthLabel {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[_selectedMonth.month]} ${_selectedMonth.year}';
  }

  /// Cek apakah next month button boleh dipakai (tidak boleh lewat bulan ini).
  /// Sebelumnya pakai `next.isBefore(DateTime(now.year, now.month + 2, 1))`
  /// yang allow bulan depan (kosong). Sekarang strict: hanya sampai bulan ini.
  bool _canGoNext() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    return _selectedMonth.isBefore(currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(transaksiKasByPeriodProvider(_range));
    final kasAsync = ref.watch(kasListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                    _selectedMonth.year, _selectedMonth.month - 1, 1);
              });
            },
          ),
          Center(
            child: Text(
              _monthLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // Disable jika sudah di bulan ini (tidak boleh ke masa depan).
            onPressed: _canGoNext()
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year,
                          _selectedMonth.month + 1, 1);
                    });
                  }
                : null,
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(transaksiKasByPeriodProvider(_range)),
        ),
        data: (list) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(transaksiKasByPeriodProvider(_range));
              ref.invalidate(kasListProvider);
              await ref.read(transaksiKasByPeriodProvider(_range).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _KasBalanceSection(kasAsync: kasAsync),
                const SizedBox(height: AppSpacing.md),
                _PemasukanPengeluaranSection(list: list),
                const SizedBox(height: AppSpacing.md),
                _TransaksiListSection(list: list),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KasBalanceSection extends StatelessWidget {
  const _KasBalanceSection({required this.kasAsync});

  final AsyncValue<List<KasModel>> kasAsync;

  @override
  Widget build(BuildContext context) {
    return kasAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Text('Error kas: $e'),
      data: (list) {
        final totalSaldo =
            list.fold<double>(0, (s, k) => s + k.balance);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance,
                  color: AppColors.white, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saldo Kas',
                      style: TextStyle(fontSize: 12, color: AppColors.white),
                    ),
                    Text(
                      formatRupiah(totalSaldo),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${list.length} Kas',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PemasukanPengeluaranSection extends StatelessWidget {
  const _PemasukanPengeluaranSection({required this.list});

  final List<TransaksiKasModel> list;

  @override
  Widget build(BuildContext context) {
    final pemasukan = list
        .where((t) => t.type == TransaksiKasType.pemasukan)
        .fold<double>(0, (s, t) => s + t.amount);
    final pengeluaran = list
        .where((t) => t.type == TransaksiKasType.pengeluaran)
        .fold<double>(0, (s, t) => s + t.amount);
    final net = pemasukan - pengeluaran;
    // Hitung max val untuk skala bar — supaya bar pemasukan/pengeluaran
    // proporsional. Min 1 supaya tidak divide by zero.
    final maxVal = [pemasukan, pengeluaran, 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pemasukan vs Pengeluaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BarComparison(
            label: 'Pemasukan',
            value: pemasukan,
            maxVal: maxVal,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xs),
          _BarComparison(
            label: 'Pengeluaran',
            value: pengeluaran,
            maxVal: maxVal,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Selisih (Net)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                formatRupiah(net),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarComparison extends StatelessWidget {
  const _BarComparison({
    required this.label,
    required this.value,
    required this.maxVal,
    required this.color,
  });

  final String label;
  final double value;
  final double maxVal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Rasio bar width = value / maxVal (clamp 0..1 supaya tidak overflow).
    final ratio = maxVal > 0 ? (value / maxVal).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            formatRupiah(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _TransaksiListSection extends StatelessWidget {
  const _TransaksiListSection({required this.list});

  final List<TransaksiKasModel> list;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: const EmptyState(
          title: 'Belum ada transaksi',
          subtitle: 'Tidak ada transaksi kas pada periode ini.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Transaksi (${list.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...list.map((t) => _TransaksiCard(transaksi: t)),
      ],
    );
  }
}

class _TransaksiCard extends StatelessWidget {
  const _TransaksiCard({required this.transaksi});

  final TransaksiKasModel transaksi;

  @override
  Widget build(BuildContext context) {
    final isPemasukan = transaksi.type == TransaksiKasType.pemasukan;
    final typeColor = isPemasukan ? AppColors.success : AppColors.danger;
    final typeBg = isPemasukan
        ? AppColors.successLight
        : AppColors.dangerLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isPemasukan
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaksi.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${TransaksiKasCategory.label(transaksi.category)} • ${transaksi.kasName ?? transaksi.kasCode ?? '-'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(transaksi.transaksiDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPemasukan ? '+' : '-'}${formatRupiah(transaksi.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
