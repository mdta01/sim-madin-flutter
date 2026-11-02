// Keuangan hub — Tab 4.
// Pintu masuk ke 3 monitor screens: Tagihan, Pembayaran, Laporan Keuangan.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class KeuanganHubScreen extends StatelessWidget {
  const KeuanganHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keuangan')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: [
          _HubCard(
            icon: Icons.receipt_long,
            label: 'Tagihan',
            description: 'Monitor tagihan santri + tunggakan',
            color: AppColors.warning,
            bg: AppColors.warningLight,
            onTap: () => context.push('/dashboard/keuangan/tagihan'),
          ),
          _HubCard(
            icon: Icons.payment,
            label: 'Pembayaran',
            description: 'Riwayat + status verifikasi pembayaran',
            color: AppColors.success,
            bg: AppColors.successLight,
            onTap: () => context.push('/dashboard/keuangan/pembayaran'),
          ),
          _HubCard(
            icon: Icons.bar_chart,
            label: 'Laporan Keuangan',
            description: 'Transaksi kas + arus kas per periode',
            color: AppColors.primary,
            bg: AppColors.primaryLight,
            onTap: () => context.push('/dashboard/keuangan/laporan'),
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
