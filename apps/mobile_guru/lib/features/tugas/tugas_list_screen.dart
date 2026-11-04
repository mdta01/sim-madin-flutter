// Tugas list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

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
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(tugasGuruProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada tugas',
              icon: Icons.assignment_outlined,
              onRefresh: () => ref.invalidate(tugasGuruProvider),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.assignment,
                          color: AppColors.success),
                    ),
                    title: Text(t.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${t.mapelName ?? '-'} • ${t.kelasName ?? '-'}',
                            style: const TextStyle(fontSize: 12)),
                        if (t.dueDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                              'Tenggat: ${formatDateTime(t.dueDate)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: t.dueDate!.isBefore(DateTime.now())
                                      ? AppColors.danger
                                      : AppColors.warning)),
                        ],
                        if (t.submissionCount != null) ...[
                          const SizedBox(height: 2),
                          Text('${t.submissionCount} pengumpulan',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.info)),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    trailing: t.isPublished
                        ? const StatusChip(
                            label: 'Aktif',
                            color: AppColors.success,
                            bg: AppColors.successLight,
                            compact: true)
                        : const StatusChip(
                            label: 'Draft',
                            color: AppColors.textMuted,
                            bg: Color(0xFFF1F5F9),
                            compact: true),
                    onTap: () => context.push('/dashboard/akademik/tugas/${t.id}'),
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
