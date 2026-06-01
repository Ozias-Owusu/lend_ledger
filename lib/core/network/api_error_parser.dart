import 'dart:convert';

import 'package:lend_ledger/models/api_response.dart';

class ApiErrorParser {
  static String messageFromBody(String body) {
    if (body.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        if (map.containsKey('success')) {
          final envelope = ApiResponse<void>.fromJson(map, (_) => null);
          if (envelope.message.isNotEmpty) {
            return _appendErrors(envelope.message, envelope.errors);
          }
        }

        final title = map['title']?.toString();
        final detail = map['detail']?.toString();
        if (title != null &&
            title.isNotEmpty &&
            detail != null &&
            detail.isNotEmpty) {
          return '$title: $detail';
        }
        if (detail != null && detail.isNotEmpty) return detail;
        if (title != null && title.isNotEmpty) return title;
        final message = map['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return _appendErrors(message, map['errors']);
        }

        final errors = map['errors'];
        final fromErrors = _errorsToMessage(errors);
        if (fromErrors.isNotEmpty) return fromErrors;
      }
    } catch (_) {
      // Fall through to raw body.
    }

    return _cleanPlainBody(body);
  }

  static String _cleanPlainBody(String body) {
    var text = body.trim();
    if (text.isEmpty) return '';

    try {
      final decoded = jsonDecode(text);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {
      // Plain text response (e.g. ASP.NET Conflict message).
    }

    if (text.length >= 2 &&
        text.startsWith('"') &&
        text.endsWith('"')) {
      text = text.substring(1, text.length - 1).trim();
    }

    return text;
  }

  static String _appendErrors(String message, dynamic errors) {
    final fromErrors = _errorsToMessage(errors);
    if (fromErrors.isEmpty) return message;
    return '$message\n$fromErrors';
  }

  static String _errorsToMessage(dynamic errors) {
    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          parts.add('${entry.key}: ${value.first}');
        } else if (value != null) {
          parts.add('${entry.key}: $value');
        }
      }
      if (parts.isNotEmpty) return parts.join('\n');
    }
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    if (errors != null && errors.toString().trim().isNotEmpty) {
      return errors.toString();
    }
    return '';
  }
}
