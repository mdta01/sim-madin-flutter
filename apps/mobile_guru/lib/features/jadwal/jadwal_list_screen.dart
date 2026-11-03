// Jadwal list — grouped by day.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class JadwalListScreen extends ConsumerWidget {
  const JadwalListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(jadwalGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Jadwal Mengajar')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada jadwal',
              subtitle: 'Hubungi admin untuk setup jadwal mengajar',
              icon: Icons.calendar_month_outlined,
              onRefresh: () => ref.invalidate(jadwalGuruProvider),
            );
          }
          // Group by day
          final grouped = <int, List<JadwalModel>>{};
          for (final j in list) {
            grouped.putIfAbsent(j.dayOfWeek, () => []).add(j);
          }
          final days = grouped.keys.toList()..sort();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jadwalGuruProvider);
              await ref.read(jadwalGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: days.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final day = days[i];
                final items = grouped[day]!;
                items.sort((a, b) => a.startTime.compareTo(b.startTime));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(dayOfWeekLabel(day),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                    ...items.map((j) => Card(
                          margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSpacing.md),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Column(
                                children: [
                                  Text(j.startTime,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                  Text(j.endTime,
                                      style: const TextStyle(
                                          fontSize: 10, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            title: Text(j.mapelName ?? 'Mapel',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(j.kelasName ?? '-',
                                style: const TextStyle(fontSize: 12)),
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
