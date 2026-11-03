// Pembayaran create — form input pembayaran baru.
// 1. Pilih santri (search by name/NIS)
// 2. Pilih tagihan belum lunas (opsional) — auto-fill amount
// 3. Edit amount
// 4. Pilih metode (TUNAI/TRANSFER/QRIS)
// 5. Submit → createPembayaran() mutation
// 6. Optional: cetak kwitansi PDF setelah sukses

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../services/pdf_service.dart';
import '../../widgets/amount_input.dart';
import '../../widgets/feedback_widgets.dart';

class PembayaranCreateScreen extends ConsumerStatefulWidget {
  const PembayaranCreateScreen({super.key});

  @override
  ConsumerState<PembayaranCreateScreen> createState() =>
      _PembayaranCreateScreenState();
}

class _PembayaranCreateScreenState
    extends ConsumerState<PembayaranCreateScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedSantriId;
  String? _selectedSantriName;
  String? _selectedTagihanId;
  int _amount = 0;
  String _method = PaymentMethod.tunai;
  String _note = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedSantriId == null) {
      _toast('Pilih santri terlebih dahulu', isError: true);
      return;
    }
    if (_amount <= 0) {
      _toast('Nominal harus lebih dari 0', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await createPembayaran(
        ref,
        santriId: _selectedSantriId!,
        tagihanId: _selectedTagihanId,
        amount: _amount.toDouble(),
        paymentMethod: _method,
        note: _note.isNotEmpty ? _note : null,
      );
      if (!mounted) return;
      _toast('Pembayaran ${formatRupiah(_amount.toDouble())} tercatat');

      // Tanya cetak kwitansi
      final cetak = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pembayaran Berhasil'),
          content: Text(
              'Invoice: ${result.payment.invoiceNo}\nMau cetak kwitansi PDF?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.print),
              label: const Text('Cetak'),
            ),
          ],
        ),
      );
      if (cetak == true && mounted) {
        await PdfService.shareKwitansiPembayaran(result.payment);
      }
      if (mounted) context.go('/dashboard/pembayaran');
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
    final santriAsync = ref.watch(santriListProvider);
    final tagihanAsync = _selectedSantriId == null
        ? const AsyncValue<List<TagihanModel>>.data([])
        : ref.watch(tagihanBySantriProvider(_selectedSantriId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Input Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Bantuan',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cara Input Pembayaran'),
                content: const Text(
                  '1. Cari santri (nama atau NIS)\n'
                  '2. Pilih santri dari hasil pencarian\n'
                  '3. (Opsional) Pilih tagihan yang akan dibayar — nominal auto-terisi\n'
                  '4. Edit nominal sesuai pembayaran\n'
                  '5. Pilih metode pembayaran\n'
                  '6. (Opsional) Tambah catatan\n'
                  '7. Simpan → pembayaran berstatus PENDING (perlu verifikasi)\n'
                  '8. Cetak kwitansi PDF setelah sukses',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // === Step 1: Pilih Santri ===
            const Text(
              'Cari Santri',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Nama atau NIS...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_selectedSantriId != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSantriName ?? 'Santri',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                          const Text(
                            'Santri terpilih. Cari lagi untuk ganti.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedSantriId = null;
                        _selectedSantriName = null;
                        _selectedTagihanId = null;
                        _amount = 0;
                      }),
                      child: const Text('Ganti'),
                    ),
                  ],
                ),
              )
            else
              santriAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Text(friendlyError(e)),
                data: (list) {
                  final filtered = _query.isEmpty
                      ? list
                      : list
                          .where((s) =>
                              s.name.toLowerCase().contains(_query) ||
                              s.nis.toLowerCase().contains(_query))
                          .toList();
                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: const Text(
                        'Tidak ditemukan',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: filtered.take(5).map((s) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.primary,
                            child: Text(s.initials),
                          ),
                          title: Text(s.name,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                              '${s.nis} • ${s.kelasName ?? '-'}',
                              style: const TextStyle(fontSize: 12)),
                          trailing:
                              const Icon(Icons.chevron_right, size: 18),
                          onTap: () => setState(() {
                            _selectedSantriId = s.id;
                            _selectedSantriName = s.name;
                            _selectedTagihanId = null;
                            _amount = 0;
                            _searchController.clear();
                            _query = '';
                          }),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.md),

            // === Step 2: Pilih Tagihan (jika santri sudah dipilih) ===
            if (_selectedSantriId != null) ...[
              const Text(
                'Tagihan Belum Lunas (opsional)',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              tagihanAsync.when(
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Text(friendlyError(e)),
                data: (list) {
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                        'Tidak ada tagihan belum lunas. Pembayaran akan dicatat tanpa link tagihan.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: list.map((t) {
                      final outstanding = tagihanOutstanding(t);
                      final selected = _selectedTagihanId == t.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        color: selected ? AppColors.primaryLight : null,
                        child: ListTile(
                          dense: true,
                          title: Text(
                            '${t.jenisTagihanName ?? 'Tagihan'} • ${formatRupiah(outstanding)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            t.description ?? 'Tanpa keterangan',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20)
                              : const Icon(Icons.radio_button_unchecked,
                                  size: 20),
                          onTap: () => setState(() {
                            _selectedTagihanId = selected ? null : t.id;
                            _amount = outstanding.round();
                          }),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // === Step 3: Nominal ===
            AmountInput(
              label: 'Nominal Pembayaran',
              initialValue: _amount,
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: AppSpacing.md),

            // === Step 4: Metode ===
            const Text(
              'Metode Pembayaran',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                PaymentMethod.tunai,
                PaymentMethod.transfer,
                PaymentMethod.qris,
              ].map((m) {
                final selected = _method == m;
                return ChoiceChip(
                  label: Text(PaymentMethod.label(m)),
                  selected: selected,
                  onSelected: (_) => setState(() => _method = m),
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // === Step 5: Catatan ===
            const Text(
              'Catatan (opsional)',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Contoh: Cicilan SPP bulan September',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => _note = v,
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Submit ===
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Pembayaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
