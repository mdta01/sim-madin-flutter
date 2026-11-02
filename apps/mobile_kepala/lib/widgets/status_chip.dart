// StatusChip — badge berwarna untuk status (HADIR/SAKIT/LUNAS/VERIFIED/DRAFT).
// Warna diambil dari StatusStyles di shared/theme.dart.

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    required this.style,
    this.compact = false,
  });

  final String status;
  final StatusStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style.color,
        ),
      ),
    );
  }
}

/// Helper untuk lookup absensi status chip.
StatusStyle absensiStatusStyle(String status) {
  return StatusStyles.forStatus(StatusStyles.absensi, status) ??
      const StatusStyle(label: '-', color: AppColors.textMuted, bg: AppColors.border);
}

/// Helper untuk lookup tagihan status chip.
StatusStyle tagihanStatusStyle(String status) {
  return StatusStyles.forStatus(StatusStyles.tagihan, status) ??
      const StatusStyle(label: '-', color: AppColors.textMuted, bg: AppColors.border);
}

/// Helper untuk lookup payment status chip (verifikasi flow).
StatusStyle paymentStatusStyle(String status) {
  return StatusStyles.forStatus(StatusStyles.verify, status) ??
      const StatusStyle(label: '-', color: AppColors.textMuted, bg: AppColors.border);
}

/// Helper untuk lookup honor guru status chip — fallback manual
/// karena tidak ada di StatusStyles.
StatusStyle honorGuruStatusStyle(String status) {
  switch (status) {
    case HonorGuruStatus.draft:
      return const StatusStyle(
        label: 'Draft',
        color: AppColors.textMuted,
        bg: Color(0xFFF1F5F9),
      );
    case HonorGuruStatus.disetujui:
      return const StatusStyle(
        label: 'Disetujui',
        color: AppColors.info,
        bg: AppColors.infoLight,
      );
    case HonorGuruStatus.dibayarkan:
      return const StatusStyle(
        label: 'Dibayarkan',
        color: AppColors.success,
        bg: AppColors.successLight,
      );
    default:
      return StatusStyle(label: status, color: AppColors.text, bg: AppColors.border);
  }
}
