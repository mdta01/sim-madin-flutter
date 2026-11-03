// Profile + logout.
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
    final client = ref.watch(supabaseClientProvider);
    final user = client.auth.currentUser;
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
                    user?.email?.isNotEmpty == true
                        ? user!.email![0].toUpperCase()
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
                      Text(user?.email ?? '-',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      const Text('Guru Madrasah',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _infoRow(Icons.alternate_email, 'User ID', user?.id ?? '-'),
          _infoRow(Icons.email_outlined, 'Email', user?.email ?? '-'),
          _infoRow(Icons.access_time, 'Login Terakhir',
              user?.lastSignInAt != null
                  ? formatDateTime(DateTime.parse(user!.lastSignInAt!))
                  : '-'),
          const SizedBox(height: AppSpacing.xl),
          const Text('Aksi',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.refresh, 'Refresh Data', AppColors.primary, () {
            invalidateGuruQueries(ref);
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
              applicationName: 'SIM MADIN — Guru',
              applicationVersion: '1.0.0+1',
              applicationLegalese:
                  'SIM Madrasah Diniyah — App Guru Madrasah\n© ${DateTime.now().year} MDTA Miftahul Ulum 01',
              children: [
                const SizedBox(height: AppSpacing.sm),
                const Text('Phase 4 — mobile_guru (akademik CRUD + ujian)',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          _actionBtn(Icons.logout, 'Keluar', AppColors.danger,
              () async => logoutAndNavigate(context, ref)),
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
                          'Auto-refresh saat ada perubahan Jadwal, Materi, Tugas, Pertemuan, Ujian, Chat',
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

Future<void> logoutAndNavigate(BuildContext context, WidgetRef ref) async {
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
  final client = ref.read(supabaseClientProvider);
  await client.auth.signOut();
  // ignore: unused_result
  await ref.read(authStorageProvider).clear();
  invalidateGuruQueries(ref);
  if (!context.mounted) return;
  context.go('/login');
}
