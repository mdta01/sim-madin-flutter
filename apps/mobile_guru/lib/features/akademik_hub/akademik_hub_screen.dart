// Akademik hub — Tab 3. Grid menu ke 9 akademik screens.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class AkademikHubScreen extends StatelessWidget {
  const AkademikHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('Absensi', Icons.check_circle_outline, AppColors.success,
          AppColors.successLight, '/dashboard/akademik/absensi'),
      _MenuItem('Nilai', Icons.star_outline, AppColors.primary,
          AppColors.primaryLight, '/dashboard/akademik/nilai'),
      _MenuItem('Materi', Icons.book_outlined, AppColors.info,
          AppColors.infoLight, '/dashboard/akademik/materi'),
      _MenuItem('Tugas', Icons.assignment_outlined, AppColors.success,
          AppColors.successLight, '/dashboard/akademik/tugas'),
      _MenuItem('Pertemuan', Icons.event_outlined, AppColors.primary,
          AppColors.primaryLight, '/dashboard/akademik/pertemuan'),
      _MenuItem('Perkembangan', Icons.trending_up, AppColors.success,
          AppColors.successLight, '/dashboard/akademik/perkembangan'),
      _MenuItem('Jadwal', Icons.calendar_month_outlined, AppColors.info,
          AppColors.infoLight, '/dashboard/akademik/jadwal'),
      _MenuItem('Chat Wali', Icons.chat_outlined, const Color(0xFF7C3AED),
          const Color(0xFFEDE9FE), '/dashboard/akademik/chat'),
      _MenuItem('Pengumuman', Icons.campaign_outlined, AppColors.warning,
          AppColors.warningLight, '/dashboard/akademik/pengumuman'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akademik')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: items
            .map((item) => _MenuCard(item: item))
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final String location;
  const _MenuItem(this.label, this.icon, this.color, this.bg, this.location);
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});
  final _MenuItem item;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(item.location),
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
                color: item.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(item.icon, color: item.color, size: 32),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
