// QR Code Management — generate QR per kelas atau per santri untuk absensi.
//
// QR Code berisi payload JSON: {"t":"SANTRI","sid":"<santriId>","nis":"<nis>"}.
// Saat di-scan oleh app mobile santri di madrasah, akan trigger check-in
// absensi otomatis.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

/// Build QR payload untuk santri.
String _buildSantriQrPayload({
  required String santriId,
  required String nis,
}) {
  return jsonEncode({
    't': 'SANTRI',
    'sid': santriId,
    'nis': nis,
    'v': 1,
  });
}

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});
  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  /// Generated QR cards (state local). Setiap item = (santriId, nis, name, kelasName, payload).
  final List<QrCardData> _generated = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.qr_code,
                          size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('QR Code Management', style: AppTextStyles.h3),
                    const Spacer(),
                    if (_generated.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _copyAllToClipboard,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy All Payloads'),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_generated.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _clearGenerated,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Info card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.infoLight.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.info_outline,
                            size: 20, color: AppColors.info),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tentang QR Code Absensi',
                                style: AppTextStyles.label),
                            const SizedBox(height: 4),
                            Text(
                              'QR Code digunakan untuk absensi otomatis. Santri scan QR di madrasah untuk check-in. '
                              'Pilih kelas untuk generate QR massal (1 per santri) atau pilih santri untuk QR individual. '
                              'QR berisi payload JSON yang didecode oleh app mobile santri.',
                              style: AppTextStyles.body3
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Action buttons
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _showGenerateByKelasDialog,
                      icon: const Icon(Icons.class_, size: 18),
                      label: const Text('Generate QR per Kelas'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: _showGenerateBySantriDialog,
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('Generate QR per Santri'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid of generated QR codes
          Expanded(
            child: _generated.isEmpty
                ? const ModernEmptyState(
                    title: 'Belum ada QR Code',
                    subtitle:
                        'Klik "Generate QR per Kelas" atau "Generate QR per Santri" untuk membuat QR code baru.',
                    icon: Icons.qr_code_2_outlined,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _generated.length,
                    itemBuilder: (ctx, i) {
                      final card = _generated[i];
                      return _QrCard(
                        data: card,
                        onRemove: () =>
                            setState(() => _generated.removeAt(i)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Dialog: pilih kelas → generate QR untuk semua santri di kelas itu.
  Future<void> _showGenerateByKelasDialog() async {
    final kelasList = await ref.read(kelasListProvider.future);
    if (!mounted) return;
    if (kelasList.isEmpty) {
      _toast('Belum ada kelas terdaftar. Tambahkan kelas dulu.', true);
      return;
    }

    String? kelasId = kelasList.first.id;
    bool generating = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Generate QR per Kelas'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormFieldLabel(
                  label: 'Pilih Kelas',
                  child: DropdownButtonFormField<String>(
                    value: kelasId,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    items: kelasList
                        .map((k) => DropdownMenuItem(
                              value: k.id,
                              child: Text('${k.code} • ${k.name}',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setInner(() => kelasId = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'QR akan di-generate untuk semua santri aktif di kelas terpilih. '
                  'Setiap QR berisi payload JSON {santriId, nis} untuk check-in absensi.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: generating
                  ? null
                  : () async {
                      if (kelasId == null) return;
                      setInner(() => generating = true);
                      try {
                        final count = await _generateForKelas(kelasId!);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _toast('✅ $count QR code di-generate');
                      } catch (e) {
                        _toast('Gagal: ${friendlyError(e)}', true);
                      } finally {
                        if (ctx.mounted) setInner(() => generating = false);
                      }
                    },
              icon: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.qr_code_2, size: 18),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _generateForKelas(String kelasId) async {
    final client = ref.read(supabaseClientProvider);
    final res = await client
        .from('Santri')
        .select('id, nis, name, Kelas(name, code)')
        .eq('kelasId', kelasId)
        .eq('status', SantriStatus.aktif)
        .filter('deletedAt', 'is', null)
        .order('name');
    final santriRows = (res as List).cast<Map<String, dynamic>>();
    if (santriRows.isEmpty) {
      throw Exception('Tidak ada santri aktif di kelas ini.');
    }
    final newCards = santriRows.map((r) {
      final kelas = r['Kelas'] as Map<String, dynamic>?;
      return QrCardData(
        santriId: r['id'] as String,
        nis: r['nis'] as String,
        name: r['name'] as String,
        kelasName: (kelas?['name'] as String?) ?? '-',
        payload: _buildSantriQrPayload(
          santriId: r['id'] as String,
          nis: r['nis'] as String,
        ),
      );
    }).toList();
    setState(() {
      // Remove duplicates (re-generate kelas yang sama akan replace existing
      // cards for the same santri supaya payload selalu fresh).
      final newSantriIds = newCards.map((c) => c.santriId).toSet();
      _generated.removeWhere((c) => newSantriIds.contains(c.santriId));
      _generated.insertAll(0, newCards);
    });
    return newCards.length;
  }

  /// Dialog: pilih santri (dengan search) → generate 1 QR.
  Future<void> _showGenerateBySantriDialog() async {
    final santriList = await ref.read(santriListProvider.future);
    if (!mounted) return;
    if (santriList.isEmpty) {
      _toast('Belum ada santri terdaftar.', true);
      return;
    }

    String? santriId;
    final searchCtrl = TextEditingController();
    String search = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final filtered = search.isEmpty
              ? santriList
              : santriList
                  .where((s) =>
                      s.name.toLowerCase().contains(search) ||
                      s.nis.toLowerCase().contains(search))
                  .toList();
          return AlertDialog(
            title: const Text('Generate QR per Santri'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari santri by nama/NIS...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setInner(() => search = v.trim().toLowerCase()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return RadioListTile<String>(
                          value: s.id,
                          groupValue: santriId,
                          title: Text(s.name,
                              style: AppTextStyles.body2
                                  .copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Text('${s.nis} • ${s.kelasName ?? '-'}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                          onChanged: (v) => setInner(() => santriId = v),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: santriId == null
                    ? null
                    : () {
                        final santri = santriList.firstWhere(
                          (s) => s.id == santriId,
                          orElse: () => santriList.first,
                        );
                        final card = QrCardData(
                          santriId: santri.id,
                          nis: santri.nis,
                          name: santri.name,
                          kelasName: santri.kelasName ?? '-',
                          payload: _buildSantriQrPayload(
                            santriId: santri.id,
                            nis: santri.nis,
                          ),
                        );
                        setState(() {
                          _generated.removeWhere(
                              (c) => c.santriId == card.santriId);
                          _generated.insert(0, card);
                        });
                        Navigator.of(ctx).pop();
                        _toast('✅ QR code di-generate untuk ${santri.name}');
                      },
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearGenerated() {
    if (_generated.isEmpty) return;
    setState(() => _generated.clear());
    _toast('✅ Semua QR dihapus');
  }

  Future<void> _copyAllToClipboard() async {
    if (_generated.isEmpty) return;
    final buf = StringBuffer();
    buf.writeln('QR Code Payloads - generated ${DateTime.now()}');
    buf.writeln('Total: ${_generated.length}');
    buf.writeln('${'-' * 60}');
    for (final c in _generated) {
      buf.writeln('Name: ${c.name}');
      buf.writeln('NIS: ${c.nis}');
      buf.writeln('Kelas: ${c.kelasName}');
      buf.writeln('Payload: ${c.payload}');
      buf.writeln('');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    _toast('✅ ${_generated.length} payload disalin ke clipboard');
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }
}

/// Data untuk 1 QR card yang sudah di-generate.
class QrCardData {
  const QrCardData({
    required this.santriId,
    required this.nis,
    required this.name,
    required this.kelasName,
    required this.payload,
  });
  final String santriId;
  final String nis;
  final String name;
  final String kelasName;
  final String payload;
}

/// Card berisi QR code + info santri + tombol print/copy.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.data, required this.onRemove});
  final QrCardData data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.name,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onRemove,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(data.nis,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted, fontFamily: 'monospace')),
          const Divider(height: AppSpacing.md),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: data.payload,
                  version: QrVersions.auto,
                  size: 120,
                  gapless: true,
                  backgroundColor: AppColors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.roundedOuter,
                    color: AppColors.text,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.roundedOuter,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(data.kelasName,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Copy Payload',
                iconSize: 18,
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: data.payload));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Payload ${data.name} disalin'),
                    duration: const Duration(seconds: 1),
                  ));
                },
                icon: const Icon(Icons.copy, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Print (visual)',
                iconSize: 18,
                onPressed: () => _showPrintView(context),
                icon: const Icon(Icons.print, color: AppColors.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tampilkan QR + info santri dalam dialog print-friendly (admin bisa
  /// pakai browser/OS print dialog). Implementasi sederhana — bukan printing
  /// package. Cukup tampilkan QR besar untuk screenshot/print manual.
  void _showPrintView(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Print QR - ${data.name}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('SIM MADIN',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
              Text('QR Card Absensi Santri',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: data.payload,
                  version: QrVersions.auto,
                  size: 200,
                  gapless: true,
                  backgroundColor: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(data.name,
                  style: AppTextStyles.h4, textAlign: TextAlign.center),
              Text('NIS: ${data.nis}',
                  style: AppTextStyles.body2.copyWith(fontFamily: 'monospace')),
              Text('Kelas: ${data.kelasName}',
                  style: AppTextStyles.body3.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
