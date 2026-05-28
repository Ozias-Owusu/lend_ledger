import 'package:flutter/material.dart';
import 'package:lend_ledger/app/app_keys.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';

/// Sends users to the sign-in entry flow when auth fully fails.
void navigateToSignInLanding({
  String message = 'Your session has expired. Please login again.',
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger != null) {
    SnackbarUtils.showWithMessenger(
      messenger,
      message,
      backgroundColor: Colors.red.shade700,
    );
  }

  rootNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LandingPage()),
    (_) => false,
  );
}
