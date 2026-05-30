import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pin_storage_service.dart';

/// Locks the app after the user has been away for [lockAfter].
class AppLockService {
  AppLockService({
    PinStorageService? pinStorage,
    LocalAuthentication? localAuth,
  })  : _pinStorage = pinStorage ?? PinStorageService(),
        _localAuth = localAuth ?? LocalAuthentication();

  static const lockAfter = Duration(hours: 1);
  static const _lastBackgroundKey = 'app_last_background_ms';

  final PinStorageService _pinStorage;
  final LocalAuthentication _localAuth;

  Future<void> recordBackgroundTime() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(
      _lastBackgroundKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearBackgroundTime() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_lastBackgroundKey);
  }

  Future<bool> deviceSupportsBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _localAuth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPinEnabled() => _pinStorage.isPinEnabled();

  Future<bool> hasPin() => _pinStorage.hasPin();

  Future<bool> verifyPin(String pin) => _pinStorage.verifyPin(pin);

  Future<void> savePin(String pin) => _pinStorage.savePin(pin);

  Future<void> clearPin() => _pinStorage.clearPin();

  Future<bool> shouldLock() async {
    final sp = await SharedPreferences.getInstance();
    final lastMs = sp.getInt(_lastBackgroundKey);
    if (lastMs == null) return false;

    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (DateTime.now().difference(last) < lockAfter) return false;

    final pinOn = await isPinEnabled() && await hasPin();
    final bioOn =
        (sp.getBool('biometricsEnabled') ?? false) &&
        await deviceSupportsBiometrics();
    return pinOn || bioOn;
  }

  Future<bool> canUnlockWithPin() async {
    return await isPinEnabled() && await hasPin();
  }

  Future<bool> tryBiometricUnlock() async {
    try {
      final supported = await deviceSupportsBiometrics();
      if (!supported) return false;
      return _localAuth.authenticate(
        localizedReason: 'Unlock Lend Ledger',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
