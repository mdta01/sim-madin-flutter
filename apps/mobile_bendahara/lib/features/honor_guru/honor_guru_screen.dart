// Honor Guru screen — list + slip PDF.
// Bendahara bisa approve (DRAFT → DISETUJUI) dan bayar (DISETUJUI → DIBAYARKAN).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../services/pdf_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/feedback_widgets.dart';

class HonorGuruScreen extends ConsumerStatefulWidget {
  const HonorGuruScreen({super.key});

  @override
  ConsumerState<HonorGuruScreen> createState() => _HonorGuruScreenState();
}

class _HonorGuruScreenState extends ConsumerState<HonorGuruScreen> {
  String _statusFilter = 'ALL';
  bool _actionLoading = false;

  Future<void> _approve(HonorGuruModel honor) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Setujui Honor',
      message: 'Setujui honor ${honor.guruName ?? ''} periode ${honor.periodeLabel}?',
      confirmText: 'Setujui',
    );
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      await updateHonorGuruStatus(ref, honor.id, HonorGuruStatus.disetujui);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Honor disetujui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _pay(HonorGuruModel honor) async {
    final kasListAsync = ref.read(kasListProvider);
    final kasList = kasListAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <KasModel>[],
    );
    if (kasList.isEmpty) {
      _toast('Belum ada kas terdaftar. Tambah dulu dari admin desktop.',
          isError: true);
      return;
    }
    String? selectedKasId = kasList.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Bayar Honor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Guru: ${honor.guruName ?? '-'}'),
              Text('Periode: ${honor.periodeLabel}'),
              Text('Total: ${formatRupiah(honor.totalHonor > 0 ? honor.totalHonor : computeTotalHonor(honor))}'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Pilih kas yang digunakan:'),
              ...kasList.map((k) {
                return RadioListTile<String>(
                  value: k.id,
                  groupValue: selectedKasId,
                  title: Text(k.name),
                  subtitle: Text(
                      'Saldo: ${formatRupiah(k.balance)}'),
                  onChanged: (v) =>
                      setInnerState(() => selectedKasId = v),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await updateHonorGuruStatus(
        ref,
        honor.id,
        HonorGuruStatus.dibayarkan,
        kasId: selectedKasId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Honor dibayarkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cetakSlip(HonorGuruModel honor) async {
    try {
      await PdfService.shareSlipHonorGuru(honor);
    } catch (e) {
      _toast('Gagal cetak: ${friendlyError(e)}', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(honorGuruListProvider(_statusFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Honor Guru')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                prefixIcon: Icon(Icons.filter_list),
              ),
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Semua')),
                DropdownMenuItem(
                    value: HonorGuruStatus.draft, child: Text('Draft')),
                DropdownMenuItem(
                    value: HonorGuruStatus.disetujui,
                    child: Text('Disetujui')),
                DropdownMenuItem(
                    value: HonorGuruStatus.dibayarkan,
                    child: Text('Dibayarkan')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
            ),
          ),
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(honorGuruListProvider(_statusFilter)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'Belum ada honor guru',
                    subtitle: 'Generate dari admin desktop (Phase 6).',
                    icon: Icons.school_outlined,
                    onRefresh: () => ref
                        .invalidate(honorGuruListProvider(_statusFilter)),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(honorGuruListProvider(_statusFilter));
                    await ref.read(
                        honorGuruListProvider(_statusFilter).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: list
                        .map((h) => _HonorCard(
                              honor: h,
                              actionLoading: _actionLoading,
                              onApprove: () => _approve(h),
                              onPay: () => _pay(h),
                              onCetak: () => _cetakSlip(h),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HonorCard extends StatelessWidget {
  const _HonorCard({
    required this.honor,
    required this.actionLoading,
    required this.onApprove,
    required this.onPay,
    required this.onCetak,
  });

  final HonorGuruModel honor;
  final bool actionLoading;
  final VoidCallback onApprove;
  final VoidCallback onPay;
  final VoidCallback onCetak;

  @override
  Widget build(BuildContext context) {
    final style = honorGuruStatusStyle(honor.status);
    final total = honor.totalHonor > 0
        ? honor.totalHonor
        : computeTotalHonor(honor);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        honor.guruName ?? 'Guru',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${honor.periodeLabel} • ${honor.guruSpecialization ?? "Guru"}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: honor.status, style: style, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Breakdown
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  _breakdownRow('Honor Mengajar', formatRupiah(honor.honorMengajar),
                      AppColors.text),
                  _breakdownRow('Insentif',
                      '+ ${formatRupiah(honor.insentif)}', AppColors.success),
                  _breakdownRow('Tunjangan',
                      '+ ${formatRupiah(honor.tunjangan)}', AppColors.success),
                  _breakdownRow('Potongan',
                      '- ${formatRupiah(honor.potongan)}', AppColors.danger),
                  const Divider(height: AppSpacing.sm),
                  _breakdownRow('Total', formatRupiah(total),
                      AppColors.primary, bold: true),
                ],
              ),
            ),

            if (honor.catatan != null && honor.catatan!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Catatan: ${honor.catatan}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Actions
            Row(
              children: [
                if (honor.status == HonorGuruStatus.draft) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionLoading ? null : onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (honor.status == HonorGuruStatus.disetujui) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: actionLoading ? null : onPay,
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Bayar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                IconButton(
                  onPressed: onCetak,
                  icon: const Icon(Icons.print, size: 20),
                  tooltip: 'Cetak Slip PDF',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight:
                        bold ? FontWeight.w600 : FontWeight.w400)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
