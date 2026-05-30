import 'package:lend_ledger/core/network/api_client.dart';
import 'package:lend_ledger/models/api_response.dart';
import 'package:lend_ledger/models/notification_models.dart';

class NotificationsApiService {
  NotificationsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationListResult> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final query = Uri(queryParameters: {
      'page': '$page',
      'pageSize': '$pageSize',
      'unreadOnly': unreadOnly.toString(),
    }).query;

    final response = await _apiClient.get('/api/Notifications?$query');
    final envelope = ApiResponse.decodeNotificationList(response.body);
    return envelope.requireData(
      fallbackMessage: 'Could not load notifications.',
    );
  }

  Future<int> fetchUnreadCount() async {
    final response =
        await _apiClient.get('/api/Notifications/unread-count');
    final envelope =
        ApiResponse.decodeNotificationUnreadCount(response.body);
    return envelope.requireData(
      fallbackMessage: 'Could not load unread count.',
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await _apiClient.patch(
      '/api/Notifications/$notificationId/read',
    );
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not mark notification as read.',
    );
  }

  Future<void> markAllAsRead() async {
    final response =
        await _apiClient.post('/api/Notifications/mark-all-read');
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not mark all notifications as read.',
    );
  }

  /// Registers the device FCM token for server-side push (requires backend endpoint).
  Future<void> registerFcmToken({
    required String fcmToken,
    required String deviceName,
    required String deviceType,
    required String platform,
  }) async {
    final response = await _apiClient.post(
      '/api/Notifications/fcm-token',
      body: {
        'fcmToken': fcmToken,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'platform': platform,
      },
    );
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not register push token.',
    );
  }
}
