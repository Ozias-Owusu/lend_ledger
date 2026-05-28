class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String userId;
  final String email;
  final String fullName;
  final List<String> roles;

  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: _requireString(json, 'accessToken'),
      accessTokenExpiresAt: _parseDateTime(json['accessTokenExpiresAt']),
      refreshToken: _requireString(json, 'refreshToken'),
      refreshTokenExpiresAt: _parseDateTime(json['refreshTokenExpiresAt']),
      userId: _requireString(json, 'userId'),
      email: _requireString(json, 'email'),
      fullName: _requireString(json, 'fullName'),
      roles: _parseRoles(json['roles']),
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required field: $key');
    }
    return value;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      throw const FormatException('Missing date/time value.');
    }
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) {
      throw const FormatException('Missing date/time value.');
    }
    return DateTime.parse(text);
  }

  static List<String> _parseRoles(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
