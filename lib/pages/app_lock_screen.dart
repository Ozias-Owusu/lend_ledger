import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:lend_ledger/widgets/auth/auth_glass_card.dart';
import 'package:lend_ledger/widgets/security/pin_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with TickerProviderStateMixin {
  final _lockService = AppLockService();
  String _entry = '';
  bool _errorShake = false;
  bool _showBiometric = false;
  bool _showPinPad = false;
  bool _unlocking = false;

  late final AnimationController _entranceController;
  late final AnimationController _shieldController;
  late final AnimationController _ringController;
  late final AnimationController _shimmerController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  late final Animation<double> _shieldFloat;
  late final Animation<double> _ringRotation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
    ));
    _shieldFloat = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );
    _ringRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _ringController,
    );

    _entranceController.forward();
    _initUnlockOptions();
  }

  Future<void> _initUnlockOptions() async {
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
      Future.delayed(const Duration(milliseconds: 650), _tryBiometric);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shieldController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _tryBiometric() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final ok = await _lockService.tryBiometricUnlock();
    if (!mounted) return;
    setState(() => _unlocking = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    }
  }

  void _onDigit(String digit) {
    if (_unlocking || _entry.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() => _entry += digit);
    if (_entry.length == 6) _verifyPin();
  }

  void _onBackspace() {
    if (_entry.isEmpty || _unlocking) return;
    HapticFeedback.selectionClick();
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _unlocking = true);
    final ok = await _lockService.verifyPin(_entry);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _unlocking = false;
      _errorShake = true;
      _entry = '';
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _errorShake = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AuthAnimatedBackground(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          _buildHero(),
                          const SizedBox(height: 28),
                          AuthGlassCard(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                            child: Column(
                              children: [
                                Text(
                                  'Session locked',
                                  style: AppTheme.body(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppTheme.softRose,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _showPinPad
                                      ? 'Enter your 6-digit PIN'
                                      : 'Confirm it\'s you',
                                  style: AppTheme.body(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your ledger is protected after 30 minutes away',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                if (_unlocking && _entry.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.softRose,
                                      ),
                                    ),
                                  )
                                else if (_showPinPad)
                                  PinPad(
                                    filledCount: _entry.length,
                                    onDigit: _onDigit,
                                    onBackspace: _onBackspace,
                                    onBiometric:
                                        _showBiometric ? _tryBiometric : null,
                                    showBiometric: _showBiometric,
                                    errorShake: _errorShake,
                                  )
                                else if (_showBiometric)
                                  _BiometricUnlockButton(
                                    onPressed: _unlocking ? null : _tryBiometric,
                                  )
                                else
                                  Text(
                                    'Enable a PIN or biometrics in Settings',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body(fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shieldFloat, _ringRotation, _shimmerController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _shieldFloat.value),
          child: child,
        );
      },
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _ringRotation,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(140, 140),
                      painter: _LockRingPainter(
                        rotation: _ringRotation.value,
                        shimmer: _shimmerController.value,
                      ),
                    );
                  },
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        AppTheme.peach.withValues(alpha: 0.55),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.softRose.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 44,
                    color: Color(0xFF5C4542),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _greeting,
            style: AppTheme.display(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Text(
            'Lend Ledger',
            style: AppTheme.body(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricUnlockButton extends StatefulWidget {
  const _BiometricUnlockButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_BiometricUnlockButton> createState() => _BiometricUnlockButtonState();
}

class _BiometricUnlockButtonState extends State<_BiometricUnlockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1 + _pulse.value * 0.04;
        return Transform.scale(scale: scale, child: child);
      },
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.softRose.withValues(alpha: 0.25),
                      AppTheme.mintGray.withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.softRose.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 48,
                  color: AppTheme.softRose,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to unlock with biometrics',
            style: AppTheme.body(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LockRingPainter extends CustomPainter {
  _LockRingPainter({required this.rotation, required this.shimmer});

  final double rotation;
  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          AppTheme.softRose.withValues(alpha: 0.15),
          AppTheme.softRose.withValues(alpha: 0.85),
          AppTheme.peach.withValues(alpha: 0.6),
          AppTheme.mintGray.withValues(alpha: 0.4),
          AppTheme.softRose.withValues(alpha: 0.15),
        ],
        stops: [
          0,
          0.25 + shimmer * 0.1,
          0.5,
          0.75,
          1,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      math.pi * 1.65,
      false,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LockRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.shimmer != shimmer;
  }
}
