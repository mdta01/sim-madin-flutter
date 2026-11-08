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
    final asyncValue = ref.watch(userListProvider(
        UserListParams(search: _search.isEmpty ? null : _search)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminScreenHeader(
            title: 'Users',
            icon: Icons.manage_accounts_outlined,
            subtitle: 'Akun login pengguna sistem',
            actions: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari user (email, name, username)...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => _showCreateStaffDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Tambah Akun Staf'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _showCreateEditDialog(context),
                icon: const Icon(Icons.person_add, size: 18),
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
          // Table
          Expanded(
            child: asyncValue.when(
              loading: () => const LoadingSkeleton(itemCount: 10),
              error: (e, _) => ErrorView(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(userListProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title:
                        _search.isEmpty ? 'Belum ada user' : 'Tidak ditemukan',
                    subtitle: _search.isEmpty
                        ? 'Klik "Tambah User" untuk membuat user pertama'
                        : 'Coba kata kunci lain',
                    icon: Icons.people_outline,
                    onRefresh: null,
                  );
                }
                return ModernDataTableContainer(
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
                              style: AppTextStyles.body3)),
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

  // -------------------------------------------------------------------
  // Tambah akun staf (email + password) — didaftarkan admin
  // -------------------------------------------------------------------
  // Ini alur produksi: admin mendaftarkan kepala/bendahara/guru dengan email
  // dan password, lalu staf tersebut login di aplikasi mobile masing-masing.
  // Berbeda dari "Tambah User" biasa yang hanya menulis tabel User.
  Future<void> _showCreateStaffDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nipCtrl = TextEditingController();
    final specCtrl = TextEditingController();

    // Peran yang bisa diberikan. SUPER_ADMIN hanya untuk admin utama.
    const roleOptions = <String, String>{
      'KEPALA': 'Kepala Madrasah',
      'BENDAHARA': 'Bendahara',
      'GURU': 'Guru',
      'ADMIN': 'Admin',
    };
    final selected = <String>{};
    bool saving = false;
    bool showPassword = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Tambah Akun Staf'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Akun ini dipakai untuk login di aplikasi mobile. '
                      'Email & password dibuat di sini, lalu diberikan kepada '
                      'staf yang bersangkutan.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FormFieldLabel(
                    label: 'Email *',
                    child: TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'nama@madrasah.com',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FormFieldLabel(
                    label: 'Password *',
                    hint: 'Minimal 6 karakter. Berikan ke staf, minta segera diganti.',
                    child: TextField(
                      controller: passwordCtrl,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(showPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setInner(() => showPassword = !showPassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FormFieldLabel(
                    label: 'Nama Lengkap *',
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FormFieldLabel(
                    label: 'No. WhatsApp',
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Peran *',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ...roleOptions.entries.map((e) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value),
                        subtitle: Text(e.key,
                            style: const TextStyle(fontSize: 11)),
                        value: selected.contains(e.key),
                        onChanged: (v) => setInner(() {
                          if (v == true) {
                            selected.add(e.key);
                          } else {
                            selected.remove(e.key);
                          }
                        }),
                      )),
                  if (selected.contains('GURU')) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FormFieldLabel(
                      label: 'NIP Guru (opsional)',
                      child: TextField(
                        controller: nipCtrl,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FormFieldLabel(
                      label: 'Bidang / Spesialisasi (opsional)',
                      hint: 'Mis. Al-Qur\'an, Fiqih, Matematika',
                      child: TextField(
                        controller: specCtrl,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Akun guru otomatis dibuatkan profil Guru. '
                      'Tambahkan jadwal di menu Jadwal agar data kelas muncul.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
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
                        _snack('Email dan Nama wajib diisi', error: true);
                        return;
                      }
                      if (passwordCtrl.text.length < 6) {
                        _snack('Password minimal 6 karakter', error: true);
                        return;
                      }
                      if (selected.isEmpty) {
                        _snack('Pilih minimal satu peran', error: true);
                        return;
                      }
                      setInner(() => saving = true);
                      try {
                        final result = await adminCreateStaffAccount(
                          ref,
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          name: nameCtrl.text.trim(),
                          roles: selected.toList(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          guruNip: nipCtrl.text.trim().isEmpty
                              ? null
                              : nipCtrl.text.trim(),
                          specialization: specCtrl.text.trim().isEmpty
                              ? null
                              : specCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        _snack('✅ ${result.message}');
                      } catch (e) {
                        if (ctx.mounted) {
                          _snack('Gagal: ${friendlyError(e)}', error: true);
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
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
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
                      child: CircularProgressIndicator(strokeWidth: 2))
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

  // -------------------------------------------------------------------
  // Hapus akun — kredensial login ikut dihapus
  // -------------------------------------------------------------------
  // Soft delete biasa (deletedAt + isActive=false) TIDAK cukup: baris
  // auth.users masih ada, sehingga orangnya masih bisa login ke aplikasi
  // mobile. RPC admin_delete_account menghapus auth.users juga, jadi akses
  // benar-benar dicabut.
  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    bool hardDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Hapus Akun'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hapus akun "${user.name}" (${user.email})?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Akun ini akan langsung tidak bisa login ke aplikasi '
                    'mobile. Kredensial login (Supabase Auth) dihapus, '
                    'peran dinonaktifkan, dan PIN wali dicabut.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: hardDelete,
                  onChanged: (v) => setInner(() => hardDelete = v == true),
                  title: const Text('Hapus permanen dari database',
                      style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    'Baris User ikut dihapus. Ditolak otomatis bila akun '
                    'punya data historis (guru/wali/santri) agar riwayat '
                    'absensi & pembayaran tidak rusak.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus Akun'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await adminDeleteAccount(
        ref,
        email: user.email,
        hardDelete: hardDelete,
      );
      _snack('✅ ${result.message}');
    } catch (e) {
      _snack('Gagal: ${friendlyError(e)}', error: true);
    }
  }
}
