// MonitorScaffold — reusable scaffold untuk semua monitor screen (read-only).
// Mempunyai AppBar dengan tombol back, body dengan refresh indicator,
// dan handling loading/error/empty states otomatis dari AsyncValue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'feedback_views.dart';

class MonitorScaffold<T> extends ConsumerWidget {
  const MonitorScaffold({
    super.key,
    required this.title,
    required this.asyncValue,
    required this.itemBuilder,
    this.itemCount,
    this.leading,
    this.actions,
    this.summary,
    this.onRefresh,
    this.emptyTitle = 'Tidak ada data',
    this.emptySubtitle,
  });

  final String title;
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(BuildContext, T) itemBuilder;
  final int? itemCount;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? summary; // Card di atas list (mis. total pemasukan)
  final Future<void> Function()? onRefresh;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: leading ??
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        actions: actions,
      ),
      body: asyncValue.when(
        loading: () => const LoadingSkeleton(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: onRefresh,
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: Icons.inbox_outlined,
              onRefresh: onRefresh,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              if (onRefresh != null) {
                await onRefresh!();
              } else {
                // Default: invalidate no-op — caller harus override onRefresh
                // atau gunakan invalidate di provider.
              }
            },
            child: ListView.builder(
              itemCount: items.length + (summary != null ? 1 : 0),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemBuilder: (context, index) {
                if (summary != null) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: summary!,
                    );
                  }
                  return itemBuilder(context, items[index - 1]);
                }
                return itemBuilder(context, items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
