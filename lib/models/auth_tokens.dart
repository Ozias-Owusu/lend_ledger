import 'package:lend_ledger/models/auth/auth_response.dart';

/// Persisted session credentials derived from [AuthResponse].
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.email,
    this.fullName,
    this.role,
    this.userId,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String? email;
  final String? fullName;
  final String? role;
  final String? userId;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  factory AuthTokens.fromAuthResponse(AuthResponse response) {
    return AuthTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      email: response.email,
      fullName: response.fullName,
      role: response.primaryRole,
      userId: response.userId,
      accessTokenExpiresAt: response.accessTokenExpiresAt,
      refreshTokenExpiresAt: response.refreshTokenExpiresAt,
    );
  }
}
