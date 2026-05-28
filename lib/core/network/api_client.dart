import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lend_ledger/config/api_config.dart';
import 'package:lend_ledger/core/auth/token_storage_service.dart';
import 'package:lend_ledger/core/device/device_info_collector.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/models/api_response.dart';
import 'package:lend_ledger/models/auth/auth_requests.dart';
import 'package:lend_ledger/models/auth/auth_response.dart';
import 'package:lend_ledger/models/auth_tokens.dart';

typedef SessionExpiredCallback = void Function();

class ApiClient {
  ApiClient({
    required TokenStorageService tokenStorage,
    http.Client? client,
    this.onSessionExpired,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorageService _tokenStorage;
  final http.Client _client;
  final SessionExpiredCallback? onSessionExpired;

  Completer<void>? _refreshCompleter;

  static bool isPublicEndpoint(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/register') ||
        normalized.contains('/auth/login') ||
        normalized.contains('/auth/refresh') ||
        normalized.contains('/auth/forgot-password') ||
        normalized.contains('/auth/reset-password');
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.get(
        Uri.parse(ApiConfig.endpoint(path)),
        headers: await _buildHeaders(
          authenticated: authenticated,
          extra: headers,
          includeJsonContentType: false,
        ),
      ),
      path: path,
      authenticated: authenticated,
    );
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.post(
        Uri.parse(ApiConfig.endpoint(path)),
        headers: await _buildHeaders(authenticated: authenticated, extra: headers),
        body: body == null ? null : _encodeBody(body),
      ),
      path: path,
      authenticated: authenticated,
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.put(
        Uri.parse(ApiConfig.endpoint(path)),
        headers: await _buildHeaders(authenticated: authenticated, extra: headers),
        body: body == null ? null : _encodeBody(body),
      ),
      path: path,
      authenticated: authenticated,
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.patch(
        Uri.parse(ApiConfig.endpoint(path)),
        headers: await _buildHeaders(authenticated: authenticated, extra: headers),
        body: body == null ? null : _encodeBody(body),
      ),
      path: path,
      authenticated: authenticated,
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      () async => _client.delete(
        Uri.parse(ApiConfig.endpoint(path)),
        headers: await _buildHeaders(authenticated: authenticated, extra: headers),
        body: body == null ? null : _encodeBody(body),
      ),
      path: path,
      authenticated: authenticated,
    );
  }

  Future<http.Response> postPublic(String path, {Object? body}) {
    return post(path, body: body, authenticated: false);
  }

  Future<http.StreamedResponse> sendMultipart({
    required String path,
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    String method = 'POST',
  }) async {
    Future<http.StreamedResponse> sendRequest() async {
      final request = http.MultipartRequest(
        method,
        Uri.parse(ApiConfig.endpoint(path)),
      );
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.addAll(files);
      final headers = await _buildHeaders(
        authenticated: true,
        includeJsonContentType: false,
      );
      request.headers.addAll(headers);
      return _client.send(request);
    }

    try {
      var response = await sendRequest();
      if (response.statusCode == 401 && !isPublicEndpoint(path)) {
        final refreshed = await _refreshTokensOnce() != null;
        if (!refreshed) {
          throw ApiException.sessionExpired();
        }
        response = await sendRequest();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw ApiException.fromResponse(
          http.Response(body, response.statusCode),
        );
      }
      return response;
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.timeout();
    }
  }

  Future<bool> refreshTokens() async => (await refreshSession()) != null;

  Future<AuthResponse?> refreshSession() => _refreshTokensOnce();

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
    Map<String, String>? extra,
    bool includeJsonContentType = true,
  }) async {
    final headers = <String, String>{
      ...ApiConfig.defaultHeaders,
      ...?extra,
    };
    if (!includeJsonContentType) {
      headers.remove('Content-Type');
    }

    if (authenticated) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required String path,
    required bool authenticated,
  }) async {
    try {
      var response = await request();
      if (authenticated &&
          response.statusCode == 401 &&
          !isPublicEndpoint(path)) {
        final refreshed = await _refreshTokensOnce() != null;
        if (!refreshed) {
          throw ApiException.sessionExpired();
        }
        response = await request();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromResponse(response);
      }
      return response;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.timeout();
    }
  }

  Future<AuthResponse?> _refreshTokensOnce() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      final access = await _tokenStorage.getAccessToken();
      final refresh = await _tokenStorage.getRefreshToken();
      if (access == null || refresh == null) return null;
      return AuthResponse(
        accessToken: access,
        refreshToken: refresh,
        accessTokenExpiresAt: DateTime.now(),
        refreshTokenExpiresAt: DateTime.now(),
        userId: '',
        email: await _tokenStorage.getUserEmail() ?? '',
        fullName: await _tokenStorage.getUserName() ?? '',
        roles: const [],
      );
    }

    _refreshCompleter = Completer<void>();
    AuthResponse? refreshedAuth;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _handleSessionExpired();
        return null;
      }

      final device = await DeviceInfoCollector.collect();
      final response = await _client.post(
        Uri.parse(ApiConfig.endpoint('/api/Auth/refresh')),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(
          RefreshTokenRequest(
            refreshToken: refreshToken,
            deviceName: device.deviceName,
          ).toJson(),
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final envelope = ApiResponse.decodeAuth(response.body);
        if (!envelope.success || envelope.data == null) {
          await _handleSessionExpired();
          return null;
        }
        refreshedAuth = envelope.data;
        await _tokenStorage.saveTokens(
          AuthTokens.fromAuthResponse(refreshedAuth!),
        );
        return refreshedAuth;
      }

      await _handleSessionExpired();
      return null;
    } catch (_) {
      await _handleSessionExpired();
      return null;
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  Future<void> _handleSessionExpired() async {
    await _tokenStorage.clearAll();
    onSessionExpired?.call();
  }

  String _encodeBody(Object body) {
    if (body is String) return body;
    return jsonEncode(body);
  }
}
