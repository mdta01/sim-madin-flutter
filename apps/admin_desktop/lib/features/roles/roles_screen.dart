// Roles CRUD — DataTable + form create/edit + permission matrix.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});
  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(roleListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Text('Daftar Role',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateEditDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Role'),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(roleListProvider),
                ),
              ],
            ),
          ),
          // Table
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(itemCount: 6),
              error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(roleListProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      title: 'Belum ada role',
                      subtitle: 'Klik "Tambah Role" untuk membuat role',
                      icon: Icons.admin_panel_settings_outlined);
                }
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Sort')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: list.map((r) {
                        return DataRow(cells: [
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(r.code,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          )),
                          DataCell(Text(r.name,
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text(r.description ?? '-',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Text('${r.sortOrder ?? 0}',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Edit',
                                onPressed: () => _showCreateEditDialog(
                                    context, role: r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.lock, size: 18),
                                tooltip: 'Permissions',
                                onPressed: () => _showPermissionMatrix(
                                    context, r),
                                color: AppColors.info,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDelete(context, r),
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

  Future<void> _showCreateEditDialog(BuildContext context,
      {RoleModel? role}) async {
    final isEdit = role != null;
    final codeCtrl = TextEditingController(text: role?.code ?? '');
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    final sortCtrl =
        TextEditingController(text: role != null ? '${role.sortOrder}' : '99');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(isEdit ? 'Edit Role' : 'Tambah Role'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormFieldLabel(
                  label: 'Code',
                  hint: 'Huruf kapital + underscore (cth: KEPALA_MADIN)',
                  child: TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    enabled: !isEdit, // code immutable after create
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Name',
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
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
                FormFieldLabel(
                  label: 'Sort Order',
                  hint: 'Urutan tampil di sidebar (1=atas)',
                  child: TextField(
                    controller: sortCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                  ),
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
                      if (codeCtrl.text.trim().isEmpty ||
                          nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Code dan Name wajib diisi'),
                              backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      setInner(() => saving = true);
                      try {
                        final sortOrder =
                            int.tryParse(sortCtrl.text) ?? 99;
                        if (isEdit) {
                          await updateRole(
                            ref,
                            roleId: role.id,
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            sortOrder: sortOrder,
                          );
                        } else {
                          await createRole(
                            ref,
                            code: codeCtrl.text.trim().toUpperCase(),
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            sortOrder: sortOrder,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isEdit
                                  ? '✅ Role updated'
                                  : '✅ Role created'),
                              backgroundColor: AppColors.success),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal: $e'),
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

  Future<void> _showPermissionMatrix(
      BuildContext context, RoleModel role) async {
    // Get all permissions + current role permissions
    final permissions = await ref.read(permissionListProvider.future);
    final currentMatrix =
        await ref.read(rolePermissionsMatrixProvider(role.id).future);
    final currentPermIds = currentMatrix[role.id] ?? <String>{};

    // Map code → permissionId for quick lookup
    final codeToId = <String, String>{};
    for (final p in permissions) {
      codeToId[p.code] = p.id;
    }

    // Group by module
    final grouped = <String, List<PermissionModel>>{};
    for (final p in permissions) {
      final module = p.code.split(':')[0];
      grouped.putIfAbsent(module, () => []).add(p);
    }

    // Track local state (for UI updates before save)
    final localState = <String, bool>{};
    for (final p in permissions) {
      localState[p.id] = currentPermIds.contains(p.id);
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Permission Matrix — ${role.name}'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: ListView(
              children: grouped.entries.map((entry) {
                final module = entry.key;
                final perms = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(module.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: perms.map((p) {
                            final granted = localState[p.id] ?? false;
                            return FilterChip(
                              label: Text(p.code.split(':')[1]),
                              selected: granted,
                              onSelected: (v) =>
                                  setInner(() => localState[p.id] = v),
                              selectedColor: AppColors.primaryLight,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await bulkUpdateRolePermissions(
                    ref,
                    roleId: role.id,
                    permissions: localState,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✅ Permissions updated'),
                        backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: AppColors.danger),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RoleModel role) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Role',
      message:
          'Yakin ingin menghapus role "${role.name}" (${role.code})?\n\n'
          'Catatan: kalau role masih dipakai oleh user, FK constraint '
          'akan block delete. Reassign users dulu sebelum delete.',
      confirmText: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await deleteRole(ref, role.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Role dihapus'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}
