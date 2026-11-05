// Notifikasi — list + delete + create/broadcast.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifikasiListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Notifikasi',
          icon: Icons.notifications_outlined,
          subtitle: 'Kirim notifikasi & broadcast',
          actions: [
            FilledButton.icon(onPressed: () => _showCreateDialog(context, ref), icon: const Icon(Icons.send), label: const Text('Kirim Notifikasi')),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(onPressed: () => _showBroadcastDialog(context, ref), icon: const Icon(Icons.campaign), label: const Text('Broadcast All')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(notifikasiListAdminProvider)),
          ],
        ),
        Expanded(child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 8),
          error: (e, _) => ErrorView(message: friendlyError(e), onRetry: () => ref.invalidate(notifikasiListAdminProvider)),
          data: (list) => list.isEmpty ? const EmptyState(title: 'Belum ada notifikasi', subtitle: 'Kirim notifikasi pertama Anda dengan tombol di atas.', icon: Icons.notifications_outlined, onRefresh: null) : ModernDataTableContainer(
            child: SingleChildScrollView(child: DataTable(
              columns: const [DataColumn(label: Text('Wali')), DataColumn(label: Text('Title')), DataColumn(label: Text('Type')), DataColumn(label: Text('Priority')), DataColumn(label: Text('Read')), DataColumn(label: Text('Tanggal')), DataColumn(label: Text('Actions'))],
              rows: list.map((n) => DataRow(cells: [
                DataCell(Text(n.waliName, style: AppTextStyles.body3)),
                DataCell(Text(n.title, style: AppTextStyles.label)),
                DataCell(StatusChip(label: n.type, color: AppColors.info, bg: AppColors.infoLight, compact: true)),
                DataCell(StatusChip(label: n.priority, color: n.priority == 'URGENT' ? AppColors.danger : n.priority == 'PENTING' ? AppColors.warning : AppColors.textMuted, bg: n.priority == 'URGENT' ? AppColors.dangerLight : n.priority == 'PENTING' ? AppColors.warningLight : const Color(0xFFF1F5F9), compact: true)),
                DataCell(Icon(n.isRead ? Icons.check_circle : Icons.circle_outlined, size: 16, color: n.isRead ? AppColors.success : AppColors.warning)),
                DataCell(Text(formatDateTime(n.createdAt), style: AppTextStyles.body3)),
                DataCell(IconButton(icon: const Icon(Icons.delete, size: 18), color: AppColors.danger, onPressed: () async { await adminDeleteNotifikasi(ref, n.id); })),
              ])).toList(),
              headingRowHeight: 48, dataRowMinHeight: 48, dataRowMaxHeight: 56, columnSpacing: 24,
            )),
          ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }

  static const _types = ['NILAI', 'ABSENSI', 'TAGIHAN', 'PAYMENT', 'CHAT', 'PENGUMUMAN', 'CUSTOM'];
  static const _priorities = ['NORMAL', 'PENTING', 'URGENT'];

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final waliList = await ref.read(waliListAdminProvider(null).future);
    if (!context.mounted) return;

    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String? waliId;
    String type = 'CUSTOM';
    String priority = 'NORMAL';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: const Text('Kirim Notifikasi'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          FormFieldLabel(label: 'Wali', child: DropdownButtonFormField<String>(value: waliId, hint: const Text('Pilih Wali'), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: waliList.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(), onChanged: (v) => setInner(() => waliId = v))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Type', child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setInner(() => type = v!)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Priority', child: DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setInner(() => priority = v!)))),
          ]),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Judul', child: TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Pesan', child: TextField(controller: msgCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 4)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            if (waliId == null) { _toast(context, 'Wali wajib dipilih', true); return; }
            if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) { _toast(context, 'Judul & Pesan wajib diisi', true); return; }
            setInner(() => saving = true);
            try {
              await adminCreateNotifikasi(ref, waliId: waliId!, type: type, title: titleCtrl.text.trim(), message: msgCtrl.text.trim(), priority: priority);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast(context, '✅ Notifikasi terkirim');
            } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Kirim')),
        ],
      )),
    );
  }

  Future<void> _showBroadcastDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String type = 'PENGUMUMAN';
    String priority = 'NORMAL';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) => AlertDialog(
        title: const Text('Broadcast Notifikasi ke Semua Wali'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Kirim notifikasi ke semua wali dengan status ACTIVE. Akan trigger FCM push ke device masing-masing.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FormFieldLabel(label: 'Type', child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setInner(() => type = v!)))),
            const SizedBox(width: 8),
            Expanded(child: FormFieldLabel(label: 'Priority', child: DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setInner(() => priority = v!)))),
          ]),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Judul', child: TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
          const SizedBox(height: 8),
          FormFieldLabel(label: 'Pesan', child: TextField(controller: msgCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true), maxLines: 4)),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: saving ? null : () async {
            if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) { _toast(context, 'Judul & Pesan wajib diisi', true); return; }
            setInner(() => saving = true);
            try {
              final count = await adminCreateNotifikasiBulk(ref, type: type, title: titleCtrl.text.trim(), message: msgCtrl.text.trim(), priority: priority);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              _toast(context, '✅ $count notifikasi broadcast');
            } catch (e) { _toast(context, 'Gagal: ${friendlyError(e)}', true); } finally { if (ctx.mounted) setInner(() => saving = false); }
          }, child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Broadcast')),
        ],
      )),
    );
  }

  void _toast(BuildContext context, String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
