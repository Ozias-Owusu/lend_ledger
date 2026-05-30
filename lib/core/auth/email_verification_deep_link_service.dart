import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:lend_ledger/app/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:lend_ledger/core/auth/email_verification_link_handler.dart';
import 'package:lend_ledger/pages/verify_email_page.dart';

class EmailVerificationDeepLinkService {
  EmailVerificationDeepLinkService() : _appLinks = AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> initialize() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(initial);
    }

    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleUri(Uri uri) {
    final parsed = EmailVerificationLinkHandler.parse(uri);
    if (parsed == null) return;
    _openVerifyPage(parsed.userId, parsed.token);
  }

  void _openVerifyPage(String userId, String token) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => VerifyEmailPage(
          userId: userId,
          token: token,
          preferGet: true,
        ),
      ),
    );
  }
}
