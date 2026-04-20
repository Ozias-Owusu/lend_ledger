class ApiConfig {
  ApiConfig._();

  // Single source of truth for backend API host.
  static const String baseUrl = 'https://tinfoil-steerable-scribe.ngrok-free.dev';

  static String endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }
}
