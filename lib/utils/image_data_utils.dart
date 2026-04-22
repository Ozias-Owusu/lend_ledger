import 'dart:convert';
import 'dart:typed_data';

class ImageDataUtils {
  ImageDataUtils._();

  static Uint8List? decodeToBytes(String? rawValue) {
    if (rawValue == null) return null;
    var value = rawValue.trim();
    if (value.isEmpty) return null;

    // Handle data URI payloads like: data:image/jpeg;base64,....
    final commaIndex = value.indexOf(',');
    if (value.startsWith('data:image') && commaIndex != -1) {
      value = value.substring(commaIndex + 1);
    }

    value = value.replaceAll(RegExp(r'\s+'), '');

    try {
      return base64Decode(value);
    } catch (_) {
      try {
        return base64Decode(base64.normalize(value));
      } catch (_) {
        return null;
      }
    }
  }
}
