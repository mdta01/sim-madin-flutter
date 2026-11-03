// Users CRUD — DataTable + form create/edit + role assign.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';
import '../../widgets/form_widgets.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue =
        ref.watch(userListProvider(UserListParams(search: _search.isEmpty ? null : _search)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari user (email, name, username)...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateEditDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tambah User'),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(userListProvider),
                ),
              ],
            ),
          ),
          // Table
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(itemCount: 10),
              error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(userListProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: _search.isEmpty
                        ? 'Belum ada user'
                        : 'Tidak ditemukan',
                    subtitle: _search.isEmpty
                        ? 'Klik "Tambah User" untuk membuat user pertama'
                        : 'Coba kata kunci lain',
                    icon: Icons.people_outline,
                    onRefresh: () => ref.invalidate(userListProvider),
                  );
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
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Last Login')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: list.map((u) {
                        return DataRow(cells: [
                          DataCell(Text(u.email,
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text(u.username,
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text(u.name,
                              style: const TextStyle(fontSize: 13))),
                          DataCell(Text(u.phone ?? '-',
                              style: const TextStyle(fontSize: 13))),
                          DataCell(StatusChip(
                            label: u.isActive ? 'Active' : 'Inactive',
                            color: u.isActive
                                ? AppColors.success
                                : AppColors.danger,
                            bg: u.isActive
                                ? AppColors.successLight
                                : AppColors.dangerLight,
                            compact: true,
                          )),
                          DataCell(Text(
                              u.lastLoginAt != null
                                  ? formatDateTime(u.lastLoginAt)
                                  : '-',
                              style: const TextStyle(fontSize: 12))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _showCreateEditDialog(context, user: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.security, size: 18),
                                tooltip: 'Assign Role',
                                onPressed: () =>
                                    _showAssignRoleDialog(context, u),
                                color: AppColors.info,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(context, u),
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
      {UserModel? user}) async {
    final isEdit = user != null;
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final uidCtrl = TextEditingController(text: user?.firebaseUid ?? '');
    bool isActive = user?.isActive ?? true;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(isEdit ? 'Edit User' : 'Tambah User'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormFieldLabel(
                  label: 'Email',
                  child: TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Username',
                  child: TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
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
                  label: 'Phone (opsional)',
                  child: TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FormFieldLabel(
                  label: 'Supabase Auth UID (opsional)',
                  hint: 'Link ke user Supabase Auth (auth.users.id). '
                      'Diisi kalau user sudah ada di auth.users.',
                  child: TextField(
                    controller: uidCtrl,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setInner(() => isActive = v),
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
                      if (emailCtrl.text.trim().isEmpty ||
                          nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Email dan Name wajib diisi'),
                              backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      setInner(() => saving = true);
                      try {
                        if (isEdit) {
                          await updateUser(
                            ref,
                            userId: user.id,
                            email: emailCtrl.text.trim(),
                            username: usernameCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            isActive: isActive,
                          );
                        } else {
                          await createUser(
                            ref,
                            email: emailCtrl.text.trim(),
                            username: usernameCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            firebaseUid: uidCtrl.text.trim().isEmpty
                                ? null
                                : uidCtrl.text.trim(),
                            isActive: isActive,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  isEdit ? '✅ User updated' : '✅ User created'),
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
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignRoleDialog(
      BuildContext context, UserModel user) async {
    final rolesAsync = ref.read(roleListProvider.future);
    final roles = await rolesAsync;
    if (!context.mounted) return;

    final userRoleIds = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Assign Role — ${user.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: roles.map((role) {
                final assigned = userRoleIds.contains(role.id);
                return CheckboxListTile(
                  title: Text(role.name),
                  subtitle: Text(role.code),
                  value: assigned,
                  onChanged: (v) async {
                    if (v == true) {
                      try {
                        await assignRoleToUser(ref,
                            userId: user.id, roleId: role.id);
                        setInner(() => userRoleIds.add(role.id));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal: ${friendlyError(e)}'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    } else {
                      try {
                        await removeRoleFromUser(ref,
                            userId: user.id, roleId: role.id);
                        setInner(() => userRoleIds.remove(role.id));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal: ${friendlyError(e)}'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Selesai')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus User',
      message:
          'Yakin ingin menghapus user "${user.name}" (${user.email})?\n\n'
          'User akan di-soft delete (deletedAt set, isActive=false). '
          'Data historis tetap utuh.',
      confirmText: 'Hapus',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await softDeleteUser(ref, user.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ User dihapus (soft delete)'),
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
