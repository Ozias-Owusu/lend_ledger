import 'package:flutter/material.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/user_friendly_errors.dart';

/// A clear, readable error dialog for end users (replaces long red snackbars).
class AppErrorDialog extends StatelessWidget {
  const AppErrorDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static Future<void> show(
    BuildContext context, {
    required Object error,
    String? title,
  }) {
    if (!context.mounted) return Future.value();
    final resolved = UserFriendlyErrors.resolve(error, titleOverride: title);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppErrorDialog(
        title: resolved.title,
        message: resolved.message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.softRose.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppTheme.softRose,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.body(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: AppTheme.body(
            fontSize: 15,
            height: 1.45,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.softRose,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
