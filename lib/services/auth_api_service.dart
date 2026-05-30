import 'package:lend_ledger/core/auth/token_storage_service.dart';
import 'package:lend_ledger/core/device/device_info_collector.dart';
import 'package:lend_ledger/core/network/api_client.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/models/api_response.dart';
import 'package:lend_ledger/models/auth/auth_requests.dart';
import 'package:lend_ledger/models/auth/auth_response.dart';
import 'package:lend_ledger/models/auth/user_profile.dart';
import 'package:lend_ledger/models/auth_tokens.dart';

class AuthApiService {
  AuthApiService({
    required ApiClient apiClient,
    required TokenStorageService tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  static const List<String> availableRoles = [
    'Admin',
    'LoanOfficer',
    'Cashier',
    'Customer',
  ];

  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  Future<AuthResponse> login({
    required String email,
    required String password,
    LoginDeviceMetadata? deviceMetadata,
  }) async {
    final device = deviceMetadata ?? await DeviceInfoCollector.collect();
    final request = LoginRequest(
      email: email.trim(),
      password: password,
      deviceName: device.deviceName,
      deviceType: device.deviceType,
      platform: device.platform,
    );

    final response = await _apiClient.postPublic(
      '/api/Auth/login',
      body: request.toJson(),
    );
    final auth = _parseAuthResponse(response.body);
    await _persist(auth, fallbackEmail: email);
    return auth;
  }

  Future<String> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    final response = await _apiClient.postPublic(
      '/api/Auth/register',
      body: {
        'fullName': fullName,
        'email': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
        'role': role,
      },
    );

    final envelope = ApiResponse.decodeVoid(response.body);
    envelope.ensureSuccess(fallbackMessage: 'Registration failed.');
    if (envelope.message.isNotEmpty) return envelope.message;
    return 'Account created. Check your email to verify before signing in.';
  }

  Future<AuthResponse> verifyEmail({
    required String userId,
    required String token,
  }) async {
    final response = await _apiClient.postPublic(
      '/api/Auth/verify-email',
      body: VerifyEmailRequest(userId: userId.trim(), token: token.trim()).toJson(),
    );
    final auth = _parseAuthResponse(response.body);
    await _persist(auth);
    return auth;
  }

  Future<AuthResponse> verifyEmailFromLink({
    required String userId,
    required String token,
  }) async {
    final query = Uri(queryParameters: {
      'userId': userId.trim(),
      'token': token.trim(),
    }).query;
    final response = await _apiClient.getPublic('/api/Auth/verify-email?$query');
    final auth = _parseAuthResponse(response.body);
    await _persist(auth);
    return auth;
  }

  Future<String> resendVerificationEmail(String email) async {
    final response = await _apiClient.postPublic(
      '/api/Auth/resend-verification',
      body: ResendVerificationRequest(email: email).toJson(),
    );
    final envelope = ApiResponse.decodeVoid(response.body);
    envelope.ensureSuccess(
      fallbackMessage: 'Could not resend verification email.',
    );
    if (envelope.message.isNotEmpty) return envelope.message;
    return 'Verification email sent.';
  }

  Future<UserProfile> getCurrentUser() async {
    final response = await _apiClient.get('/api/Auth/users/me');
    final envelope = ApiResponse.decodeUserProfile(response.body);
    return envelope.requireData(
      fallbackMessage: 'Could not load your profile.',
    );
  }

  Future<List<UserProfile>> getAllUsers() async {
    final response = await _apiClient.get('/api/Auth/users');
    final envelope = ApiResponse.decodeUserList(response.body);
    if (!envelope.success) {
      throw ApiException(
        type: ApiExceptionType.validation,
        message: envelope.message.isNotEmpty
            ? envelope.message
            : 'Could not load users.',
      );
    }
    return envelope.data ?? [];
  }

  Future<void> deleteUser(String userId) async {
    final response = await _apiClient.delete('/api/Auth/users/$userId');
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not delete user.',
    );
  }

  Future<AuthResponse> refreshTokens() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException.sessionExpired();
    }

    final auth = await _apiClient.refreshSession();
    if (auth == null) {
      throw ApiException.sessionExpired();
    }
    return auth;
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    final response = await _apiClient.post(
      '/api/Auth/change-password',
      body: request.toJson(),
    );
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not change password.',
    );
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    final response = await _apiClient.postPublic(
      '/api/Auth/forgot-password',
      body: request.toJson(),
    );
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not send password reset email.',
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    final response = await _apiClient.postPublic(
      '/api/Auth/reset-password',
      body: request.toJson(),
    );
    ApiResponse.decodeVoid(response.body).ensureSuccess(
      fallbackMessage: 'Could not reset password.',
    );
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final device = await DeviceInfoCollector.collect();
        final response = await _apiClient.post(
          '/api/Auth/logout',
          body: LogoutRequest(
            refreshToken: refreshToken,
            deviceName: device.deviceName,
          ).toJson(),
        );
        ApiResponse.decodeVoid(response.body).ensureSuccess(
          fallbackMessage: 'Logout failed.',
        );
      }
    } on ApiException {
      // Still clear local session even if remote logout fails.
    }
    await _tokenStorage.clearAll();
  }

  AuthResponse _parseAuthResponse(String body) {
    final envelope = ApiResponse.decodeAuth(body);
    return envelope.requireData(
      fallbackMessage: 'Authentication response did not include tokens.',
    );
  }

  Future<void> _persist(
    AuthResponse auth, {
    String? fallbackEmail,
    String? fallbackName,
  }) async {
    final tokens = AuthTokens.fromAuthResponse(auth);
    await _tokenStorage.saveTokens(
      AuthTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        email: tokens.email ?? fallbackEmail,
        fullName: tokens.fullName ?? fallbackName,
        role: tokens.role,
        userId: tokens.userId,
        accessTokenExpiresAt: tokens.accessTokenExpiresAt,
        refreshTokenExpiresAt: tokens.refreshTokenExpiresAt,
      ),
    );
  }
}
