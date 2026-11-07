// Profile screen — Tab 5.
// Modern design dengan gradient header + ModernCard, pakai userProfileProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:supabase_client/supabase_client.dart';

import 'package:api_client/api_client.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final client = ref.watch(supabaseClientProvider);
    final authUser = client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Fallback ke auth user info kalau profile gagal load.
            _ProfileHeader(
              name: authUser?.email ?? '-',
              roleLabel: 'Kepala Madrasah',
              avatarName: authUser?.email,
            ),
            const SizedBox(height: AppSpacing.lg),

            // === Info Section ===
            SectionHeader(title: 'Informasi', icon: Icons.person_outline),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
                icon: Icons.alternate_email,
                label: 'User ID',
                value: authUser?.id ?? '-'),
            _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: authUser?.email ?? '-'),
            const SizedBox(height: AppSpacing.md),
            ModernCard(
              backgroundColor: AppColors.warningLight,
              border: Border.all(color: AppColors.warningLight),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                        'Gagal memuat data profil: ${friendlyError(e)}',
                        style: AppTextStyles.body3
                            .copyWith(color: AppColors.warning)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Actions Section ===
            SectionHeader(title: 'Aksi', icon: Icons.tune_outlined),
            const SizedBox(height: AppSpacing.sm),
            _ActionCard(
              icon: Icons.refresh,
              label: 'Refresh Data',
              color: AppColors.primary,
              onTap: () {
                invalidateAllQueries(ref);
                ref.invalidate(userProfileProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data dimuat ulang'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            _ActionCard(
              icon: Icons.info_outline,
              label: 'Tentang Aplikasi',
              color: AppColors.info,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SIM MADIN — Kepala',
                  applicationVersion: '1.0.0+1',
                  applicationLegalese:
                      'SIM Madrasah Diniyah — App Kepala Madrasah\n© ${DateTime.now().year} MDTA Miftahul Ulum 01',
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Phase 2 — mobile_kepala (read-only monitoring)',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                );
              },
            ),
            _ActionCard(
              icon: Icons.logout,
              label: 'Keluar',
              color: AppColors.danger,
              onTap: () async => logoutAndNavigate(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),

            // === Realtime Badge ===
            ModernCard(
              backgroundColor: AppColors.infoLight,
              border: Border.all(color: AppColors.infoLight),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.wifi,
                        color: AppColors.info, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Realtime Aktif',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.info)),
                        const SizedBox(height: 2),
                        Text(
                            'Auto-refresh: Santri, Pembayaran, Tagihan, Honor Guru, Absensi, Nilai, Kas',
                            style: AppTextStyles.body3
                                .copyWith(color: AppColors.info)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (profile) {
          if (profile == null) {
            // Fallback ke auth user info.
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ProfileHeader(
                  name: authUser?.email ?? '-',
                  roleLabel: 'Kepala Madrasah',
                  avatarName: authUser?.email,
                ),
                const SizedBox(height: AppSpacing.lg),

                // === Info Section ===
                SectionHeader(title: 'Informasi', icon: Icons.person_outline),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                    icon: Icons.alternate_email,
                    label: 'User ID',
                    value: authUser?.id ?? '-'),
                _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: authUser?.email ?? '-'),
                _InfoRow(
                    icon: Icons.access_time,
                    label: 'Login Terakhir',
                    value: authUser?.lastSignInAt != null
                        ? formatDateTime(
                            DateTime.parse(authUser!.lastSignInAt!))
                        : '-'),
                const SizedBox(height: AppSpacing.xl),

                // === Actions Section ===
                SectionHeader(title: 'Aksi', icon: Icons.tune_outlined),
                const SizedBox(height: AppSpacing.sm),
                _ActionCard(
                  icon: Icons.refresh,
                  label: 'Refresh Data',
                  color: AppColors.primary,
                  onTap: () {
                    invalidateAllQueries(ref);
                    ref.invalidate(userProfileProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data dimuat ulang'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.info_outline,
                  label: 'Tentang Aplikasi',
                  color: AppColors.info,
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'SIM MADIN — Kepala',
                      applicationVersion: '1.0.0+1',
                      applicationLegalese:
                          'SIM Madrasah Diniyah — App Kepala Madrasah\n© ${DateTime.now().year} MDTA Miftahul Ulum 01',
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Phase 2 — mobile_kepala (read-only monitoring)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.logout,
                  label: 'Keluar',
                  color: AppColors.danger,
                  onTap: () async => logoutAndNavigate(context, ref),
                ),
                const SizedBox(height: AppSpacing.xl),

                // === Realtime Badge ===
                ModernCard(
                  backgroundColor: AppColors.infoLight,
                  border: Border.all(color: AppColors.infoLight),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.wifi,
                            color: AppColors.info, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Realtime Aktif',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.info)),
                            const SizedBox(height: 2),
                            Text(
                                'Auto-refresh: Santri, Pembayaran, Tagihan, Honor Guru, Absensi, Nilai, Kas',
                                style: AppTextStyles.body3
                                    .copyWith(color: AppColors.info)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProfileHeader(
                name: profile.name,
                roleLabel: profile.primaryRoleLabel,
                avatarName: profile.name,
                photoUrl: profile.avatarUrl,
              ),
              const SizedBox(height: AppSpacing.lg),

              // === Info Section ===
              SectionHeader(title: 'Informasi', icon: Icons.person_outline),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                  icon: Icons.alternate_email,
                  label: 'User ID',
                  value: profile.id),
              _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email),
              _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Username',
                  value: profile.username),
              if (profile.phone != null && profile.phone!.isNotEmpty)
                _InfoRow(
                    icon: Icons.call, label: 'Telepon', value: profile.phone!),
              if (profile.roleNames.isNotEmpty)
                _InfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Role',
                    value: profile.roleNames.join(', ')),
              _InfoRow(
                  icon: Icons.access_time,
                  label: 'Login Terakhir',
                  value: profile.lastLoginAt != null
                      ? formatDateTime(profile.lastLoginAt!)
                      : (authUser?.lastSignInAt != null
                          ? formatDateTime(
                              DateTime.parse(authUser!.lastSignInAt!))
                          : '-')),
              const SizedBox(height: AppSpacing.xl),

              // === Actions Section ===
              SectionHeader(title: 'Aksi', icon: Icons.tune_outlined),
              const SizedBox(height: AppSpacing.sm),
              _ActionCard(
                icon: Icons.refresh,
                label: 'Refresh Data',
                color: AppColors.primary,
                onTap: () {
                  invalidateAllQueries(ref);
                  ref.invalidate(userProfileProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data dimuat ulang'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _ActionCard(
                icon: Icons.info_outline,
                label: 'Tentang Aplikasi',
                color: AppColors.info,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'SIM MADIN — Kepala',
                    applicationVersion: '1.0.0+1',
                    applicationLegalese:
                        'SIM Madrasah Diniyah — App Kepala Madrasah\n© ${DateTime.now().year} MDTA Miftahul Ulum 01',
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Phase 2 — mobile_kepala (read-only monitoring)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  );
                },
              ),
              _ActionCard(
                icon: Icons.logout,
                label: 'Keluar',
                color: AppColors.danger,
                onTap: () async => logoutAndNavigate(context, ref),
              ),
              const SizedBox(height: AppSpacing.xl),

              // === Realtime Badge ===
              ModernCard(
                backgroundColor: AppColors.infoLight,
                border: Border.all(color: AppColors.infoLight),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.wifi,
                          color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Realtime Aktif',
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.info)),
                          const SizedBox(height: 2),
                          Text(
                              'Auto-refresh: Santri, Pembayaran, Tagihan, Honor Guru, Absensi, Nilai, Kas',
                              style: AppTextStyles.body3
                                  .copyWith(color: AppColors.info)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Modern gradient header dengan avatar + name + role badge.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.roleLabel,
    this.avatarName,
    this.photoUrl,
  });

  final String name;
  final String roleLabel;
  final String? avatarName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          ModernAvatar(
            name: avatarName,
            photoUrl: photoUrl,
            radius: 40,
            gradient: LinearGradient(
              colors: [AppColors.white, AppColors.primaryLight],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name,
              style: AppTextStyles.h3.copyWith(color: AppColors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs),
          ModernChip(
            label: roleLabel,
            color: AppColors.white,
            bg: AppColors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

/// Modern info row dengan icon + label + value dalam ModernCard.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 16, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textMuted)),
          ),
          Flexible(
            child: Text(value,
                style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Modern action card dengan icon + label + chevron dalam ModernCard.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ModernCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.text))),
            Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Helper logout yang dipakai ProfileScreen dan DashboardScreen.
/// Clear session + invalidate query cache + navigate to /login.
Future<void> logoutAndNavigate(BuildContext context, WidgetRef ref) async {
  // Confirm
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Konfirmasi Keluar'),
      content: const Text('Apakah Anda yakin ingin keluar?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // Unsubscribe realtime channels (prevent leak + double-trigger).
  await disposeAppRealtime(ref);

  // Clear FCM token dari DB + device sebelum signOut (butuh currentUser
  // masih ada untuk hapus row User.fcmToken by firebaseUid).
  await ref.read(notificationServiceProvider).clearToken();

  // Clear Supabase Auth session
  final client = ref.read(supabaseClientProvider);
  await client.auth.signOut();

  // Clear secure storage token (admin token + wali session)
  // ignore: unused_result
  await ref.read(authStorageProvider).clear();

  // Invalidate semua query providers supaya tidak bocor ke session berikutnya
  invalidateAllQueries(ref);

  if (!context.mounted) return;
  context.go('/login');
}
