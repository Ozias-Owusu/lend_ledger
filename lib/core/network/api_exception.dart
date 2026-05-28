import 'package:http/http.dart' as http;

import 'api_error_parser.dart';

enum ApiExceptionType {
  network,
  timeout,
  unauthorized,
  validation,
  server,
  unknown,
}

class ApiException implements Exception {
  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.rawBody,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final String? rawBody;

  factory ApiException.network([String? details]) {
    return ApiException(
      type: ApiExceptionType.network,
      message: details ?? 'Network connection lost. Please check your internet.',
    );
  }

  factory ApiException.timeout() {
    return ApiException(
      type: ApiExceptionType.timeout,
      message: 'Request timed out. Please try again.',
    );
  }

  factory ApiException.sessionExpired() {
    return ApiException(
      type: ApiExceptionType.unauthorized,
      message: 'Your session has expired. Please login again.',
      statusCode: 401,
    );
  }

  factory ApiException.fromResponse(http.Response response) {
    final parsed = ApiErrorParser.messageFromBody(response.body);
    final type = _typeFromStatus(response.statusCode);
    return ApiException(
      type: type,
      message: parsed.isEmpty ? _fallbackForStatus(response.statusCode) : parsed,
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  static ApiExceptionType _typeFromStatus(int statusCode) {
    if (statusCode == 401) return ApiExceptionType.unauthorized;
    if (statusCode >= 400 && statusCode < 500) return ApiExceptionType.validation;
    if (statusCode >= 500) return ApiExceptionType.server;
    return ApiExceptionType.unknown;
  }

  static String _fallbackForStatus(int statusCode) {
    if (statusCode == 401) return 'Invalid login credentials.';
    if (statusCode >= 500) {
      return 'Something went wrong on the server. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  String toString() => message;
}
