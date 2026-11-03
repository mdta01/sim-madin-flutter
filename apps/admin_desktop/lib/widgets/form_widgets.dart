// DataTable helpers + form fields + confirm dialog untuk desktop.

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Generic DataTable dengan sort, search, pagination, row tap.
///
/// Cara pakai:
/// ```dart
/// DataTableHelper<UserModel>(
///   columns: [
///     DataColumn(label: Text('Email'), onSort: (i, asc) => ...),
///     DataColumn(label: Text('Name')),
///     DataColumn(label: Text('Actions')),
///   ],
///   rows: list.map((u) => DataRow(
///     cells: [
///       DataCell(Text(u.email)),
///       DataCell(Text(u.name)),
///       DataCell(Row(children: [IconButton(...edit), IconButton(...delete)])),
///     ],
///   )).toList(),
///   onRefresh: () => ref.invalidate(userListProvider),
/// ).build(context)
/// ```
class DataTableHelper<T> {
  DataTableHelper({
    required this.columns,
    required this.rows,
    this.onRefresh,
    this.searchController,
    this.searchHint,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final VoidCallback? onRefresh;
  final TextEditingController? searchController;
  final String? searchHint;

  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar: search + refresh
        if (searchController != null || onRefresh != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (searchController != null)
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: searchHint ?? 'Cari...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (searchController != null && onRefresh != null)
                  const SizedBox(width: AppSpacing.sm),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),
        // Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                columns: columns,
                rows: rows,
                headingRowHeight: 48,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                horizontalMargin: 16,
                columnSpacing: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Confirm dialog desktop style.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Ya',
  String cancelText = 'Batal',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Form field dengan label di atas (desktop pattern).
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Empty cell with placeholder text.
class EmptyCell extends StatelessWidget {
  const EmptyCell({super.key, this.text = '-'});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: AppColors.textMuted));
  }
}
