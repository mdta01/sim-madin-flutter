// Pertemuan list — lihat history pertemuan + create baru.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/form_widgets.dart';

class PertemuanListScreen extends ConsumerStatefulWidget {
  const PertemuanListScreen({super.key});
  @override
  ConsumerState<PertemuanListScreen> createState() =>
      _PertemuanListScreenState();
}

class _PertemuanListScreenState extends ConsumerState<PertemuanListScreen> {
  bool _creating = false;

  Future<void> _createPertemuan() async {
    final jadwalAsync = await ref.read(jadwalGuruProvider.future);
    if (jadwalAsync.isEmpty) {
      _toast('Belum ada jadwal. Hubungi admin.', isError: true);
      return;
    }
    String? selectedJadwalId = jadwalAsync.first.id;
    final topicController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Buat Pertemuan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jadwal', style: AppTextStyles.label),
                DropdownButton<String>(
                  value: selectedJadwalId,
                  items: jadwalAsync
                      .map((j) => DropdownMenuItem(
                            value: j.id,
                            child: Text(
                                '${dayOfWeekLabel(j.dayOfWeek)} ${j.startTime} • ${j.mapelName} • ${j.kelasName}'),
                          ))
                      .toList(),
                  onChanged: (v) => setInner(() => selectedJadwalId = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Topik (opsional)', style: AppTextStyles.label),
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text('Deskripsi (opsional)', style: AppTextStyles.label),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), isDense: true),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'jadwalId': selectedJadwalId,
                'topic': topicController.text,
                'description': descController.text,
              }),
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    setState(() => _creating = true);
    try {
      final jadwal = jadwalAsync.firstWhere((j) => j.id == result['jadwalId']);
      final existing = await ref.read(pertemuanGuruProvider.future);
      final pertemuanKe =
          existing.where((p) => p.kelasId == jadwal.kelasId).length + 1;
      await createPertemuan(
        ref,
        kelasId: jadwal.kelasId,
        mapelId: jadwal.mapelId,
        pertemuanKe: pertemuanKe,
        date: DateTime.now(),
        topic: (result['topic'] as String?)?.isEmpty == true
            ? null
            : result['topic'],
        description: (result['description'] as String?)?.isEmpty == true
            ? null
            : result['description'],
      );
      if (!mounted) return;
      _toast('✅ Pertemuan dibuat');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _complete(String id) async {
    // Konfirmasi dulu — complete pertemuan irreversible dari UI (data
    // sudah final, tidak bisa di-un-complete).
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Pertemuan Selesai?'),
        content: const Text(
            'Pertemuan akan ditandai selesai dan tidak bisa diubah kembali.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await completePertemuan(ref, id);
      if (!mounted) return;
      _toast('✅ Pertemuan selesai');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
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
    final asyncValue = ref.watch(pertemuanGuruProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pertemuan'),
        actions: [
          IconButton(
            icon: _creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white))
                : const Icon(Icons.add_circle),
            tooltip: 'Buat Pertemuan',
            onPressed: _creating ? null : _createPertemuan,
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const ModernLoadingSkeleton(),
        error: (e, _) => ModernErrorView(message: friendlyError(e)),
        data: (list) {
          if (list.isEmpty) {
            return ModernEmptyState(
              title: 'Belum ada pertemuan',
              subtitle: 'Tap + untuk buat dari jadwal',
              icon: Icons.event_outlined,
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(pertemuanGuruProvider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pertemuanGuruProvider);
              await ref.read(pertemuanGuruProvider.future);
            },
            child: ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (c, i) {
                final p = list[i];
                return ModernCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text('#${p.pertemuanKe}',
                              style: AppTextStyles.h4
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.topic ??
                                  '${p.mapelName} - Pertemuan ${p.pertemuanKe}',
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.mapelName ?? '-'} • ${p.kelasName ?? '-'}',
                              style: AppTextStyles.body3
                                  .copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatDate(p.date),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (p.isCompleted)
                        const ModernChip(
                          label: 'Selesai',
                          color: AppColors.success,
                          bg: AppColors.successLight,
                          compact: true,
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _complete(p.id),
                          icon: const Icon(Icons.check, size: 16),
                          label:
                              const Text('Selesai', style: AppTextStyles.body3),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
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
