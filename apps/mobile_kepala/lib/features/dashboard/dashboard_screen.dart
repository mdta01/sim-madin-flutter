// ============================================================================
// DashboardScreen — Bottom-tab shell untuk mobile_kepala
// ============================================================================
// Mengandung:
//   - AppBar dengan judul kontekstual + tombol logout
//   - StatefulNavigationShell sebagai body (ganti per tab)
//   - BottomNavigationBar dengan 5 tab
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:api_client/api_client.dart';

import '../../app/router.dart';
import '../../widgets/stat_card.dart';
import '../profile/profile_screen.dart' show logoutAndNavigate;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Setup realtime subscription sekali saat dashboard pertama kali dibuka.
    // Best-effort: kalau gagal (RLS/network), diabaikan diam-diam.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupKepalaRealtime(ref);
    });
  }

  Future<void> _handleLogout() async {
    await logoutAndNavigate(context, ref);
  }

  String get _title {
    final branchIndex = widget.shell.currentIndex;
    if (branchIndex < kBottomNavItems.length) {
      return 'SIM MADIN — ${kBottomNavItems[branchIndex].label}';
    }
    return 'SIM MADIN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) {
          widget.shell.goBranch(
            i,
            initialLocation: i == widget.shell.currentIndex,
          );
        },
        destinations: [
          for (final item in kBottomNavItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryLight,
        height: 64,
      ),
    );
  }
}

