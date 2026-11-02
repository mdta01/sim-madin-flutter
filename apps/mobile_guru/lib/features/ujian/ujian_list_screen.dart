// Ujian list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

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
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada ujian',
              subtitle: 'Tap + untuk buat ujian baru',
              icon: Icons.quiz_outlined,
              onRefresh: () => ref.invalidate(ujianGuruProvider),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.quiz, color: AppColors.danger),
                    ),
                    title: Text(u.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${u.type} • ${u.mapelName ?? '-'} • ${u.kelasName ?? '-'}',
                            style: const TextStyle(fontSize: 12)),
                        if (u.startTime != null)
                          Text('Mulai: ${formatDateTime(u.startTime)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        if (u.durationMnt > 0)
                          Text('Durasi: ${u.durationMnt} menit',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: StatusChip(
                      label: UjianStatus.label(u.isPublished ? UjianStatus.published : UjianStatus.draft),
                      color: u.isPublished ? AppColors.success : AppColors.textMuted,
                      bg: u.isPublished
                          ? AppColors.successLight
                          : const Color(0xFFF1F5F9),
                      compact: true,
                    ),
                    onTap: () =>
                        context.push('/dashboard/ujian/list/${u.id}'),
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
