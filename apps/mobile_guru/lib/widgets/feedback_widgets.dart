// Feedback widgets — copy dari mobile_bendahara (sengaja tidak di-shared cross-app).

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'Tidak ada data',
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onRefresh,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh')),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: const TextStyle(fontSize: 14, color: AppColors.danger),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi')),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.itemCount = 6});
  final int itemCount;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                color: AppColors.border,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(width: 200, height: 12, color: AppColors.border),
              const SizedBox(height: AppSpacing.xs),
              Container(width: 140, height: 12, color: AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
    this.subtitle,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.compact = false,
  });
  final String label;
  final Color color;
  final Color bg;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// Status helpers
StatusStyle absensiStatusStyle(String s) {
  switch (s) {
    case AbsensiStatus.hadir:
      return const StatusStyle(
          label: 'Hadir', color: AppColors.success, bg: AppColors.successLight);
    case AbsensiStatus.sakit:
      return const StatusStyle(
          label: 'Sakit', color: AppColors.warning, bg: AppColors.warningLight);
    case AbsensiStatus.izin:
      return const StatusStyle(
          label: 'Izin', color: AppColors.info, bg: AppColors.infoLight);
    case AbsensiStatus.alfa:
      return const StatusStyle(
          label: 'Alfa', color: AppColors.danger, bg: AppColors.dangerLight);
    default:
      return StatusStyle(label: s, color: AppColors.text, bg: AppColors.border);
  }
}

StatusStyle ujianStatusStyle(String s) {
  switch (s) {
    case UjianStatus.draft:
      return const StatusStyle(
          label: 'Draft', color: AppColors.textMuted, bg: Color(0xFFF1F5F9));
    case UjianStatus.published:
      return const StatusStyle(
          label: 'Terbit', color: AppColors.success, bg: AppColors.successLight);
    case UjianStatus.ongoing:
      return const StatusStyle(
          label: 'Berlangsung',
          color: AppColors.warning,
          bg: AppColors.warningLight);
    case UjianStatus.finished:
      return const StatusStyle(
          label: 'Selesai', color: AppColors.info, bg: AppColors.infoLight);
    case UjianStatus.cancelled:
      return const StatusStyle(
          label: 'Batal', color: AppColors.danger, bg: AppColors.dangerLight);
    default:
      return StatusStyle(label: s, color: AppColors.text, bg: AppColors.border);
  }
}

StatusStyle pembinaanSeverityStyle(String s) {
  switch (s) {
    case PembinaanSeverity.ringan:
      return const StatusStyle(
          label: 'Ringan', color: AppColors.success, bg: AppColors.successLight);
    case PembinaanSeverity.sedang:
      return const StatusStyle(
          label: 'Sedang', color: AppColors.warning, bg: AppColors.warningLight);
    case PembinaanSeverity.berat:
      return const StatusStyle(
          label: 'Berat', color: AppColors.danger, bg: AppColors.dangerLight);
    default:
      return StatusStyle(label: s, color: AppColors.text, bg: AppColors.border);
  }
}
