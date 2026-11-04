// Profile + logout — modern design dengan gradient header + ModernCard.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(waliSessionProvider);
    final wali = session?.wali;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // === Modern Gradient Header ===
          _ProfileHeader(
            name: wali?.name ?? '-',
            roleLabel: 'Wali Santri',
            avatarName: wali?.name,
          ),
          const SizedBox(height: AppSpacing.lg),

          // === Info Section ===
          SectionHeader(title: 'Informasi', icon: Icons.person_outline),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.alternate_email, label: 'Wali ID', value: wali?.id ?? '-'),
          _InfoRow(icon: Icons.call, label: 'WhatsApp', value: wali?.phone ?? '-'),
          if (wali?.email != null)
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: wali!.email!),
          if (wali?.occupation != null)
            _InfoRow(icon: Icons.work_outline, label: 'Pekerjaan', value: wali!.occupation!),
          if (wali?.address != null)
            _InfoRow(icon: Icons.location_on_outlined, label: 'Alamat', value: wali!.address!),
          _InfoRow(icon: Icons.people_outline, label: 'Hubungan', value: wali?.relationship ?? '-'),
          _InfoRow(
              icon: Icons.verified_user,
              label: 'Status Aktivasi',
              value: wali?.activationStatus ?? '-',
              valueColor: wali?.activationStatus == WaliActivationStatus.active
                  ? AppColors.success
                  : AppColors.warning),
          _InfoRow(
              icon: Icons.access_time,
              label: 'Login Terakhir',
              value: wali?.lastLoginAt != null
                  ? formatDateTime(wali!.lastLoginAt)
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
              invalidateWaliQueries(ref);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data dimuat ulang'),
                    backgroundColor: AppColors.primary),
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
                applicationName: 'SIM MADIN — Wali Santri',
                applicationVersion: '1.0.0+1',
                applicationLegalese:
                    'SIM Madrasah Diniyah — App Wali Santri\n© ${DateTime.now().year} MDTA Miftahul Ulum 01',
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                      'Phase 5 — mobile_wali (WA+PIN auth, multi-anak, ujian online)',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              );
            },
          ),
          _ActionCard(
            icon: Icons.lock_reset,
            label: 'Ubah PIN',
            color: AppColors.warning,
            onTap: () => context.push('/forgot-pin'),
          ),
          _ActionCard(
            icon: Icons.logout,
            label: 'Keluar',
            color: AppColors.danger,
            onTap: () async => logoutWaliAndNavigate(context, ref),
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
                  child: const Icon(Icons.wifi, color: AppColors.info, size: 20),
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
                          'Auto-refresh: Notifikasi, Chat, Tagihan, Pembayaran',
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
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

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
                    color: valueColor ?? AppColors.text),
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

/// Helper logout untuk wali — clear secure storage + invalidate + navigate.
Future<void> logoutWaliAndNavigate(
    BuildContext context, WidgetRef ref) async {
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

  await logoutWali(ref);
  if (!context.mounted) return;
  context.go('/login');
}
