import 'package:flutter/material.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:lend_ledger/widgets/security/pin_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final _lockService = AppLockService();
  String _entry = '';
  bool _errorShake = false;
  bool _showBiometric = false;
  bool _showPinPad = false;
  bool _unlocking = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final sp = await SharedPreferences.getInstance();
    final bioEnabled = sp.getBool('biometricsEnabled') ?? false;
    final deviceBio = await _lockService.deviceSupportsBiometrics();
    final pinOn = await _lockService.canUnlockWithPin();
    if (!mounted) return;
    setState(() {
      _showBiometric = bioEnabled && deviceBio;
      _showPinPad = pinOn;
    });
    if (_showBiometric) {
      Future.delayed(const Duration(milliseconds: 400), _tryBiometric);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final ok = await _lockService.tryBiometricUnlock();
    if (!mounted) return;
    setState(() => _unlocking = false);
    if (ok) {
      await _lockService.clearBackgroundTime();
      widget.onUnlocked();
    }
  }

  void _onDigit(String digit) {
    if (_unlocking || _entry.length >= 6) return;
    setState(() => _entry += digit);
    if (_entry.length == 6) _verifyPin();
  }

  void _onBackspace() {
    if (_entry.isEmpty || _unlocking) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _unlocking = true);
    final ok = await _lockService.verifyPin(_entry);
    if (!mounted) return;
    if (ok) {
      await _lockService.clearBackgroundTime();
      widget.onUnlocked();
      return;
    }
    setState(() {
      _unlocking = false;
      _errorShake = true;
      _entry = '';
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _errorShake = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: AuthAnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.04).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.softRose.withValues(alpha: 0.4),
                        AppTheme.mintGray.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.softRose.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 52,
                    color: Color(0xFF5C4542),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lend Ledger',
                style: AppTheme.display(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back — enter your PIN to continue',
                style: AppTheme.body(fontSize: 14),
              ),
              const Spacer(),
              if (_unlocking && _entry.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: CircularProgressIndicator(color: AppTheme.softRose),
                )
              else if (_showPinPad)
                PinPad(
                  filledCount: _entry.length,
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onBiometric: _showBiometric ? _tryBiometric : null,
                  showBiometric: _showBiometric,
                  errorShake: _errorShake,
                )
              else if (_showBiometric)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: FilledButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Unlock with biometrics'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.softRose,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
