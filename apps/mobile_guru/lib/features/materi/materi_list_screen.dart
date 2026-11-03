// Materi list + create.
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
                return Card(
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
                      // TODO: open materi detail / edit
                    },
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
