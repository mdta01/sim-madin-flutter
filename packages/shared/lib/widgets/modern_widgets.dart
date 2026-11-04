// ============================================================================
// SIM MADIN — Modern Reusable Widgets
// ============================================================================
// Widget-widget reusable modern dengan shadow, gradient, dan rounded corners.
// Dipakai di semua 4 mobile apps untuk konsistensi visual.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Modern card dengan shadow halus + rounded corners.
/// Pakai ini alih-alih Card default untuk tampilan yang lebih modern.
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = CardElevation.level1,
    this.borderRadius,
    this.border,
    this.gradient,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final CardElevation elevation;
  final double? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lg;
    final shadow = switch (elevation) {
      CardElevation.none => <BoxShadow>[],
      CardElevation.level1 => AppColors.cardShadow,
      CardElevation.level2 => AppColors.elevatedShadow,
    };

    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? (gradient != null ? null : AppColors.card),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.border, width: 0.5),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

enum CardElevation { none, level1, level2 }

/// Section header dengan title + optional action button (mis. "Lihat Semua").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h4),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      style: AppTextStyles.body3
                          .copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!,
                style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}

/// Stat card dengan icon + value + label, modern design.
/// Gradient optional (untuk KPI utama).
class ModernStatCard extends StatelessWidget {
  const ModernStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.subtitle,
    this.onTap,
    this.useGradient = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: useGradient ? AppColors.primaryGradient : null,
      backgroundColor: useGradient ? null : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: useGradient
                  ? AppColors.white.withValues(alpha: 0.2)
                  : bgColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon,
                size: 22,
                color: useGradient ? AppColors.white : color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTextStyles.h2.copyWith(
                  color: useGradient ? AppColors.white : AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.body3.copyWith(
                  color: useGradient
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.textMuted)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: AppTextStyles.caption.copyWith(
                    color: useGradient
                        ? AppColors.white.withValues(alpha: 0.7)
                        : AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Modern status badge / chip dengan rounded pill shape.
class ModernChip extends StatelessWidget {
  const ModernChip({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? 2 : AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Empty state modern dengan icon besar + title + subtitle + action.
class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!,
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state modern dengan icon + message + retry button.
class ModernErrorView extends StatelessWidget {
  const ModernErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Terjadi Kesalahan',
                style: AppTextStyles.h4, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton dengan shimmer effect (sederhana, tanpa animasi).
class ModernLoadingSkeleton extends StatelessWidget {
  const ModernLoadingSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 80,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        height: itemHeight,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 180,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar dengan inisial + gradient background.
/// Dipakai untuk profile header, list items dengan avatar.
class ModernAvatar extends StatelessWidget {
  const ModernAvatar({
    super.key,
    this.name,
    this.photoUrl,
    this.radius = 24,
    this.gradient,
  });

  final String? name;
  final String? photoUrl;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient ?? AppColors.primaryGradient,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}

/// FAB modern dengan shadow + gradient.
class ModernFab extends StatelessWidget {
  const ModernFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.gradient,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: gradient ?? AppColors.primaryGradient,
        boxShadow: AppColors.primaryShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(label,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive container yang membatasi max width di desktop/tablet.
/// Phone = full width, Tablet = max 800, Desktop = max 1200.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final w = maxWidth ?? Breakpoints.maxContentWidth(context);
    if (w == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: child,
      ),
    );
  }
}

/// Responsive grid yang adaptif berdasarkan lebar device.
/// Phone = 1 col (atau custom), Tablet = 2 cols, Desktop = 3 cols.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.phoneColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
    this.childAspectRatio = 1.0,
  });

  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int columns;
    if (width < Breakpoints.phone) {
      columns = phoneColumns;
    } else if (width < Breakpoints.tablet) {
      columns = tabletColumns;
    } else {
      columns = desktopColumns;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}
