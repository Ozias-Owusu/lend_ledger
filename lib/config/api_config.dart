class ApiConfig {
  ApiConfig._();

  // Single source of truth for backend API host.
  // Android emulator → http://10.0.2.2:PORT
  static const String baseUrl =
      'https://tinfoil-steerable-scribe.ngrok-free.dev';

  static Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (baseUrl.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    return headers;
  }

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }
}
