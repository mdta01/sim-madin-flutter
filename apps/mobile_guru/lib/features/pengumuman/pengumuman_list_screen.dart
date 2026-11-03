// Pengumuman list (read-only).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class PengumumanListScreen extends ConsumerWidget {
  const PengumumanListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(pengumumanListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengumuman')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
                title: 'Belum ada pengumuman',
                icon: Icons.campaign_outlined,
                onRefresh: () => ref.invalidate(pengumumanListProvider));
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
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(AppRadius.sm)),
                              child: Text(p.priority,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.infoLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm)),
                              child: Text(p.audience,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.info)),
                            ),
                            if (p.publishedAt != null) ...[
                              const Spacer(),
                              Text(formatDate(p.publishedAt),
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(p.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(p.content,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
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
