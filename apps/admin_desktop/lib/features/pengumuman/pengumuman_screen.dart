// Pengumuman — list + create + delete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class PengumumanScreen extends ConsumerStatefulWidget {
  const PengumumanScreen({super.key});
  @override
  ConsumerState<PengumumanScreen> createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends ConsumerState<PengumumanScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pengumumanListAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AdminScreenHeader(
          title: 'Pengumuman',
          icon: Icons.campaign_outlined,
          subtitle: 'Siaran pengumuman madrasah',
          actions: [
            FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah')),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(pengumumanListAdminProvider)),
          ],
        ),
        Expanded(
            child: async.when(
          loading: () => const LoadingSkeleton(itemCount: 6),
          error: (e, _) => ErrorView(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(pengumumanListAdminProvider)),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  title: 'Belum ada pengumuman',
                  subtitle:
                      'Tambahkan pengumuman pertama Anda dengan tombol di atas.',
                  icon: Icons.campaign_outlined,
                  onRefresh: null)
              : ModernDataTableContainer(
                  child: SingleChildScrollView(
                      child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Judul')),
                      DataColumn(label: Text('Priority')),
                      DataColumn(label: Text('Audience')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Actions'))
                    ],
                    rows: list
                        .map((p) => DataRow(cells: [
                              DataCell(Container(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.3),
                                  child: Text(p.title,
                                      style: AppTextStyles.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis))),
                              DataCell(StatusChip(
                                  label: p.priority,
                                  color:
                                      p.priority == AnnouncementPriority.urgent
                                          ? AppColors.danger
                                          : p.priority ==
                                                  AnnouncementPriority.penting
                                              ? AppColors.warning
                                              : AppColors.info,
                                  bg: p.priority == AnnouncementPriority.urgent
                                      ? AppColors.dangerLight
                                      : p.priority ==
                                              AnnouncementPriority.penting
                                          ? AppColors.warningLight
                                          : AppColors.infoLight,
                                  compact: true)),
                              DataCell(StatusChip(
                                  label: p.audience,
                                  color: AppColors.info,
                                  bg: AppColors.infoLight,
                                  compact: true)),
                              DataCell(Text(formatDate(p.publishedAt),
                                  style: AppTextStyles.body3)),
                              DataCell(IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: AppColors.danger,
                                  onPressed: () async {
                                    await adminDeletePengumuman(ref, p.id);
                                  })),
                            ]))
                        .toList(),
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    columnSpacing: 24,
                  )),
                ),
        )),
        const SizedBox(height: AppSpacing.md),
      ]),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String priority = AnnouncementPriority.normal;
    String audience = AnnouncementAudience.all;
    bool saving = false;
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setInner) => AlertDialog(
                  title: const Text('Tambah Pengumuman'),
                  content: SizedBox(
                      width: 500,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FormFieldLabel(
                            label: 'Judul',
                            child: TextField(
                                controller: titleCtrl,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true))),
                        const SizedBox(height: 8),
                        FormFieldLabel(
                            label: 'Isi',
                            child: TextField(
                                controller: contentCtrl,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true),
                                maxLines: 5)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: FormFieldLabel(
                                  label: 'Priority',
                                  child: DropdownButtonFormField<String>(
                                      value: priority,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true),
                                      items: const [
                                        DropdownMenuItem(
                                            value: AnnouncementPriority.normal,
                                            child: Text('Normal')),
                                        DropdownMenuItem(
                                            value: AnnouncementPriority.penting,
                                            child: Text('Penting')),
                                        DropdownMenuItem(
                                            value: AnnouncementPriority.urgent,
                                            child: Text('Urgent'))
                                      ],
                                      onChanged: (v) =>
                                          setInner(() => priority = v!)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: FormFieldLabel(
                                  label: 'Audience',
                                  child: DropdownButtonFormField<String>(
                                      value: audience,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          isDense: true),
                                      items: const [
                                        DropdownMenuItem(
                                            value: AnnouncementAudience.all,
                                            child: Text('Semua')),
                                        DropdownMenuItem(
                                            value: AnnouncementAudience.wali,
                                            child: Text('Wali')),
                                        DropdownMenuItem(
                                            value: AnnouncementAudience.guru,
                                            child: Text('Guru')),
                                        DropdownMenuItem(
                                            value: AnnouncementAudience.santri,
                                            child: Text('Santri'))
                                      ],
                                      onChanged: (v) =>
                                          setInner(() => audience = v!))))
                        ]),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal')),
                    ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (titleCtrl.text.trim().isEmpty ||
                                    contentCtrl.text.trim().isEmpty) {
                                  _toast('Judul dan Isi wajib diisi', true);
                                  return;
                                }
                                setInner(() => saving = true);
                                try {
                                  await adminCreatePengumuman(ref,
                                      title: titleCtrl.text.trim(),
                                      content: contentCtrl.text.trim(),
                                      priority: priority,
                                      audience: audience);
                                  if (!context.mounted) return;
                                  Navigator.of(ctx).pop();
                                  _toast('✅ Pengumuman created');
                                } catch (e) {
                                  _toast('Gagal: ${friendlyError(e)}', true);
                                } finally {
                                  if (ctx.mounted) {
                                    setInner(() => saving = false);
                                  }
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Create'))
                  ],
                )));
  }

  void _toast(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success));
  }
}
