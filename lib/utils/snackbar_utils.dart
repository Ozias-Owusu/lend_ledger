import 'package:flutter/material.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/user_friendly_errors.dart';
import 'package:lend_ledger/widgets/app_error_dialog.dart';

class SnackbarUtils {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.body(color: AppTheme.textPrimary, fontSize: 14),
        ),
        backgroundColor: backgroundColor ?? Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Shows a readable error dialog instead of a fleeting red snackbar.
  static Future<void> showError(
    BuildContext context,
    Object error, {
    String? title,
  }) {
    return AppErrorDialog.show(context, error: error, title: title);
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: const Color(0xFFE8F5E9),
      duration: const Duration(seconds: 3),
    );
  }

  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    Color? backgroundColor,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.body(color: AppTheme.textPrimary, fontSize: 14),
        ),
        backgroundColor: backgroundColor ?? Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Used by snackbars or brief inline hints; prefer [showError] for failures.
  static String messageFromError(Object error) {
    return UserFriendlyErrors.message(error);
  }
}
