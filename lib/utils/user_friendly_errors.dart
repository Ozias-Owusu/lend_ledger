import 'package:lend_ledger/core/network/api_exception.dart';

/// Turns API and client errors into short titles and plain-language messages.
class UserFriendlyErrors {
  UserFriendlyErrors._();

  static ResolvedError resolve(Object error, {String? titleOverride}) {
    if (error is String) {
      final trimmed = error.trim();
      if (trimmed.isEmpty) {
        return ResolvedError(
          title: titleOverride ?? 'Something went wrong',
          message: 'Please try again.',
        );
      }
      return _fromRaw(trimmed, titleOverride: titleOverride);
    }

    if (error is ApiException) {
      final raw = error.message.trim();
      if (raw.isEmpty) {
        return ResolvedError(
          title: titleOverride ?? _defaultTitle(error.type, error.statusCode),
          message: _defaultMessage(error.type),
        );
      }
      final resolved = _fromRaw(
        raw,
        statusCode: error.statusCode,
        type: error.type,
        titleOverride: titleOverride,
      );
      if (resolved.title == 'Something went wrong' &&
          titleOverride == null) {
        return ResolvedError(
          title: _defaultTitle(error.type, error.statusCode),
          message: resolved.message,
        );
      }
      return resolved;
    }

    final text = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .trim();
    if (text.isEmpty) {
      return ResolvedError(
        title: titleOverride ?? 'Something went wrong',
        message: 'Please try again.',
      );
    }
    return _fromRaw(text, titleOverride: titleOverride);
  }

  static String message(Object error) => resolve(error).message;

  static String title(Object error, {String? titleOverride}) =>
      resolve(error, titleOverride: titleOverride).title;

  static ResolvedError _fromRaw(
    String raw, {
    int? statusCode,
    ApiExceptionType? type,
    String? titleOverride,
  }) {
    if (_isTechnicalMessage(raw)) {
      return ResolvedError(
        title: titleOverride ?? _defaultTitle(
          type ?? ApiExceptionType.server,
          statusCode,
        ),
        message: _friendlyTechnicalMessage(
          titleOverride: titleOverride,
          statusCode: statusCode,
        ),
      );
    }

    final cleaned = _sanitize(raw);
    final lower = cleaned.toLowerCase();

    for (final rule in _knownRules) {
      if (rule.matches(lower)) {
        return ResolvedError(
          title: titleOverride ?? rule.title,
          message: rule.message,
        );
      }
    }

    if (statusCode == 401) {
      return ResolvedError(
        title: titleOverride ?? 'Sign in required',
        message: cleaned.isNotEmpty
            ? cleaned
            : 'Your session has expired. Please sign in again.',
      );
    }

    if (statusCode == 404) {
      return ResolvedError(
        title: titleOverride ?? 'Not found',
        message: cleaned.isNotEmpty
            ? cleaned
            : 'The item you requested could not be found.',
      );
    }

    if (statusCode == 409) {
      return ResolvedError(
        title: titleOverride ?? 'Cannot complete action',
        message: cleaned,
      );
    }

    return ResolvedError(
      title: titleOverride ??
          _defaultTitle(type ?? ApiExceptionType.unknown, statusCode),
      message: cleaned.isNotEmpty ? cleaned : 'Please try again.',
    );
  }

  static bool _isTechnicalMessage(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'system.',
      'exception:',
      'invalidoperationexception',
      'could not be translated',
      'linq expression',
      'dbset<',
      'stacktrace',
      ' at lendledger',
      ' at microsoft.',
      'controllers.',
      'translation of method',
    ];
    if (markers.any(lower.contains)) return true;
    if (text.length > 200 && lower.contains('exception')) return true;
    return false;
  }

  static String _friendlyTechnicalMessage({
    String? titleOverride,
    int? statusCode,
  }) {
    final title = titleOverride?.toLowerCase() ?? '';
    if (title.contains('delete')) {
      return 'We could not delete this customer right now. Please try again in a moment.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return 'We could not complete that action. Please try again.';
  }

  static String _sanitize(String text) {
    var value = text.trim();

    if (_isTechnicalMessage(value)) {
      return _friendlyTechnicalMessage();
    }

    if (value.startsWith('"') && value.endsWith('"') && value.length > 2) {
      value = value.substring(1, value.length - 1);
    }

    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (value.toLowerCase().contains('<html') ||
        value.toLowerCase().contains('<!doctype')) {
      return 'We could not reach the server. Check your connection and try again.';
    }

    if (value.startsWith('{') && value.endsWith('}') && value.length > 120) {
      return 'Something went wrong. Please try again.';
    }

    if (value.length > 400) {
      return 'Something went wrong. Please try again.';
    }

    return value;
  }

  static String _defaultTitle(ApiExceptionType type, int? statusCode) {
    switch (type) {
      case ApiExceptionType.network:
        return 'No connection';
      case ApiExceptionType.timeout:
        return 'Request timed out';
      case ApiExceptionType.unauthorized:
        return 'Sign in required';
      case ApiExceptionType.validation:
        if (statusCode == 409) return 'Cannot complete action';
        return 'Check your input';
      case ApiExceptionType.server:
        return 'Something went wrong';
      case ApiExceptionType.unknown:
        return 'Something went wrong';
    }
  }

  static String _defaultMessage(ApiExceptionType type) {
    switch (type) {
      case ApiExceptionType.network:
        return 'Network connection lost. Please check your internet and try again.';
      case ApiExceptionType.timeout:
        return 'The request took too long. Please try again.';
      case ApiExceptionType.unauthorized:
        return 'Your session has expired. Please sign in again.';
      case ApiExceptionType.validation:
        return 'Please check your input and try again.';
      case ApiExceptionType.server:
        return 'Something went wrong on our side. Please try again in a moment.';
      case ApiExceptionType.unknown:
        return 'Please try again.';
    }
  }
}

class ResolvedError {
  const ResolvedError({required this.title, required this.message});

  final String title;
  final String message;
}

class _KnownRule {
  const _KnownRule({
    required this.title,
    required this.message,
    required this.patterns,
  });

  final String title;
  final String message;
  final List<String> patterns;

  bool matches(String lower) {
    for (final pattern in patterns) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }
}

const _knownRules = <_KnownRule>[
  _KnownRule(
    title: 'Cannot delete customer',
    message:
        'This customer still owes money on a loan. Fully repay every loan first, then try deleting again.',
    patterns: [
      'cannot delete customer',
      'cannot delete this customer',
      'still owe money on a loan',
      'active or unpaid loans',
    ],
  ),
  _KnownRule(
    title: 'Customer already exists',
    message:
        'A customer with the same name, phone number, Ghana Card, or licence ID already exists. Open that record or change the details.',
    patterns: [
      'customer with the same full name',
      'ghana card number / license',
    ],
  ),
  _KnownRule(
    title: 'Sign in failed',
    message: 'Email or password is incorrect. Check your details and try again.',
    patterns: [
      'invalid login',
      'invalid credentials',
      'incorrect password',
    ],
  ),
  _KnownRule(
    title: 'Email not verified',
    message:
        'Please verify your email before signing in. Check your inbox for the verification link.',
    patterns: [
      'email not verified',
      'verify your email',
    ],
  ),
  _KnownRule(
    title: 'Session expired',
    message: 'Your session has ended. Please sign in again.',
    patterns: [
      'session has expired',
      'session expired',
    ],
  ),
  _KnownRule(
    title: 'No connection',
    message:
        'We could not reach the server. Check your internet connection and try again.',
    patterns: [
      'network connection lost',
      'socketexception',
      'failed host lookup',
      'connection refused',
    ],
  ),
];
