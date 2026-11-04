// Materi list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class MateriListScreen extends ConsumerWidget {
  const MateriListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(materiGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Materi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Buat Materi',
            onPressed: () => context.push('/dashboard/akademik/materi/create'),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const ModernLoadingSkeleton(),
        error: (e, _) => ModernErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(materiGuruProvider)),
        data: (list) {
          if (list.isEmpty) {
            return ModernEmptyState(
              title: 'Belum ada materi',
              subtitle: 'Tap + untuk buat materi pertama',
              icon: Icons.book_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(materiGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(materiGuruProvider);
              await ref.read(materiGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final m = list[i];
                return Dismissible(
                  key: ValueKey(m.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: AppColors.danger,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: const Icon(Icons.delete, color: AppColors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Materi?'),
                        content: Text(
                            'Materi "${m.title}" akan dihapus (soft delete).'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: AppColors.white),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    try {
                      await deleteMateri(ref, m.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ Materi dihapus'),
                            backgroundColor: AppColors.success),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Gagal: ${friendlyError(e)}'),
                            backgroundColor: AppColors.danger),
                      );
                      ref.invalidate(materiGuruProvider);
                    }
                  },
                  child: ModernCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.book, color: AppColors.info, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: AppTextStyles.h4),
                              Text(
                                  '${MateriType.label(m.type)} • ${m.mapelName ?? '-'} • ${m.kelasName ?? '-'}',
                                  style: AppTextStyles.body3
                                      .copyWith(color: AppColors.textMuted)),
                              if (m.description != null) ...[
                                const SizedBox(height: 2),
                                Text(m.description!,
                                    style: AppTextStyles.body3
                                        .copyWith(color: AppColors.textMuted),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 2),
                              Text(formatDateTime(m.createdAt),
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        ModernChip(
                          label: m.isPublished ? 'Terbit' : 'Draft',
                          color: m.isPublished
                              ? AppColors.success
                              : AppColors.textMuted,
                          bg: m.isPublished
                              ? AppColors.successLight
                              : const Color(0xFFF1F5F9),
                          compact: true,
                        ),
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

  void _showMateriDetail(BuildContext context, MateriModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(m.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
                '${MateriType.label(m.type)} • ${m.mapelName ?? '-'} • ${m.kelasName ?? '-'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: AppSpacing.lg),
            if (m.description != null && m.description!.isNotEmpty) ...[
              Text(m.description!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (m.externalUrl != null && m.externalUrl!.isNotEmpty) ...[
              const Text('URL Eksternal:',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(m.externalUrl!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.info)),
              const SizedBox(height: AppSpacing.md),
            ],
            Text('Dibuat: ${formatDateTime(m.createdAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            if (m.isPublished)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: ModernChip(
                    label: 'Sudah dipublikasi',
                    color: AppColors.success,
                    bg: AppColors.successLight),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
