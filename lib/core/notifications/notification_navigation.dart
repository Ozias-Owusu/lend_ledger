import 'package:flutter/material.dart';
import 'package:lend_ledger/app/app_keys.dart';
import 'package:lend_ledger/pages/notifications_page.dart';

/// Opens the notifications inbox when the user taps a system-tray notification.
class NotificationNavigation {
  NotificationNavigation._();

  static const _openInbox = '__inbox__';
  static String? _pendingNotificationId;

  static void queueOpen({String? notificationId}) {
    _pendingNotificationId = notificationId ?? _openInbox;
  }

  static Future<void> openFromTap({String? notificationId}) async {
    queueOpen(notificationId: notificationId);
    await processPending();
  }

  /// Call once the main navigator is ready (e.g. from [AppShellPage]).
  static Future<void> processPending() async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    final pending = _pendingNotificationId;
    if (pending == null) return;
    _pendingNotificationId = null;

    if (pending == _openInbox) {
      await nav.push<void>(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
      return;
    }

    await nav.push<void>(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(focusNotificationId: pending),
      ),
    );
  }

  static Future<void> openInbox() async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      queueOpen();
      return;
    }
    await nav.push<void>(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }
}
