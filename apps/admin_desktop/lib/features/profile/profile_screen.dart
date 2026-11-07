// Profil admin — identitas akun, role & permission efektif, status realtime,
// ganti password, dan info server.
//
// Sebelumnya admin_desktop TIDAK punya halaman profil sama sekali: menu sidebar
// berisi 34 modul tapi tidak ada tempat untuk melihat role/permission yang
// dimiliki admin yang sedang login. `userProfileProvider` sudah ada di
// api_client tetapi tidak pernah dipakai.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/feedback_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final client = ref.watch(supabaseClientProvider);
    final authUser = client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminScreenHeader(
            title: 'Profil Saya',
            icon: Icons.account_circle_outlined,
            subtitle: 'Identitas akun, role & permission',
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(userProfileProvider),
              ),
            ],
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => const LoadingSkeleton(itemCount: 6),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
              data: (profile) => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _HeaderCard(
                    name: profile?.name ?? authUser?.email ?? 'Tidak diketahui',
                    email: profile?.email ?? authUser?.email ?? '-',
                    roleLabel: profile?.primaryRoleLabel ?? 'Tanpa role',
                    initials: profile?.initials,
                    avatarUrl: profile?.avatarUrl,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    title: 'Informasi Akun',
                    icon: Icons.badge_outlined,
                    children: [
                      _Row(
                        label: 'Nama lengkap',
                        value: profile?.name ?? '-',
                      ),
                      _Row(
                        label: 'Email',
                        value: profile?.email ?? authUser?.email ?? '-',
                      ),
                      _Row(label: 'Username', value: profile?.username ?? '-'),
                      _Row(
                        label: 'Telepon',
                        value: profile?.phone?.isNotEmpty == true
                            ? profile!.phone!
                            : '-',
                      ),
                      _Row(
                        label: 'Status akun',
                        value: (profile?.isActive ?? true)
                            ? 'Aktif'
                            : 'Nonaktif',
                        valueColor: (profile?.isActive ?? true)
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      _Row(
                        label: 'Login terakhir',
                        value: profile?.lastLoginAt != null
                            ? formatDateTime(profile!.lastLoginAt)
                            : '-',
                      ),
                      _Row(label: 'User ID', value: profile?.id ?? '-'),
                      _Row(
                        label: 'Supabase Auth UID',
                        value: authUser?.id ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    title: 'Role & Permission',
                    icon: Icons.shield_outlined,
                    children: [
                      if (profile == null || profile.roleNames.isEmpty)
                        const _Row(
                          label: 'Role',
                          value: 'Belum ada role aktif — hubungi super admin',
                          valueColor: AppColors.warning,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final r in profile.roleNames)
                                ModernChip(
                                  label: r,
                                  color: AppColors.primary,
                                  bg: AppColors.primaryLight,
                                  compact: true,
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _RolePermissions(roleCodes: profile?.roleCodes ?? const []),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    title: 'Status Koneksi',
                    icon: Icons.wifi_tethering,
                    children: [
                      const _RealtimeStatus(),
                      _Row(
                        label: 'Server',
                        value: SupabaseConfig.url
                            .replaceAll('https://', '')
                            .split('.')
                            .first,
                      ),
                      const _Row(label: 'Versi aplikasi', value: '1.0.0+1'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    title: 'Keamanan',
                    icon: Icons.lock_outline,
                    children: [
                      _ActionRow(
                        label: 'Ganti Password',
                        icon: Icons.password,
                        color: AppColors.warning,
                        onTap: () => _showChangePassword(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context, WidgetRef ref) async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Ganti Password'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Password minimal 8 karakter. Anda akan tetap login setelah '
                  'password diubah.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password baru',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi password baru',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final pwd = newCtrl.text;
                      if (pwd.length < 8) {
                        setInner(() => error = 'Password minimal 8 karakter');
                        return;
                      }
                      if (pwd != confirmCtrl.text) {
                        setInner(() => error = 'Konfirmasi password tidak sama');
                        return;
                      }
                      setInner(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(supabaseClientProvider)
                            .auth
                            .updateUser(UserAttributes(password: pwd));
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Password berhasil diubah'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        setInner(() {
                          saving = false;
                          error = friendlyError(e);
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    newCtrl.dispose();
    confirmCtrl.dispose();
  }
}

// ============================================================================
// Widgets
// ============================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.roleLabel,
    this.initials,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String roleLabel;
  final String? initials;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ModernAvatar(
            name: initials ?? name,
            photoUrl: avatarUrl,
            radius: 36,
            gradient: const LinearGradient(
              colors: [AppColors.white, AppColors.primaryLight],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                ModernChip(
                  label: roleLabel,
                  color: AppColors.white,
                  bg: AppColors.white.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTextStyles.label),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: AppTextStyles.body3.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: AppTextStyles.body2)),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan jumlah permission efektif yang dimiliki role user.
class _RolePermissions extends ConsumerWidget {
  const _RolePermissions({required this.roleCodes});

  final List<String> roleCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(allRolePermissionsProvider);
    final rolesAsync = ref.watch(roleListProvider);

    return matrixAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LinearProgressIndicator(minHeight: 3),
      ),
      error: (e, _) => _Row(
        label: 'Permission',
        value: 'Gagal memuat: ${friendlyError(e)}',
        valueColor: AppColors.warning,
      ),
      data: (matrix) {
        final codes = rolesAsync.maybeWhen(
          data: (roles) => roles
              .where((r) => roleCodes.contains(r.code))
              .map((r) => r.id)
              .toList(),
          orElse: () => const <String>[],
        );
        if (codes.isEmpty) {
          return const _Row(label: 'Permission', value: '-');
        }
        final granted = <String>{};
        for (final roleId in codes) {
          granted.addAll(matrix[roleId] ?? const <String>[]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              label: 'Permission efektif',
              value: '${granted.length} dari ${Permissions.all.length}',
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in granted.take(18))
                  ModernChip(
                    label: p,
                    color: AppColors.info,
                    bg: AppColors.infoLight,
                    compact: true,
                  ),
                if (granted.length > 18)
                  ModernChip(
                    label: '+${granted.length - 18} lainnya',
                    color: AppColors.textMuted,
                    bg: AppColors.backgroundSecondary,
                    compact: true,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Indikator realtime yang menampilkan status NYATA (jumlah event yang
/// diterima), bukan tulisan statis "Realtime aktif".
class _RealtimeStatus extends ConsumerWidget {
  const _RealtimeStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(realtimeEventCount);
    final tables = ref.watch(realtimeSubscribedTables);

    final connected = tables.isNotEmpty;
    final color = connected ? AppColors.success : AppColors.warning;

    return _Row(
      label: 'Realtime',
      value: connected
          ? 'Terhubung • ${tables.length} tabel • $events perubahan diterima'
          : 'Belum terhubung — data akan diperbarui saat refresh',
      valueColor: color,
    );
  }
}
