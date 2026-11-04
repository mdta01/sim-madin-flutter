// Ujian list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class UjianListScreen extends ConsumerWidget {
  const UjianListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(ujianGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Ujian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Buat Ujian',
            onPressed: () => context.push('/dashboard/ujian/list/create'),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const ModernLoadingSkeleton(),
        error: (e, _) => ModernErrorView(message: friendlyError(e)),
        data: (list) {
          if (list.isEmpty) {
            return ModernEmptyState(
              title: 'Belum ada ujian',
              subtitle: 'Tap + untuk buat ujian baru',
              icon: Icons.quiz_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(ujianGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ujianGuruProvider);
              await ref.read(ujianGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final u = list[i];
                final statusLabel = UjianStatus.label(
                    u.isPublished ? UjianStatus.published : UjianStatus.draft);
                return ModernCard(
                  onTap: () => context.push('/dashboard/ujian/list/${u.id}'),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.quiz, color: AppColors.danger),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.title, style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text(
                              '${u.type} • ${u.mapelName ?? '-'} • ${u.kelasName ?? '-'}',
                              style: AppTextStyles.body3
                                  .copyWith(color: AppColors.textMuted),
                            ),
                            if (u.startTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Mulai: ${formatDateTime(u.startTime)}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                            if (u.durationMnt > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Durasi: ${u.durationMnt} menit',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ModernChip(
                        label: statusLabel,
                        color: u.isPublished
                            ? AppColors.success
                            : AppColors.textMuted,
                        bg: u.isPublished
                            ? AppColors.successLight
                            : const Color(0xFFF1F5F9),
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
