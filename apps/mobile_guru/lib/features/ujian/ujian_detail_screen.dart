// Ujian detail — list soal + peserta + nilai + publish.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class UjianDetailScreen extends ConsumerWidget {
  const UjianDetailScreen({super.key, required this.ujianId});
  final String ujianId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ujianAsync = ref.watch(ujianByIdProvider(ujianId));
    final soalAsync = ref.watch(ujianSoalByUjianProvider(ujianId));
    final pesertaAsync = ref.watch(ujianPesertaByUjianProvider(ujianId));
    final nilaiAsync = ref.watch(ujianNilaiByUjianProvider(ujianId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Detail Ujian'),
          actions: [
            ujianAsync.maybeWhen(
              data: (u) => u != null && !u.isPublished
                  ? IconButton(
                      icon: const Icon(Icons.publish),
                      tooltip: 'Publish',
                      onPressed: () async {
                        try {
                          await publishUjian(ref, ujianId);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Ujian dipublikasi'),
                                backgroundColor: AppColors.success),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal: $e'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Soal'),
              Tab(text: 'Peserta'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Info tab
            ujianAsync.when(
              loading: () => const LoadingSkeleton(itemCount: 3),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (u) {
                if (u == null) return const EmptyState(title: 'Ujian tidak ditemukan');
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white)),
                          Text('${u.type} • ${u.mapelName ?? '-'} • ${u.kelasName ?? '-'}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _infoRow('Deskripsi', u.description ?? '-'),
                    _infoRow('Mulai', u.startTime != null ? formatDateTime(u.startTime) : '-'),
                    _infoRow('Selesai', u.endTime != null ? formatDateTime(u.endTime) : '-'),
                    _infoRow('Durasi', '${u.durationMnt} menit'),
                    _infoRow('Ruang', u.ruang ?? '-'),
                    _infoRow('Max Score', u.maxScore.toStringAsFixed(0)),
                    _infoRow('Passing Score', u.passingScore.toStringAsFixed(0)),
                    _infoRow('Status', u.isPublished ? 'Terbit' : 'Draft'),
                  ],
                );
              },
            ),
            // Soal tab
            soalAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada soal',
                      subtitle: 'Tambah soal dari Bank Soal (Phase selanjutnya)');
                }
                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (c, i) {
                    final s = list[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primary,
                          child: Text('${s.urutan}'),
                        ),
                        title: Text(s.question ?? '(soal)',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${s.type ?? '-'} • bobot ${s.bobot.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  },
                );
              },
            ),
            // Peserta + Nilai tab
            pesertaAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (peserta) {
                if (peserta.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada peserta',
                      subtitle: 'Tambah peserta dari admin desktop (Phase 6)');
                }
                final nilaiList = nilaiAsync.maybeWhen(
                    data: (l) => l, orElse: () => []);
                return ListView.builder(
                  itemCount: peserta.length,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (c, i) {
                    final p = peserta[i];
                    final nilai = nilaiList
                        .where((n) => n.santriId == p.santriId)
                        .firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.infoLight,
                          foregroundColor: AppColors.info,
                          child: const Icon(Icons.person),
                        ),
                        title: Text(p.santriName ?? 'Santri',
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('NIS: ${p.santriNis ?? '-'}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: nilai?.score != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (nilai!.score! >= 70)
                                      ? AppColors.successLight
                                      : AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(nilai.score!.toStringAsFixed(0),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: nilai.score! >= 70
                                            ? AppColors.success
                                            : AppColors.danger)),
                              )
                            : const StatusChip(
                                label: 'Belum',
                                color: AppColors.textMuted,
                                bg: Color(0xFFF1F5F9),
                                compact: true),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          const Text(': '),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
