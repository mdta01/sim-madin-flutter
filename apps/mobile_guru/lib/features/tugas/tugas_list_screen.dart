// Tugas list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class TugasListScreen extends ConsumerWidget {
  const TugasListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(tugasGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/akademik/tugas/create'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Tugas'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: asyncValue.when(
        loading: () => const ModernLoadingSkeleton(),
        error: (e, _) => ModernErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(tugasGuruProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ModernEmptyState(
              title: 'Belum ada tugas',
              icon: Icons.assignment_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(tugasGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tugasGuruProvider);
              await ref.read(tugasGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final t = list[i];
                final isOverdue =
                    t.dueDate != null && t.dueDate!.isBefore(DateTime.now());
                return ModernCard(
                  onTap: () =>
                      context.push('/dashboard/akademik/tugas/${t.id}'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.assignment,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text(
                              '${t.mapelName ?? '-'} • ${t.kelasName ?? '-'}',
                              style: AppTextStyles.body3
                                  .copyWith(color: AppColors.textMuted),
                            ),
                            if (t.dueDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Tenggat: ${formatDateTime(t.dueDate)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isOverdue
                                      ? AppColors.danger
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                            if (t.submissionCount != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${t.submissionCount} pengumpulan',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.info),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      t.isPublished
                          ? const ModernChip(
                              label: 'Aktif',
                              color: AppColors.success,
                              bg: AppColors.successLight,
                              compact: true,
                            )
                          : const ModernChip(
                              label: 'Draft',
                              color: AppColors.textMuted,
                              bg: Color(0xFFF1F5F9),
                              compact: true,
                            ),
                    ],
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
