import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pin_storage_service.dart';

/// Locks the app after the user has been away or idle for [lockAfter].
class AppLockService {
  AppLockService({
    PinStorageService? pinStorage,
    LocalAuthentication? localAuth,
  })  : _pinStorage = pinStorage ?? PinStorageService(),
        _localAuth = localAuth ?? LocalAuthentication();

  static const lockAfter = Duration(minutes: 30);
  static const _lastBackgroundKey = 'app_last_background_ms';
  static const _lastActivityKey = 'app_last_activity_ms';

  final PinStorageService _pinStorage;
  final LocalAuthentication _localAuth;

  Future<void> recordBackgroundTime() async {
    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await sp.setInt(_lastBackgroundKey, now);
  }

  Future<void> recordUserActivity() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearLockTimestamps() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_lastBackgroundKey);
    await sp.remove(_lastActivityKey);
    await recordUserActivity();
  }

  Future<void> clearBackgroundTime() async {
    await clearLockTimestamps();
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

  Future<bool> isSecurityEnabled() async {
    final pinOn = await isPinEnabled() && await hasPin();
    final sp = await SharedPreferences.getInstance();
    final bioOn =
        (sp.getBool('biometricsEnabled') ?? false) &&
        await deviceSupportsBiometrics();
    return pinOn || bioOn;
  }

  Future<bool> shouldLock() async {
    if (!await isSecurityEnabled()) return false;

    final sp = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastBg = sp.getInt(_lastBackgroundKey);
    final lastAct = sp.getInt(_lastActivityKey);

    if (lastBg == null && lastAct == null) return false;

    if (lastBg != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(lastBg),
      );
      if (elapsed >= lockAfter) return true;
    }

    if (lastAct != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(lastAct),
      );
      if (elapsed >= lockAfter) return true;
    }

    return false;
  }

  Future<bool> canUnlockWithPin() async {
    return await isPinEnabled() && await hasPin();
  }

  Future<bool> tryBiometricUnlock() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (!(sp.getBool('biometricsEnabled') ?? false)) return false;
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
