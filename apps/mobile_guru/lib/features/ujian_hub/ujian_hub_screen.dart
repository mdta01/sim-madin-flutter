// Ujian hub — Tab 4.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class UjianHubScreen extends StatelessWidget {
  const UjianHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ujian')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: [
          _MenuCard(
            label: 'Daftar Ujian',
            description: 'Lihat + buat ujian baru',
            icon: Icons.quiz_outlined,
            color: AppColors.danger,
            bg: AppColors.dangerLight,
            onTap: () => context.push('/dashboard/ujian/list'),
          ),
          _MenuCard(
            label: 'Buat Ujian Baru',
            description: 'Form create ujian',
            icon: Icons.add_circle_outline,
            color: AppColors.success,
            bg: AppColors.successLight,
            onTap: () => context.push('/dashboard/ujian/list/create'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  final String label;
  final String description;
  final IconData icon;
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
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
