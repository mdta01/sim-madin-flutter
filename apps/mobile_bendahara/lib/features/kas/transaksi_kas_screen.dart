// Transaksi Kas screen — list + create form.
// Form di-bottom-sheet (modal) untuk input pemasukan/pengeluaran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/amount_input.dart';
import '../../widgets/feedback_widgets.dart';

class TransaksiKasScreen extends ConsumerStatefulWidget {
  const TransaksiKasScreen({super.key});

  @override
  ConsumerState<TransaksiKasScreen> createState() =>
      _TransaksiKasScreenState();
}

class _TransaksiKasScreenState extends ConsumerState<TransaksiKasScreen> {
  final DateTime _now = DateTime.now();
  late ({DateTime start, DateTime end}) _range;

  @override
  void initState() {
    super.initState();
    final start = DateTime(_now.year, _now.month, 1);
    final end = DateTime(_now.year, _now.month + 1, 1);
    _range = (start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(transaksiKasByPeriodProvider(_range));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaksi Kas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Transaksi',
            onPressed: () => _showForm(context),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: friendlyError(err),
          onRetry: () =>
              ref.invalidate(transaksiKasByPeriodProvider(_range)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'Belum ada transaksi',
              subtitle: 'Bulan ini belum ada transaksi kas.',
              icon: Icons.receipt_outlined,
              onRefresh: () => ref.invalidate(
                  transaksiKasByPeriodProvider(_range)),
            );
          }

          final pemasukan = list
              .where((t) => t.type == TransaksiKasType.pemasukan)
              .fold<double>(0, (s, t) => s + t.amount);
          final pengeluaran = list
              .where((t) => t.type == TransaksiKasType.pengeluaran)
              .fold<double>(0, (s, t) => s + t.amount);
          final saldo = pemasukan - pengeluaran;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(transaksiKasByPeriodProvider(_range));
              await ref.read(
                  transaksiKasByPeriodProvider(_range).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Pemasukan',
                        value: formatRupiah(pemasukan),
                        color: AppColors.success,
                        bg: AppColors.successLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _StatBox(
                        label: 'Pengeluaran',
                        value: formatRupiah(pengeluaran),
                        color: AppColors.danger,
                        bg: AppColors.dangerLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: saldo >= 0
                        ? AppColors.primaryLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Saldo Periode',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.white),
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(saldo),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Daftar Transaksi (${list.length})',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...list.map((t) => _TransaksiCard(transaksi: t)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TransaksiForm(),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _TransaksiCard extends StatelessWidget {
  const _TransaksiCard({required this.transaksi});

  final TransaksiKasModel transaksi;

  @override
  Widget build(BuildContext context) {
    final isPemasukan = transaksi.type == TransaksiKasType.pemasukan;
    final color = isPemasukan ? AppColors.success : AppColors.danger;
    final bg = isPemasukan
        ? AppColors.successLight
        : AppColors.dangerLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaksi.description,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${TransaksiKasCategory.label(transaksi.category)} • ${transaksi.kasName ?? '-'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(transaksi.transaksiDate),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              '${isPemasukan ? '+' : '-'}${formatRupiah(transaksi.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Form transaksi kas (bottom sheet)
// ============================================================================

class _TransaksiForm extends ConsumerStatefulWidget {
  const _TransaksiForm();

  @override
  ConsumerState<_TransaksiForm> createState() => _TransaksiFormState();
}

class _TransaksiFormState extends ConsumerState<_TransaksiForm> {
  String _type = TransaksiKasType.pemasukan;
  String? _kasId;
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  int _amount = 0;
  bool _saving = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_kasId == null) {
      _toast('Pilih kas terlebih dahulu', isError: true);
      return;
    }
    if (_amount <= 0) {
      _toast('Nominal harus lebih dari 0', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final category = _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : (_type == TransaksiKasType.pemasukan
              ? TransaksiKasCategory.lainLain
              : TransaksiKasCategory.operasional);
      await createTransaksiKas(
        ref,
        kasId: _kasId!,
        type: _type,
        category: category,
        amount: _amount.toDouble(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : 'Transaksi ${_type == TransaksiKasType.pemasukan ? "pemasukan" : "pengeluaran"}',
      );
      if (!mounted) return;
      _toast('Transaksi ${formatRupiah(_amount.toDouble())} tercatat');
      Navigator.of(context).pop();
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
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasAsync = ref.watch(kasListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Tambah Transaksi',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Type toggle
            const Text(
              'Tipe Transaksi',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pemasukan'),
                    selected: _type == TransaksiKasType.pemasukan,
                    onSelected: (_) =>
                        setState(() => _type = TransaksiKasType.pemasukan),
                    selectedColor: AppColors.successLight,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Pengeluaran'),
                    selected: _type == TransaksiKasType.pengeluaran,
                    onSelected: (_) =>
                        setState(() => _type = TransaksiKasType.pengeluaran),
                    selectedColor: AppColors.dangerLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Kas picker
            const Text(
              'Kas / Rekening',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            kasAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (list) {
                if (list.isEmpty) {
                  return const Text(
                    'Belum ada kas terdaftar. Tambah dulu dari admin desktop.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.danger),
                  );
                }
                return Column(
                  children: list.map((k) {
                    final selected = _kasId == k.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      color: selected ? AppColors.primaryLight : null,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          k.type == KasType.bank
                              ? Icons.business
                              : Icons.payments,
                          color: AppColors.primary,
                        ),
                        title: Text(k.name),
                        subtitle: Text(
                            '${KasType.label(k.type)} • Saldo: ${formatRupiah(k.balance)}'),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary)
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () => setState(() => _kasId = k.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Category
            const Text(
              'Kategori (opsional)',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                hintText: _type == TransaksiKasType.pemasukan
                    ? 'cth: Donasi, Sumbangan'
                    : 'cth: Operasional, Honor, ATK',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount
            AmountInput(
              label: 'Nominal',
              initialValue: _amount,
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            const Text(
              'Keterangan',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Keterangan tambahan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
