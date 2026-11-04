// Pengumuman list (read-only).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class PengumumanListScreen extends ConsumerWidget {
  const PengumumanListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(pengumumanListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengumuman')),
      body: asyncValue.when(
        loading: () => const ModernLoadingSkeleton(),
        error: (e, _) => ModernErrorView(message: friendlyError(e)),
        data: (list) {
          if (list.isEmpty) {
            return ModernEmptyState(
              title: 'Belum ada pengumuman',
              icon: Icons.campaign_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(pengumumanListProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pengumumanListProvider);
              await ref.read(pengumumanListProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final p = list[i];
                Color color;
                Color bg;
                switch (p.priority) {
                  case AnnouncementPriority.urgent:
                    color = AppColors.danger;
                    bg = AppColors.dangerLight;
                    break;
                  case AnnouncementPriority.penting:
                    color = AppColors.warning;
                    bg = AppColors.warningLight;
                    break;
                  default:
                    color = AppColors.info;
                    bg = AppColors.infoLight;
                }
                return ModernCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ModernChip(
                            label: p.priority,
                            color: color,
                            bg: bg,
                            compact: true,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ModernChip(
                            label: p.audience,
                            color: AppColors.info,
                            bg: AppColors.infoLight,
                            compact: true,
                          ),
                          if (p.publishedAt != null) ...[
                            const Spacer(),
                            Text(formatDate(p.publishedAt),
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(p.title, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text(p.content, style: AppTextStyles.body2),
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
