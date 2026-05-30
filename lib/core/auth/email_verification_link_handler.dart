class EmailVerificationLink {
  const EmailVerificationLink({
    required this.userId,
    required this.token,
  });

  final String userId;
  final String token;
}

/// Parses verification links from email or deep links.
class EmailVerificationLinkHandler {
  EmailVerificationLinkHandler._();

  static EmailVerificationLink? parse(Uri uri) {
    final userId = _firstQuery(uri, const ['userId', 'userid', 'user_id']);
    final token = _firstQuery(uri, const ['token', 'code', 'verificationToken']);

    if (userId != null &&
        token != null &&
        userId.isNotEmpty &&
        token.isNotEmpty) {
      return EmailVerificationLink(userId: userId, token: token);
    }

    return null;
  }

  static bool looksLikeVerificationLink(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    return path.contains('verify-email') ||
        host == 'verify-email' ||
        uri.scheme == 'lendledger';
  }

  static String? _firstQuery(Uri uri, List<String> keys) {
    for (final key in keys) {
      final value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
