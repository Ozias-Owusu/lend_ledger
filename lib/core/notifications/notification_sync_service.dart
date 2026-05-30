import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lend_ledger/core/notifications/local_notification_service.dart';
import 'package:lend_ledger/core/service_locator.dart';
import 'package:lend_ledger/models/notification_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the in-app inbox and badge in sync; shows device alerts when permitted.
class NotificationSyncService {
  NotificationSyncService({
    LocalNotificationService? localNotifications,
  }) : _local = localNotifications ?? LocalNotificationService();

  final LocalNotificationService _local;
  Timer? _timer;
  bool _syncing = false;
  bool _inboxPrimed = false;
  String? _activeUserKey;

  static const _shownIdsPrefix = 'shown_notification_ids_';
  static const _pollInterval = Duration(seconds: 30);

  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final ValueNotifier<List<AppNotification>> latestItems =
      ValueNotifier(const []);

  /// New unread item to surface as an in-app banner (cleared when dismissed).
  final ValueNotifier<AppNotification?> foregroundAlert =
      ValueNotifier(null);

  Future<bool> ensurePermission() async {
    await _local.initialize();
    return _local.requestPermission();
  }

  Future<void> processSystemLaunchTap() async {
    await _local.initialize();
    await _local.processLaunchTap();
  }

  Future<bool> hasPermission() => _local.hasPermission();

  void dismissForegroundAlert() => foregroundAlert.value = null;

  Future<void> start({required String userKey}) async {
    if (userKey.isEmpty) return;
    _timer?.cancel();
    _activeUserKey = userKey;
    _inboxPrimed = false;
    await poll();
    _timer = Timer.periodic(_pollInterval, (_) => poll());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _activeUserKey = null;
    _inboxPrimed = false;
    foregroundAlert.value = null;
  }

  /// Refreshes inbox + badge; device tray only when permission is granted.
  Future<void> poll() async {
    final pushToDevice =
        _activeUserKey != null && await _local.hasPermission();
    await syncInbox(pushToDevice: pushToDevice);
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value =
          await ServiceLocator.notificationsApi.fetchUnreadCount();
    } catch (_) {}
  }

  /// Handles an incoming FCM payload (foreground, background, or tap).
  Future<void> handleRemotePush(
    AppNotification notification, {
    required bool showSystemNotification,
  }) async {
    await _local.initialize();

    _mergeIntoInbox(notification);

    if (!notification.isRead) {
      if (showSystemNotification && await _local.hasPermission()) {
        await _local.showAppNotification(notification);
      }
      if (_activeUserKey != null) {
        foregroundAlert.value = notification;
      }
    }

    await refreshUnreadCount();
  }

  void _mergeIntoInbox(AppNotification notification) {
    if (notification.id.isEmpty) return;
    final existing = List<AppNotification>.from(latestItems.value);
    final index = existing.indexWhere((item) => item.id == notification.id);
    if (index >= 0) {
      existing[index] = notification;
    } else {
      existing.insert(0, notification);
    }
    latestItems.value = existing;
  }

  Future<NotificationListResult?> syncInbox({
    int page = 1,
    int pageSize = 50,
    bool pushToDevice = false,
  }) async {
    if (_syncing || _activeUserKey == null) return null;

    _syncing = true;
    try {
      final previousIds =
          latestItems.value.map((item) => item.id).toSet();

      final result = await ServiceLocator.notificationsApi.fetchNotifications(
        page: page,
        pageSize: pageSize,
        unreadOnly: false,
      );

      latestItems.value = result.items;
      await refreshUnreadCount();

      if (_inboxPrimed) {
        for (final item in result.items) {
          if (item.isRead || previousIds.contains(item.id)) continue;
          foregroundAlert.value = item;
          break;
        }
      } else {
        _inboxPrimed = true;
      }

      if (pushToDevice) {
        final unreadNew = result.items
            .where((item) => !item.isRead && !previousIds.contains(item.id))
            .toList();
        await _pushNewToDevice(unreadNew);
      }

      return result;
    } catch (_) {
      return null;
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushNewToDevice(List<AppNotification> items) async {
    final userKey = _activeUserKey;
    if (userKey == null) return;

    final shown = await _loadShownIds(userKey);
    for (final item in items) {
      if (item.isRead || shown.contains(item.id)) continue;
      await _local.showAppNotification(item);
      shown.add(item.id);
    }
    await _saveShownIds(userKey, shown);
  }

  Future<Set<String>> _loadShownIds(String userKey) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$_shownIdsPrefix$userKey');
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveShownIds(String userKey, Set<String> ids) async {
    final capped = ids.length > 500 ? ids.take(500).toList() : ids.toList();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$_shownIdsPrefix$userKey', jsonEncode(capped));
  }

  Future<void> clearShownIds(String userKey) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_shownIdsPrefix$userKey');
  }
}
