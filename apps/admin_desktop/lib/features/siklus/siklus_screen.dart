// Siklus — overview dashboard (TA + stats, no complex auto-tagihan).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';

class SiklusScreen extends ConsumerWidget {
  const SiklusScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(siklusOverviewProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
        const Text('Siklus Akademik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.lg),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(siklusOverviewProvider)),
          data: (s) => Column(children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tahun Ajaran Aktif', style: TextStyle(fontSize: 13, color: AppColors.white)),
                Text(s.tahunAjaran?.name ?? 'Belum ada TA aktif', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white)),
                if (s.tahunAjaran != null) Text('${formatDate(s.tahunAjaran!.startDate)} - ${formatDate(s.tahunAjaran!.endDate)}', style: const TextStyle(fontSize: 13, color: AppColors.white)),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 3.0, children: [
              StatCard(label: 'Total Santri Aktif', value: '${s.totalSantri}', icon: Icons.people, color: AppColors.success, bgColor: AppColors.successLight),
              StatCard(label: 'Total Tunggakan', value: formatRupiah(s.totalTagihanOutstanding), icon: Icons.warning, color: AppColors.danger, bgColor: AppColors.dangerLight),
              StatCard(label: 'Pembayaran Verified', value: '${s.totalPaymentsVerified}', icon: Icons.payment, color: AppColors.info, bgColor: AppColors.infoLight),
            ]),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Text('Siklus fitur lanjutan (auto-tagihan generate, kenaikan kelas otomatis, payment-verify bulk) akan diimplementasikan di Phase 7 (Production). Saat ini admin dapat menggunakan modul Tagihan dan Pembayaran untuk manage manual.', style: TextStyle(fontSize: 13, color: AppColors.info)),
            ),
          ]),
        ),
      ]),
    );
  }
}
