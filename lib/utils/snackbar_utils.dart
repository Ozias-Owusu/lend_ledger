import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';

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
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  static void showError(BuildContext context, Object error) {
    show(
      context,
      messageFromError(error),
      backgroundColor: Colors.red.shade700,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green.shade700,
    );
  }

  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    Color? backgroundColor,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  static String messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.type) {
        case ApiExceptionType.network:
          return 'Network connection lost. Please check your internet.';
        case ApiExceptionType.timeout:
          return 'Request timed out. Please try again.';
        case ApiExceptionType.unauthorized:
          return error.message.isNotEmpty
              ? error.message
              : 'Your session has expired. Please login again.';
        case ApiExceptionType.validation:
          return error.message.isNotEmpty
              ? error.message
              : 'Please check your input and try again.';
        case ApiExceptionType.server:
          return error.message.isNotEmpty
              ? error.message
              : 'Something went wrong. Please try again.';
        case ApiExceptionType.unknown:
          return error.message.isNotEmpty
              ? error.message
              : 'Something went wrong. Please try again.';
      }
    }

    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return text;
  }
}
