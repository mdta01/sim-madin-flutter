// Laporan Keuangan screen — chart + filter periode (bulan) + export PDF.
// Pakai laporanKeuanganProvider (compute-on-read aggregate).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../services/pdf_service.dart';
import '../../widgets/feedback_widgets.dart';

class LaporanKeuanganScreen extends ConsumerStatefulWidget {
  const LaporanKeuanganScreen({super.key});

  @override
  ConsumerState<LaporanKeuanganScreen> createState() =>
      _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState
    extends ConsumerState<LaporanKeuanganScreen> {
  late int _month;
  late int _year;

  static const _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  ({int month, int year}) get _range => (month: _month, year: _year);

  String get _monthLabel => '${_months[_month]} $_year';

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = _month == 12 ? 1 : _month + 1;
    final nextYear = _month == 12 ? _year + 1 : _year;
    // Strict: tidak boleh lewat bulan ini (sebelumnya allow next month+1).
    if (nextYear > now.year ||
        (nextYear == now.year && nextMonth > now.month)) {
      return;
    }
    setState(() {
      _month = nextMonth;
      _year = nextYear;
    });
  }

  /// Cek apakah tombol next month boleh dipakai (disabled state).
  bool _canGoNext() {
    final now = DateTime.now();
    return _year < now.year ||
        (_year == now.year && _month < now.month);
  }

  Future<void> _exportPdf(LaporanKeuangan laporan) async {
    try {
      await PdfService.shareLaporanKeuangan(laporan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(laporanKeuanganProvider(_range));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
          ),
          Center(
            child: Text(
              _monthLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // Disable tombol jika sudah di bulan ini (tidak boleh ke masa depan).
            onPressed: _canGoNext() ? _nextMonth : null,
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: friendlyError(err),
          onRetry: () =>
              ref.invalidate(laporanKeuanganProvider(_range)),
        ),
        data: (laporan) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(laporanKeuanganProvider(_range));
              await ref.read(laporanKeuanganProvider(_range).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo ${_monthLabel}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.white),
                      ),
                      Text(
                        formatRupiah(laporan.saldo),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _Item(
                                label: 'Pemasukan',
                                value: formatRupiah(laporan.pemasukan)),
                          ),
                          Expanded(
                            child: _Item(
                                label: 'Pengeluaran',
                                value: formatRupiah(laporan.pengeluaran)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Bar comparison chart
                _BarComparisonSection(
                  pemasukan: laporan.pemasukan,
                  pengeluaran: laporan.pengeluaran,
                ),
                const SizedBox(height: AppSpacing.md),

                // Per kategori breakdown
                _KategoriSection(
                  title: 'Pemasukan per Kategori',
                  data: laporan.pemasukanPerKategori,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.md),
                _KategoriSection(
                  title: 'Pengeluaran per Kategori',
                  data: laporan.pengeluaranPerKategori,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),

                // Detail transaksi
                _TransaksiList(transaksi: laporan.transaksi),

                const SizedBox(height: AppSpacing.lg),

                // Export PDF
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdf(laporan),
                    icon: const Icon(Icons.print),
                    label: const Text('Export PDF Laporan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.white)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white)),
      ],
    );
  }
}

class _BarComparisonSection extends StatelessWidget {
  const _BarComparisonSection({
    required this.pemasukan,
    required this.pengeluaran,
  });

  final double pemasukan;
  final double pengeluaran;

  @override
  Widget build(BuildContext context) {
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
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          _Bar(
            label: 'Pemasukan',
            value: pemasukan,
            max: maxVal,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xs),
          _Bar(
            label: 'Pengeluaran',
            value: pengeluaran,
            max: maxVal,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            formatRupiah(value),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _KategoriSection extends StatelessWidget {
  const _KategoriSection({
    required this.title,
    required this.data,
    required this.color,
  });

  final String title;
  final Map<String, double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = data.values.fold<double>(0, (s, v) => s + v);

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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text(formatRupiah(total),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Belum ada data',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...sorted.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ),
                      Text(formatRupiah(e.value),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _TransaksiList extends StatelessWidget {
  const _TransaksiList({required this.transaksi});

  final List<TransaksiKasModel> transaksi;

  @override
  Widget build(BuildContext context) {
    if (transaksi.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Belum ada transaksi di periode ini.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
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
          Text(
            'Detail Transaksi (${transaksi.length})',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...transaksi.map((t) {
            final isPemasukan = t.type == TransaksiKasType.pemasukan;
            final color = isPemasukan ? AppColors.success : AppColors.danger;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isPemasukan
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${TransaksiKasCategory.label(t.category)} • ${t.kasName ?? "-"} • ${formatDate(t.transaksiDate)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isPemasukan ? "+" : "-"}${formatRupiah(t.amount)}',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
