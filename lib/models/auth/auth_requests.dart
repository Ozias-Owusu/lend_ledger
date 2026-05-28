class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceName,
    this.deviceType,
    this.platform,
  });

  final String email;
  final String password;
  final String? deviceName;
  final String? deviceType;
  final String? platform;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (deviceName != null) 'deviceName': deviceName,
        if (deviceType != null) 'deviceType': deviceType,
        if (platform != null) 'platform': platform,
      };
}

class RefreshTokenRequest {
  const RefreshTokenRequest({
    required this.refreshToken,
    this.deviceName,
  });

  final String refreshToken;
  final String? deviceName;

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
        if (deviceName != null) 'deviceName': deviceName,
      };
}

class LogoutRequest {
  const LogoutRequest({
    required this.refreshToken,
    required this.deviceName,
  });

  final String refreshToken;
  final String deviceName;

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
        'deviceName': deviceName,
      };
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String email;
  final String token;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
        'email': email,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}
