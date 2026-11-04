// Bank Soal list — list soal yang dimiliki guru, dengan FAB untuk create.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class BankSoalListScreen extends ConsumerWidget {
  const BankSoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(bankSoalGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bank Soal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/ujian/bank-soal/create'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Soal'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(bankSoalGuruProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada soal di bank soal',
              subtitle: 'Klik tombol "Buat Soal" untuk menambah soal baru',
              icon: Icons.inventory_2_outlined,
              onRefresh: () => ref.invalidate(bankSoalGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bankSoalGuruProvider);
              await ref.read(bankSoalGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final s = list[i];
                final typeLabel = s.type == SoalType.pg
                    ? 'PG'
                    : s.type == SoalType.isian
                        ? 'Isian'
                        : 'Essay';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      child: Text(typeLabel,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(s.question,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.code,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        Text('Bobot: ${s.bobot.toStringAsFixed(1)}'
                            '${s.difficulty != null ? ' • ${s.difficulty}' : ''}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: s.isActive
                        ? const StatusChip(
                            label: 'Aktif',
                            color: AppColors.success,
                            bg: AppColors.successLight,
                            compact: true)
                        : const StatusChip(
                            label: 'Nonaktif',
                            color: AppColors.textMuted,
                            bg: Color(0xFFF1F5F9),
                            compact: true),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
