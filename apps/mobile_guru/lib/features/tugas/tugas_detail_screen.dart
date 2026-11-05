// Tugas detail — list pengumpulan + grade.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class TugasDetailScreen extends ConsumerStatefulWidget {
  const TugasDetailScreen({super.key, required this.tugasId});
  final String tugasId;

  @override
  ConsumerState<TugasDetailScreen> createState() => _TugasDetailScreenState();
}

class _TugasDetailScreenState extends ConsumerState<TugasDetailScreen> {
  final _gradeControllers = <String, TextEditingController>{};
  final _feedbackControllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _gradeControllers.values) c.dispose();
    for (final c in _feedbackControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _grade(String pengumpulanId, double maxScore) async {
    final controller = _gradeControllers[pengumpulanId];
    final feedbackController = _feedbackControllers[pengumpulanId];
    if (controller == null) return;
    final score = double.tryParse(controller.text);
    if (score == null || score < 0 || score > maxScore) {
      _toast('Nilai harus 0-$maxScore', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await gradePengumpulanTugas(
        ref,
        pengumpulanId: pengumpulanId,
        score: score,
        feedback: feedbackController?.text.trim(),
      );
      if (!mounted) return;
      _toast('✅ Nilai tersimpan');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tugasAsync = ref.watch(tugasByIdProvider(widget.tugasId));
    final asyncValue =
        ref.watch(pengumpulanByTugasProvider(widget.tugasId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Tugas')),
      body: Column(
        children: [
          // Header info tugas (title, mapel, kelas, dueDate, maxScore)
          tugasAsync.when(
            loading: () => const SizedBox(height: 4),
            error: (e, _) => Container(
              color: AppColors.dangerLight,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text('Gagal load info tugas: ${friendlyError(e)}',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
            data: (t) {
              if (t == null) {
                return Container(
                  color: AppColors.warningLight,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: const Text('Tugas tidak ditemukan',
                      style: TextStyle(color: AppColors.warning, fontSize: 12)),
                );
              }
              return Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        StatusChip(
                          label: t.isPublished ? 'Aktif' : 'Draft',
                          color: t.isPublished
                              ? AppColors.success
                              : AppColors.textMuted,
                          bg: t.isPublished
                              ? AppColors.successLight
                              : const Color(0xFFF1F5F9),
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${t.mapelName ?? '-'} • ${t.kelasName ?? '-'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    if (t.description != null &&
                        t.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(t.description!,
                          style: const TextStyle(fontSize: 12)),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (t.dueDate != null)
                          _infoChip(
                              Icons.schedule,
                              'Tenggat: ${formatDateTime(t.dueDate)}',
                              t.dueDate!.isBefore(DateTime.now())
                                  ? AppColors.danger
                                  : AppColors.warning),
                        _infoChip(Icons.star_outline,
                            'Max Score: ${t.maxScore.toStringAsFixed(0)}',
                            AppColors.info),
                        _infoChip(Icons.tag,
                            'Tipe: ${t.type == TugasType.individu ? 'Individu' : 'Kelompok'}',
                            AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // List pengumpulan
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(),
              error: (e, _) => ErrorView(message: friendlyError(e)),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada pengumpulan',
                      subtitle: 'Santri belum submit tugas ini',
                      icon: Icons.inbox_outlined);
                }
                // Get maxScore dari tugasAsync untuk validasi grade.
                final tugasData = tugasAsync.maybeWhen(
                    data: (t) => t, orElse: () => null);
                final maxScore = tugasData?.maxScore ?? 100;

                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (c, i) {
                    final p = list[i];
                    _gradeControllers[p.id] ??= TextEditingController(
                        text: p.score?.toStringAsFixed(1) ?? '');
                    _feedbackControllers[p.id] ??=
                        TextEditingController(text: p.feedback ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.santriName ?? 'Santri',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      Text('NIS: ${p.santriNis ?? '-'}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                      if (p.submittedAt != null)
                                        Text(
                                            'Submit: ${formatDateTime(p.submittedAt)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                StatusChip(
                                  label: p.status == TugasStatus.graded
                                      ? 'Dinilai'
                                      : 'Terkumpul',
                                  color: p.status == TugasStatus.graded
                                      ? AppColors.success
                                      : AppColors.info,
                                  bg: p.status == TugasStatus.graded
                                      ? AppColors.successLight
                                      : AppColors.infoLight,
                                  compact: true,
                                ),
                              ],
                            ),
                            if (p.textAnswer != null &&
                                p.textAnswer!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(p.textAnswer!,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text('Nilai (0-${maxScore.toStringAsFixed(0)}): ',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _gradeControllers[p.id],
                                    decoration: InputDecoration(
                                      hintText:
                                          '0-${maxScore.toStringAsFixed(0)}',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _grade(p.id, maxScore),
                                  icon: const Icon(Icons.save, size: 18),
                                  label: const Text('Simpan'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextField(
                              controller: _feedbackControllers[p.id],
                              decoration: const InputDecoration(
                                labelText: 'Feedback (opsional)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
