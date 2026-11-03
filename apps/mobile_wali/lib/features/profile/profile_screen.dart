// Profile + logout.
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.white,
                  child: Text(
                    wali?.name.isNotEmpty == true
                        ? wali!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wali?.name ?? '-',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      const Text('Wali Santri',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _infoRow(Icons.alternate_email, 'Wali ID', wali?.id ?? '-'),
          _infoRow(Icons.call, 'WhatsApp', wali?.phone ?? '-'),
          if (wali?.email != null)
            _infoRow(Icons.email_outlined, 'Email', wali!.email!),
          if (wali?.occupation != null)
            _infoRow(Icons.work_outline, 'Pekerjaan', wali!.occupation!),
          if (wali?.address != null)
            _infoRow(Icons.location_on_outlined, 'Alamat', wali!.address!),
          _infoRow(Icons.people_outline, 'Hubungan', wali?.relationship ?? '-'),
          _infoRow(Icons.verified_user, 'Status Aktivasi', wali?.activationStatus ?? '-'),
          _infoRow(Icons.access_time, 'Login Terakhir',
              wali?.lastLoginAt != null
                  ? formatDateTime(wali!.lastLoginAt)
                  : '-'),
          const SizedBox(height: AppSpacing.xl),
          const Text('Aksi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.refresh, 'Refresh Data', AppColors.primary, () {
            invalidateWaliQueries(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Data dimuat ulang'),
                  backgroundColor: AppColors.primary),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.info_outline, 'Tentang Aplikasi', AppColors.info,
              () {
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
          }),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.lock_reset, 'Ubah PIN', AppColors.warning, () {
            context.push('/forgot-pin');
          }),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.logout, 'Keluar', AppColors.danger,
              () async => logoutWaliAndNavigate(context, ref)),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: AppColors.info, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Realtime Aktif',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info)),
                      Text(
                          'Auto-refresh saat ada perubahan Notifikasi, Chat, Tagihan, Pembayaran',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.info)),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
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
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
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
