import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lend_ledger/core/device/device_info_collector.dart';
import 'package:lend_ledger/core/notifications/local_notification_service.dart';
import 'package:lend_ledger/core/notifications/notification_navigation.dart';
import 'package:lend_ledger/core/notifications/notification_push_parser.dart';
import 'package:lend_ledger/core/service_locator.dart';
import 'package:lend_ledger/firebase_options.dart';

/// Top-level handler for FCM when the app is terminated or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notification = NotificationPushParser.fromRemoteMessage(message);
  if (notification == null || notification.isRead) return;

  final local = LocalNotificationService();
  await local.initialize();
  await local.showAppNotification(notification);
}

/// Firebase Cloud Messaging — system tray + tap-to-open navigation.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance =
      FirebaseMessagingService._();

  bool _initialized = false;
  String? _cachedToken;
  String? _pendingOpenNotificationId;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);

    if (Platform.isIOS) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _storePendingOpen(initial);
    }

    messaging.onTokenRefresh.listen((_) => registerTokenWithBackend());

    _initialized = true;
  }

  void _storePendingOpen(RemoteMessage message) {
    final notification = NotificationPushParser.fromRemoteMessage(message);
    _pendingOpenNotificationId = notification?.id ?? 'inbox';
  }

  /// Call when the app shell is ready to navigate after a cold-start notification tap.
  Future<void> processPendingOpen() async {
    final id = _pendingOpenNotificationId;
    if (id == null) return;
    _pendingOpenNotificationId = null;

    NotificationNavigation.queueOpen(
      notificationId: id == 'inbox' ? null : id,
    );
  }

  Future<String?> getToken() async {
    if (!isSupported || !_initialized) return null;
    try {
      _cachedToken = await FirebaseMessaging.instance.getToken();
      return _cachedToken;
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  Future<void> registerTokenWithBackend() async {
    if (!isSupported || !_initialized) return;

    final hasSession = await ServiceLocator.tokenStorage.hasRefreshToken();
    if (!hasSession) return;

    final token = await getToken();
    if (token == null || token.isEmpty) return;

    try {
      final device = await DeviceInfoCollector.collect();
      await ServiceLocator.notificationsApi.registerFcmToken(
        fcmToken: token,
        deviceName: device.deviceName,
        deviceType: device.deviceType,
        platform: device.platform,
      );
    } catch (e) {
      debugPrint('FCM token registration skipped: $e');
    }
  }

  Future<void> deleteToken() async {
    if (!isSupported || !_initialized) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      _cachedToken = null;
    } catch (e) {
      debugPrint('FCM deleteToken failed: $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = NotificationPushParser.fromRemoteMessage(message);
    if (notification == null) return;

    await ServiceLocator.notificationSync.handleRemotePush(
      notification,
      showSystemNotification: true,
    );
  }

  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    await _handleOpen(message);
  }

  Future<void> _handleOpen(RemoteMessage message) async {
    final notification = NotificationPushParser.fromRemoteMessage(message);
    if (notification != null) {
      await ServiceLocator.notificationSync.handleRemotePush(
        notification,
        showSystemNotification: false,
      );
      await NotificationNavigation.openFromTap(notificationId: notification.id);
    } else {
      await ServiceLocator.notificationSync.poll();
      await NotificationNavigation.openInbox();
    }
  }
}
