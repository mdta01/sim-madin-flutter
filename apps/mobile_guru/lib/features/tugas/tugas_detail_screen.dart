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
    final asyncValue =
        ref.watch(pengumpulanByTugasProvider(widget.tugasId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengumpulan Tugas')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
                title: 'Belum ada pengumpulan',
                subtitle: 'Santri belum submit tugas ini',
                icon: Icons.inbox_outlined);
          }
          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (c, i) {
              final p = list[i];
              _gradeControllers[p.id] ??=
                  TextEditingController(text: p.score?.toStringAsFixed(0) ?? '');
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.santriName ?? 'Santri',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text('NIS: ${p.santriNis ?? '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textMuted)),
                                if (p.submittedAt != null)
                                  Text('Submit: ${formatDateTime(p.submittedAt)}',
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
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(p.textAnswer!,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Text('Nilai: ',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _gradeControllers[p.id],
                              decoration: const InputDecoration(
                                hintText: '0-100',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : () => _grade(p.id, 100),
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
    );
  }
}
