import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lend_ledger/models/auth_tokens.dart';

class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  static const _userRoleKey = 'user_role';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      if (tokens.email != null)
        _storage.write(key: _userEmailKey, value: tokens.email),
      if (tokens.fullName != null)
        _storage.write(key: _userNameKey, value: tokens.fullName),
      if (tokens.role != null) _storage.write(key: _userRoleKey, value: tokens.role),
    ]);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> getUserEmail() => _storage.read(key: _userEmailKey);

  Future<String?> getUserName() => _storage.read(key: _userNameKey);

  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<bool> hasRefreshToken() async {
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<bool> hasAccessToken() async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
