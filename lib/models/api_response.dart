import 'dart:convert';

import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/models/auth/auth_response.dart';
import 'package:lend_ledger/models/auth/user_profile.dart';
import 'package:lend_ledger/models/notification_models.dart';

typedef JsonMapFactory<T> = T Function(Map<String, dynamic> json);

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(Object? value) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: fromJsonT(json['data']),
      errors: json['errors'],
    );
  }

  static ApiResponse<T> decodeBody<T>(
    String body,
    T? Function(Object? value) fromJsonT,
  ) {
    if (body.trim().isEmpty) {
      throw const FormatException('Empty API response body.');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected API response format.');
    }
    return ApiResponse.fromJson(
      Map<String, dynamic>.from(decoded),
      fromJsonT,
    );
  }

  static ApiResponse<AuthResponse> decodeAuth(String body) {
    return decodeBody(
      body,
      (value) {
        if (value == null) return null;
        if (value is! Map) {
          throw const FormatException('Auth data must be a JSON object.');
        }
        return AuthResponse.fromJson(Map<String, dynamic>.from(value));
      },
    );
  }

  static ApiResponse<void> decodeVoid(String body) {
    return decodeBody<void>(body, (value) => null);
  }

  static ApiResponse<UserProfile> decodeUserProfile(String body) {
    return decodeBody(
      body,
      (value) {
        if (value == null) return null;
        if (value is! Map) {
          throw const FormatException('User profile data must be a JSON object.');
        }
        return UserProfile.fromJson(Map<String, dynamic>.from(value));
      },
    );
  }

  static ApiResponse<NotificationListResult> decodeNotificationList(
    String body,
  ) {
    return decodeBody(
      body,
      (value) {
        if (value == null) return null;
        if (value is! Map) {
          throw const FormatException(
            'Notification list data must be a JSON object.',
          );
        }
        return NotificationListResult.fromJson(
          Map<String, dynamic>.from(value),
        );
      },
    );
  }

  static ApiResponse<int> decodeNotificationUnreadCount(String body) {
    return decodeBody(
      body,
      (value) {
        if (value == null) return null;
        if (value is! Map) {
          throw const FormatException(
            'Unread count data must be a JSON object.',
          );
        }
        final count = value['count'];
        if (count is int) return count;
        return int.tryParse(count?.toString() ?? '') ?? 0;
      },
    );
  }

  static ApiResponse<List<UserProfile>> decodeUserList(String body) {
    return decodeBody(
      body,
      (value) {
        if (value == null) return <UserProfile>[];
        if (value is! List) {
          throw const FormatException('User list data must be a JSON array.');
        }
        return value
            .whereType<Map>()
            .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  T requireData({String? fallbackMessage}) {
    if (!success || data == null) {
      throw ApiException(
        type: ApiExceptionType.validation,
        message: message.isNotEmpty
            ? message
            : (fallbackMessage ?? 'Request failed.'),
      );
    }
    return data as T;
  }

  void ensureSuccess({String? fallbackMessage}) {
    if (!success) {
      throw ApiException(
        type: ApiExceptionType.validation,
        message: message.isNotEmpty
            ? message
            : (fallbackMessage ?? 'Request failed.'),
      );
    }
  }
}
