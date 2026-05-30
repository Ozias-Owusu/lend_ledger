import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lend_ledger/core/notifications/notification_channels.dart';
import 'package:lend_ledger/core/notifications/notification_navigation.dart';
import 'package:lend_ledger/models/notification_models.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a notification tap when the app was terminated (background isolate).
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  SharedPreferences.getInstance().then((sp) {
    sp.setString('pending_notification_tap_id', payload);
  });
}

/// Shows alerts in the Android status bar / iOS notification center.
class LocalNotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      for (final channel in NotificationChannels.all) {
        await androidPlugin?.createNotificationChannel(
          channel.toAndroidChannel(),
        );
      }
    }

    _initialized = true;
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      NotificationNavigation.openInbox();
      return;
    }
    NotificationNavigation.openFromTap(notificationId: payload);
  }

  /// Handles cold start when the user tapped a notification while the app was closed.
  Future<void> processLaunchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      final sp = await SharedPreferences.getInstance();
      final stored = sp.getString('pending_notification_tap_id');
      if (stored != null && stored.isNotEmpty) {
        await sp.remove('pending_notification_tap_id');
        NotificationNavigation.queueOpen(notificationId: stored);
      }
      return;
    }

    final payload = details!.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      NotificationNavigation.queueOpen(notificationId: payload);
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) return true;
      return status.isLimited || status.isProvisional;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited || status.isProvisional;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  Future<void> showAppNotification(AppNotification notification) async {
    if (!_initialized) return;

    final channel = NotificationChannels.forType(notification.type);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        ticker: notification.title,
        styleInformation: BigTextStyleInformation(notification.message),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.message,
      notificationDetails: details,
      payload: notification.id,
    );
  }
}
