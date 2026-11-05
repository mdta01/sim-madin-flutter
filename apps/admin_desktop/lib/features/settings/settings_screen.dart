// Settings — key-value pairs CRUD.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(systemSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
        AdminScreenHeader(
          title: 'Settings',
          icon: Icons.settings_outlined,
          subtitle: 'Konfigurasi sistem & preferensi',
          actions: [
            FilledButton.icon(
              onPressed: () => _showCreateEditDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Setting'),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(systemSettingsProvider),
            ),
          ],
        ),
          // Table
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(itemCount: 6),
              error: (e, _) => ErrorView(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(systemSettingsProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada setting',
                      subtitle: 'Klik "Tambah Setting" untuk membuat config',
                      icon: Icons.settings_outlined,
                      onRefresh: null);
                }
                return ModernDataTableContainer(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Key')),
                        DataColumn(label: Text('Value')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Public')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: list.map((s) {
                        return DataRow(cells: [
                          DataCell(Text(s.key,
                              style: AppTextStyles.label.copyWith(
                                  fontFamily: AppFonts.mono))),
                          DataCell(Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.3),
                            child: Text(s.value,
                                style: AppTextStyles.body3,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          )),
                          DataCell(StatusChip(
                            label: s.type,
                            color: _typeColor(s.type),
                            bg: _typeColor(s.type).withValues(alpha: 0.1),
                            compact: true,
                          )),
                          DataCell(Text(s.description ?? '-',
                              style: AppTextStyles.body3)),
                          DataCell(Icon(
                            s.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: s.isPublic
                                ? AppColors.success
                                : AppColors.textMuted,
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Edit',
                                onPressed: () => _showCreateEditDialog(
                                    context, setting: s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDelete(context, s),
                                color: AppColors.danger,
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                      headingRowHeight: 48,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 56,
                      columnSpacing: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'STRING':
        return AppColors.info;
      case 'NUMBER':
        return AppColors.primary;
      case 'BOOLEAN':
        return AppColors.warning;
      case 'JSON':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _showCreateEditDialog(BuildContext context,
      {SystemSettingModel? setting}) async {
    final isEdit = setting != null;
    final keyCtrl = TextEditingController(text: setting?.key ?? '');
    final valueCtrl = TextEditingController(text: setting?.value ?? '');
    final descCtrl = TextEditingController(text: setting?.description ?? '');
    String type = setting?.type ?? 'STRING';
    bool isPublic = setting?.isPublic ?? false;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(isEdit ? 'Edit Setting' : 'Tambah Setting'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormFieldLabel(
                  label: 'Key',
                  hint: 'Identifier unik (cth: app.name, payment.due_days)',
                  child: TextField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    enabled: !isEdit,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Value',
                  child: TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Type',
                  child: DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(
                          value: 'STRING', child: Text('String')),
                      DropdownMenuItem(
                          value: 'NUMBER', child: Text('Number')),
                      DropdownMenuItem(
                          value: 'BOOLEAN', child: Text('Boolean')),
                      DropdownMenuItem(value: 'JSON', child: Text('JSON')),
                    ],
                    onChanged: (v) =>
                        setInner(() => type = v ?? 'STRING'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Description (opsional)',
                  child: TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: const Text('Public'),
                  subtitle: const Text(
                      'Setting public bisa diakses tanpa auth (cth: app name)'),
                  value: isPublic,
                  onChanged: (v) => setInner(() => isPublic = v),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (keyCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Key wajib diisi'),
                              backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      setInner(() => saving = true);
                      try {
                        await upsertSystemSetting(
                          ref,
                          key: keyCtrl.text.trim(),
                          value: valueCtrl.text,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          type: type,
                          isPublic: isPublic,
                        );
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isEdit
                                  ? '✅ Setting updated'
                                  : '✅ Setting created'),
                              backgroundColor: AppColors.success),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal: ${friendlyError(e)}'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setInner(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SystemSettingModel setting) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Setting',
      message: 'Yakin ingin menghapus setting "${setting.key}"?',
      confirmText: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await deleteSystemSetting(ref, setting.key);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Setting dihapus'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal: ${friendlyError(e)}'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}
