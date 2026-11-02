// ConfirmDialog — reusable confirmation dialog dengan destructive action support.

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

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

Future<bool> showAsyncConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  String confirmText = 'Ya',
  String cancelText = 'Batal',
  bool destructive = false,
}) async {
  // First confirm
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
    destructive: destructive,
  );
  if (!confirmed) return false;
  // Execute action
  try {
    await onConfirm();
    return true;
  } catch (_) {
    rethrow;
  }
}
