// Akademik hub — Tab 3.
// Pintu masuk ke 3 monitor screens: Absensi, Nilai, Honor Guru.
// Hanya berisi grid menu card yang navigasi ke nested routes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class AkademikHubScreen extends StatelessWidget {
  const AkademikHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akademik')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: [
          _HubCard(
            icon: Icons.check_circle_outline,
            label: 'Absensi',
            description: 'Monitor kehadiran santri per tanggal',
            color: AppColors.info,
            bg: AppColors.infoLight,
            onTap: () => context.push('/dashboard/akademik/absensi'),
          ),
          _HubCard(
            icon: Icons.star_outline,
            label: 'Nilai',
            description: 'Monitor nilai akademik per mapel',
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFEDE9FE),
            onTap: () => context.push('/dashboard/akademik/nilai'),
          ),
          _HubCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Honor Guru',
            description: 'Monitor honor guru per periode',
            color: AppColors.primary,
            bg: AppColors.primaryLight,
            onTap: () => context.push('/dashboard/akademik/honor-guru'),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
