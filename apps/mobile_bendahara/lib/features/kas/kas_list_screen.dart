// Kas list — Tab 4.
// Menampilkan list kas/rekening + total saldo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class KasListScreen extends ConsumerWidget {
  const KasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(kasListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kas & Rekening'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transaksi Kas',
            onPressed: () => context.push('/dashboard/kas/transaksi'),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: friendlyError(err),
          onRetry: () => ref.invalidate(kasListProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada kas',
              subtitle: 'Tambah kas pertama dari admin desktop.',
              icon: Icons.account_balance_wallet_outlined,
              onRefresh: () => ref.invalidate(kasListProvider),
            );
          }
          final totalSaldo =
              list.fold<double>(0, (s, k) => s + k.balance);
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(kasListProvider);
              await ref.read(kasListProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
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
                              'Total Saldo',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.white),
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
                        '${list.length} kas',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...list.map((k) => _KasCard(kas: k)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KasCard extends StatelessWidget {
  const _KasCard({required this.kas});

  final KasModel kas;

  @override
  Widget build(BuildContext context) {
    final isBank = kas.type == KasType.bank;
    final iconColor = isBank ? AppColors.primary : AppColors.success;
    final iconBg = isBank ? AppColors.primaryLight : AppColors.successLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isBank ? Icons.business : Icons.payments,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kas.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${KasType.label(kas.type)}'
                    '${kas.accountNumber != null ? ' • ${kas.accountNumber}' : ''}'
                    '${kas.bankName != null ? ' • ${kas.bankName}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Saldo',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  formatRupiah(kas.balance),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
