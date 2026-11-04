// Pembayaran detail — view detail + verify/reject/cetak actions.
// Fetch single payment by ID + show all fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:api_client/api_client.dart';

import '../../services/pdf_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/feedback_widgets.dart';

final paymentByIdProvider =
    FutureProvider.family<PaymentModel?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('Payment')
      .select('*, Santri(*), Tagihan(*, JenisTagihan(*))')
      .eq('id', id)
      .maybeSingle();
  if (res == null) return null;
  final santri = (res['Santri'] ?? res['santri']) as Map<String, dynamic>?;
  final tagihan = (res['Tagihan'] ?? res['tagihan']) as Map<String, dynamic>?;
  final jenis =
      tagihan?['JenisTagihan'] ?? tagihan?['jenisTagihan'];
  return PaymentModel.fromJson({
    ...res,
    if (santri != null) 'santriName': santri['name'],
    if (santri != null) 'santriNis': santri['nis'],
    if (jenis != null) 'tagihanCode': jenis['code'],
  });
});

class PembayaranDetailScreen extends ConsumerStatefulWidget {
  const PembayaranDetailScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  ConsumerState<PembayaranDetailScreen> createState() =>
      _PembayaranDetailScreenState();
}

class _PembayaranDetailScreenState
    extends ConsumerState<PembayaranDetailScreen> {
  bool _actionLoading = false;

  Future<void> _verify() async {
    final kasListAsync = ref.read(kasListProvider);
    final kasList = kasListAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <KasModel>[],
    );
    if (kasList.isEmpty) {
      // Verify tanpa kas (default)
      await _doVerify(null);
      return;
    }
    // Pilih kas
    String? selectedKasId = kasList.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: const Text('Verifikasi Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih kas yang menerima:'),
              const SizedBox(height: AppSpacing.sm),
              ...kasList.map((k) {
                return RadioListTile<String>(
                  value: k.id,
                  groupValue: selectedKasId,
                  title: Text(k.name),
                  subtitle: Text(
                      '${KasType.label(k.type)} • Saldo: ${formatRupiah(k.balance)}'),
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
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _doVerify(selectedKasId);
    }
  }

  Future<void> _doVerify(String? kasId) async {
    setState(() => _actionLoading = true);
    try {
      await verifyPembayaran(ref, widget.paymentId, kasId: kasId);
      ref.invalidate(paymentByIdProvider(widget.paymentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran diverifikasi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Tolak Pembayaran',
      message:
          'Yakin ingin menolak pembayaran ini? Tindakan ini tidak bisa dibatalkan.',
      confirmText: 'Tolak',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _actionLoading = true);
    try {
      await rejectPembayaran(ref, widget.paymentId);
      ref.invalidate(paymentByIdProvider(widget.paymentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran ditolak'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cetak(PaymentModel payment) async {
    try {
      await PdfService.shareKwitansiPembayaran(payment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cetak: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(paymentByIdProvider(widget.paymentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: friendlyError(err),
          onRetry: () =>
              ref.invalidate(paymentByIdProvider(widget.paymentId)),
        ),
        data: (payment) {
          if (payment == null) {
            return const EmptyState(
              title: 'Pembayaran tidak ditemukan',
              icon: Icons.search_off,
            );
          }
          final style = paymentStatusStyle(payment.status);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(paymentByIdProvider(widget.paymentId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Amount card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.white),
                      ),
                      Text(
                        formatRupiah(payment.amount),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusChip(
                        status: payment.status,
                        style: style,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Detail rows
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                          label: 'No. Invoice', value: payment.invoiceNo),
                      _DetailRow(
                          label: 'Tanggal',
                          value: formatDateTime(payment.paymentDate)),
                      _DetailRow(
                          label: 'Metode',
                          value:
                              PaymentMethod.label(payment.paymentMethod)),
                      _DetailRow(
                          label: 'Santri',
                          value: payment.santriName ?? '-'),
                      if (payment.santriNis != null)
                        _DetailRow(
                            label: 'NIS', value: payment.santriNis!),
                      if (payment.tagihanCode != null)
                        _DetailRow(
                            label: 'Untuk Tagihan',
                            value: payment.tagihanCode!),
                      if (payment.note != null &&
                          payment.note!.isNotEmpty)
                        _DetailRow(
                            label: 'Catatan', value: payment.note!),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Actions
                if (payment.status == PaymentStatus.pending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _actionLoading ? null : _reject,
                          icon: const Icon(Icons.close, color: AppColors.danger),
                          label: const Text('Tolak',
                              style: TextStyle(color: AppColors.danger)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _actionLoading ? null : _verify,
                          icon: _actionLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Verifikasi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Always: cetak kwitansi
                OutlinedButton.icon(
                  onPressed: () => _cetak(payment),
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Kwitansi PDF'),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}
