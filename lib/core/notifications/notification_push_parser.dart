import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lend_ledger/models/notification_models.dart';

/// Maps FCM [RemoteMessage] payloads to [AppNotification].
class NotificationPushParser {
  NotificationPushParser._();

  static AppNotification? fromRemoteMessage(RemoteMessage message) {
    final data = _normalizedData(message.data);
    if (data.isNotEmpty) {
      final id = data['id'] ?? data['notificationId'] ?? data['notification_id'];
      if (id != null && id.toString().isNotEmpty) {
        return AppNotification.fromJson({
          'id': id,
          'type': data['type'] ?? 'general',
          'title': data['title'] ?? message.notification?.title ?? 'Notification',
          'message': data['message'] ?? message.notification?.body ?? '',
          'entityType': data['entityType'] ?? data['entity_type'],
          'entityId': data['entityId'] ?? data['entity_id'],
          'isRead': data['isRead'] == 'true',
          'createdAt': data['createdAt'] ?? data['created_at'],
        });
      }
    }

    final notification = message.notification;
    if (notification == null) return null;

    return AppNotification(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type']?.toString() ?? 'general',
      title: notification.title ?? 'Notification',
      message: notification.body ?? '',
      entityType: data['entityType']?.toString(),
      entityId: data['entityId']?.toString(),
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  static Map<String, String> _normalizedData(Map<String, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
}
