// MonitorScaffold — reusable scaffold untuk semua monitor screen (read-only).
// Mempunyai AppBar dengan tombol back, body dengan refresh indicator,
// dan handling loading/error/empty states otomatis dari AsyncValue.
//
// Parameter:
//   title        — AppBar title
//   asyncValue   — AsyncValue<List<T>> untuk data list
//   itemBuilder  — builder per item
//   filterBar    — widget di atas list (dropdown filter, date picker, dll.)
//   summary      — card di atas list (mis. total pemasukan, stats card)
//   onRefresh    — callback untuk pull-to-refresh
//   actions      — AppBar actions
//   emptyTitle   — title untuk empty state
//   emptySubtitle — subtitle untuk empty state
//   errorBuilder — custom error builder (default: friendlyError(err))

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
    this.filterBar,
    this.summary,
    this.onRefresh,
    this.emptyTitle = 'Tidak ada data',
    this.emptySubtitle,
    this.errorBuilder,
  });

  final String title;
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(BuildContext, T) itemBuilder;
  final int? itemCount;
  final Widget? leading;
  final List<Widget>? actions;
  /// Widget di atas list — mis. dropdown filter atau date picker.
  final Widget? filterBar;
  /// Card di atas list (mis. summary stats, total pemasukan).
  final Widget? summary;
  final Future<void> Function()? onRefresh;
  final String emptyTitle;
  final String? emptySubtitle;
  /// Custom error builder — default pakai ErrorView dengan friendlyError.
  final Widget Function(Object error)? errorBuilder;

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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Jika ada filterBar, tampilkan di Column atas + Expanded list di bawah.
    if (filterBar != null) {
      return Column(
        children: [
          filterBar!,
          Expanded(child: _buildAsyncContent(context)),
        ],
      );
    }
    return _buildAsyncContent(context);
  }

  Widget _buildAsyncContent(BuildContext context) {
    return asyncValue.when(
      loading: () => const LoadingSkeleton(),
      error: (err, _) {
        if (errorBuilder != null) {
          return errorBuilder!(err);
        }
        return ErrorView(
          message: friendlyError(err),
          onRetry: onRefresh,
        );
      },
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
    );
  }
}