// ============================================================================
// DashboardHomeTab — Beranda (isi dari tab 1)
// ============================================================================
// Menampilkan:
//   1. 6 KPI cards (Total Santri, Guru Aktif, Saldo Kas, Tunggakan,
//      Pemasukan Bulan Ini, Kehadiran %)
//   2. Bar chart distribusi status tagihan
//   3. Line chart tren pemasukan 7 hari terakhir
//   4. Absensi hari ini (4 cards: Hadir/Sakit/Izin/Alfa)
//   5. Quick link ke monitor screens (card menu)
//
// Data di-fetch via providers di packages/api_client/query_providers.dart.
// Realtime auto-refresh via _realtimeRefreshTick yang sudah di-watch provider.
// ============================================================================

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final santriAsync = ref.watch(santriListProvider);
    final paymentsAsync = ref.watch(paymentRecentProvider);
    final tagihanAsync = ref.watch(tagihanListProvider(null));
    final kasAsync = ref.watch(kasListProvider);
    final absensiAsync = ref.watch(absensiRecentProvider(DateTime.now()));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(santriListProvider);
        ref.invalidate(paymentRecentProvider);
        ref.invalidate(tagihanListProvider);
        ref.invalidate(kasListProvider);
        ref.invalidate(absensiRecentProvider);
        // Tunggu sampai minimal satu provider selesai supaya indicator dismiss.
        await ref.read(santriListProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // === KPI Section ===
          _KpiSection(
            santriAsync: santriAsync,
            paymentsAsync: paymentsAsync,
            tagihanAsync: tagihanAsync,
            kasAsync: kasAsync,
          ),
          const SizedBox(height: AppSpacing.lg),

          // === Tagihan distribution chart ===
          _TagihanDistributionSection(tagihanAsync: tagihanAsync),
          const SizedBox(height: AppSpacing.lg),

          // === Income trend chart (7 hari terakhir) ===
          _IncomeTrendSection(paymentsAsync: paymentsAsync),
          const SizedBox(height: AppSpacing.lg),

          // === Absensi hari ini ===
          _AbsensiTodaySection(absensiAsync: absensiAsync),
          const SizedBox(height: AppSpacing.lg),

          // === Quick menu monitor screens ===
          _QuickMenuSection(context: context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({
    required this.santriAsync,
    required this.paymentsAsync,
    required this.tagihanAsync,
    required this.kasAsync,
  });

  final AsyncValue<List<SantriModel>> santriAsync;
  final AsyncValue<List<PaymentModel>> paymentsAsync;
  final AsyncValue<List<TagihanModel>> tagihanAsync;
  final AsyncValue<List<KasModel>> kasAsync;

  @override
  Widget build(BuildContext context) {
    // Aggregate dari masing-masing async value.
    final totalSantri = santriAsync.maybeWhen(
      data: (list) => list.where((s) => s.status == SantriStatus.aktif).length,
      orElse: () => 0,
    );
    final totalGuruAktif = 0; // Phase 2: tidak ada guru list provider (read-only mobile_kepala tidak butuh)
    final saldoKas = kasAsync.maybeWhen(
      data: (list) => list.fold<double>(0, (s, k) => s + k.balance),
      orElse: () => 0,
    );
    final tunggakan = tagihanAsync.maybeWhen(
      data: (list) => list
          .where((t) => t.status != TagihanStatus.lunas)
          .fold<double>(0, (s, t) => s + tagihanOutstanding(t)),
      orElse: () => 0,
    );
    final pemasukanBulanIni = paymentsAsync.maybeWhen(
      data: (list) {
        final now = DateTime.now();
        return list
            .where((p) =>
                p.status == PaymentStatus.verified &&
                p.paymentDate.year == now.year &&
                p.paymentDate.month == now.month)
            .fold<double>(0, (s, p) => s + p.amount);
      },
      orElse: () => 0,
    );
    final tagihanLunas = tagihanAsync.maybeWhen(
      data: (list) => list.where((t) => t.status == TagihanStatus.lunas).length,
      orElse: () => 0,
    );

    final isLoading = santriAsync.isLoading ||
        paymentsAsync.isLoading ||
        tagihanAsync.isLoading ||
        kasAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              label: 'Total Santri Aktif',
              value: '$totalSantri',
              icon: Icons.people,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            StatCard(
              label: 'Guru Aktif',
              value: '$totalGuruAktif',
              subtitle: 'Data belum tersedia',
              icon: Icons.school,
              color: AppColors.primary,
              bgColor: AppColors.primaryLight,
            ),
            StatCard(
              label: 'Saldo Kas',
              value: formatRupiah(saldoKas),
              icon: Icons.account_balance,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            StatCard(
              label: 'Tunggakan',
              value: formatRupiah(tunggakan),
              icon: Icons.warning,
              color: AppColors.danger,
              bgColor: AppColors.dangerLight,
            ),
            StatCard(
              label: 'Pemasukan Bulan Ini',
              value: formatRupiah(pemasukanBulanIni),
              icon: Icons.trending_up,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
            StatCard(
              label: 'Tagihan Lunas',
              value: '$tagihanLunas',
              icon: Icons.check_circle,
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _TagihanDistributionSection extends StatelessWidget {
  const _TagihanDistributionSection({required this.tagihanAsync});

  final AsyncValue<List<TagihanModel>> tagihanAsync;

  @override
  Widget build(BuildContext context) {
    final counts = tagihanAsync.maybeWhen(
      data: (list) => {
        TagihanStatus.lunas: list.where((t) => t.status == TagihanStatus.lunas).length,
        TagihanStatus.cicil: list.where((t) => t.status == TagihanStatus.cicil).length,
        TagihanStatus.belumBayar:
            list.where((t) => t.status == TagihanStatus.belumBayar).length,
      },
      orElse: () => <String, int>{},
    );

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
            'Distribusi Tagihan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DistributionBar(
            label: 'Lunas',
            count: counts[TagihanStatus.lunas] ?? 0,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.xs),
          _DistributionBar(
            label: 'Cicil',
            count: counts[TagihanStatus.cicil] ?? 0,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.xs),
          _DistributionBar(
            label: 'Belum Bayar',
            count: counts[TagihanStatus.belumBayar] ?? 0,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final max = [1, count].reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
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
                widthFactor: count / max,
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
          width: 40,
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _IncomeTrendSection extends StatelessWidget {
  const _IncomeTrendSection({required this.paymentsAsync});

  final AsyncValue<List<PaymentModel>> paymentsAsync;

  @override
  Widget build(BuildContext context) {
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
            'Tren Pemasukan 7 Hari Terakhir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: paymentsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Center(child: Text(friendlyError(err))),
              data: (payments) {
                // Group by day for last 7 days.
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final days = <DateTime>[];
                for (var i = 6; i >= 0; i--) {
                  days.add(today.subtract(Duration(days: i)));
                }
                final sums = <double>[];
                for (final d in days) {
                  final next = d.add(const Duration(days: 1));
                  final daySum = payments
                      .where((p) =>
                          p.status == PaymentStatus.verified &&
                          p.paymentDate.isAfter(d.subtract(const Duration(seconds: 1))) &&
                          p.paymentDate.isBefore(next))
                      .fold<double>(0, (s, p) => s + p.amount);
                  sums.add(daySum);
                }
                return _MiniLineChart(values: sums, days: days);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.values, required this.days});

  final List<double> values;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) {
      return const Center(
        child: Text(
          'Belum ada pemasukan minggu ini',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }
    // Render chart manually pakai CustomPaint — lebih ringan dari fl_chart untuk kasus sederhana.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const padBottom = 24.0;
        const padTop = 8.0;
        final chartH = h - padBottom - padTop;
        final stepX = (w / (values.length - 1).clamp(1, 999));

        final points = <Offset>[];
        for (var i = 0; i < values.length; i++) {
          final x = i * stepX;
          final y = padTop + chartH - (values[i] / maxVal) * chartH;
          points.add(Offset(x, y));
        }

        return CustomPaint(
          size: Size(w, h),
          painter: _LineChartPainter(
            points: points,
            color: AppColors.primary,
            fillGradientStart: AppColors.primaryLight,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: padBottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final d in days.take(7))
                      Text(
                        '${d.day}/${d.month}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.color,
    required this.fillGradientStart,
  });

  final List<Offset> points;
  final Color color;
  final Color fillGradientStart;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillGradientStart, fillGradientStart.withOpacity(0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _AbsensiTodaySection extends StatelessWidget {
  const _AbsensiTodaySection({required this.absensiAsync});

  final AsyncValue<List<AbsensiModel>> absensiAsync;

  @override
  Widget build(BuildContext context) {
    final counts = absensiAsync.maybeWhen(
      data: (list) => {
        AbsensiStatus.hadir: list.where((a) => a.status == AbsensiStatus.hadir).length,
        AbsensiStatus.sakit: list.where((a) => a.status == AbsensiStatus.sakit).length,
        AbsensiStatus.izin: list.where((a) => a.status == AbsensiStatus.izin).length,
        AbsensiStatus.alfa: list.where((a) => a.status == AbsensiStatus.alfa).length,
      },
      orElse: () => <String, int>{},
    );

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
              const Text(
                'Absensi Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/dashboard/akademik/absensi'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _AbsensiMiniCard(
                  label: 'Hadir',
                  value: counts[AbsensiStatus.hadir] ?? 0,
                  color: AppColors.success,
                  bg: AppColors.successLight,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AbsensiMiniCard(
                  label: 'Sakit',
                  value: counts[AbsensiStatus.sakit] ?? 0,
                  color: AppColors.warning,
                  bg: AppColors.warningLight,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AbsensiMiniCard(
                  label: 'Izin',
                  value: counts[AbsensiStatus.izin] ?? 0,
                  color: AppColors.info,
                  bg: AppColors.infoLight,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _AbsensiMiniCard(
                  label: 'Alfa',
                  value: counts[AbsensiStatus.alfa] ?? 0,
                  color: AppColors.danger,
                  bg: AppColors.dangerLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbsensiMiniCard extends StatelessWidget {
  const _AbsensiMiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final int value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenuSection extends StatelessWidget {
  const _QuickMenuSection({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monitoring',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          children: [
            _MenuTile(
              icon: Icons.people,
              label: 'Data Santri',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => context.go('/dashboard/santri'),
            ),
            _MenuTile(
              icon: Icons.check_circle_outline,
              label: 'Absensi',
              color: AppColors.info,
              bg: AppColors.infoLight,
              onTap: () => context.push('/dashboard/akademik/absensi'),
            ),
            _MenuTile(
              icon: Icons.star_outline,
              label: 'Nilai',
              color: const Color(0xFF7C3AED),
              bg: const Color(0xFFEDE9FE),
              onTap: () => context.push('/dashboard/akademik/nilai'),
            ),
            _MenuTile(
              icon: Icons.receipt_long,
              label: 'Tagihan',
              color: AppColors.warning,
              bg: AppColors.warningLight,
              onTap: () => context.push('/dashboard/keuangan/tagihan'),
            ),
            _MenuTile(
              icon: Icons.payment,
              label: 'Pembayaran',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => context.push('/dashboard/keuangan/pembayaran'),
            ),
            _MenuTile(
              icon: Icons.account_balance_wallet,
              label: 'Honor Guru',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: () => context.push('/dashboard/akademik/honor-guru'),
            ),
            _MenuTile(
              icon: Icons.bar_chart,
              label: 'Laporan Keuangan',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: () => context.push('/dashboard/keuangan/laporan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
