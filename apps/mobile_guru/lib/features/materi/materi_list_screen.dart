// Materi list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

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
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(materiGuruProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada materi',
              subtitle: 'Tap + untuk buat materi pertama',
              icon: Icons.book_outlined,
              onRefresh: () => ref.invalidate(materiGuruProvider),
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
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.book, color: AppColors.info),
                      ),
                      title: Text(m.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${MateriType.label(m.type)} • ${m.mapelName ?? '-'} • ${m.kelasName ?? '-'}',
                              style: const TextStyle(fontSize: 12)),
                          if (m.description != null) ...[
                            const SizedBox(height: 2),
                            Text(m.description!,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 2),
                          Text(formatDateTime(m.createdAt),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: m.isPublished
                          ? const StatusChip(
                              label: 'Terbit',
                              color: AppColors.success,
                              bg: AppColors.successLight,
                              compact: true)
                          : const StatusChip(
                              label: 'Draft',
                              color: AppColors.textMuted,
                              bg: Color(0xFFF1F5F9),
                              compact: true),
                      onTap: () {
                        // Show materi detail in modal bottom sheet (read-only).
                        _showMateriDetail(context, m);
                      },
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
                child: StatusChip(
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
