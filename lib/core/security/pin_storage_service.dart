import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinStorageService {
  PinStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _pinHashKey = 'app_pin_hash';
  static const _pinEnabledKey = 'app_pin_enabled';

  final FlutterSecureStorage _storage;

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<bool> isPinEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_pinEnabledKey) ?? false;
  }

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    if (pin.length != 6) {
      throw ArgumentError('PIN must be 6 digits.');
    }
    await _storage.write(key: _pinHashKey, value: hashPin(pin));
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_pinEnabledKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null || stored.isEmpty) return false;
    return stored == hashPin(pin);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_pinEnabledKey, false);
  }
}
