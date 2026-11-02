// Reusable widgets untuk mobile_guru.

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Pill button untuk pilihan (kelas/mapel/type/dll).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
            color: active ? AppColors.primary : AppColors.text,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400),
      ),
    );
  }
}

/// Horizontal scrollable list of pills for picking one option.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  final List<T> items;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map((item) => PillButton(
                  label: labelOf(item),
                  active: selected == item,
                  onTap: () => onSelected(item),
                ))
            .toList(),
      ),
    );
  }
}

/// Card berisi info santri + status badge di kanan.
class SantriInfoCard extends StatelessWidget {
  const SantriInfoCard({
    super.key,
    required this.name,
    this.nis,
    this.kelas,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String? nis;
  final String? kelas;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          [if (nis != null) 'NIS: $nis', if (kelas != null) kelas]
              .join(' • '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Modal bottom sheet untuk form input.
Future<T?> showFormModal<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(builder: builder),
        ],
      ),
    ),
  );
}

/// Label + child helper untuk form field.
///
/// Note: named `FormFieldLabel` to avoid clash with Flutter's built-in
/// `FormField` widget from `package:flutter/widgets.dart`.
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

/// Numeric input field untuk angka (0-100).
class ScoreInput extends StatelessWidget {
  const ScoreInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxValue = 100,
    this.hint = '0',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int maxValue;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(value);
    final isPassing = parsed != null && parsed >= 70;
    final isFailing = parsed != null && parsed > 0 && parsed < 70;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border.all(
          color: isPassing
              ? AppColors.success
              : isFailing
                  ? AppColors.danger
                  : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 3,
        controller: TextEditingController(text: value),
        style: TextStyle(
          color: isPassing
              ? AppColors.success
              : isFailing
                  ? AppColors.danger
                  : AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (v) {
          final digits = v.replaceAll(RegExp(r'[^\d]'), '').substring(0, 3);
          final num = int.tryParse(digits) ?? 0;
          if (num > maxValue) return;
          onChanged(digits);
        },
      ),
    );
  }
}
