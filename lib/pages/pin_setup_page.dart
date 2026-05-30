import 'package:flutter/material.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:lend_ledger/widgets/security/pin_pad.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key, this.isChangingPin = false});

  final bool isChangingPin;

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage>
    with SingleTickerProviderStateMixin {
  final _lockService = AppLockService();
  String _entry = '';
  String? _firstPin;
  bool _confirming = false;
  bool _errorShake = false;
  bool _saving = false;

  late final AnimationController _introController;
  late final Animation<double> _introFade;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _introFade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  String get _title =>
      _confirming ? 'Confirm your PIN' : 'Create your 6-digit PIN';

  String get _subtitle => _confirming
      ? 'Enter the same PIN again to finish setup.'
      : 'You will use this to unlock the app after being away.';

  void _onDigit(String digit) {
    if (_saving || _entry.length >= 6) return;
    setState(() => _entry += digit);
    if (_entry.length == 6) {
      Future.delayed(const Duration(milliseconds: 180), _onPinComplete);
    }
  }

  void _onBackspace() {
    if (_entry.isEmpty || _saving) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _entry;
        _entry = '';
        _confirming = true;
      });
      return;
    }

    if (_entry != _firstPin) {
      setState(() {
        _errorShake = true;
        _entry = '';
        _confirming = false;
        _firstPin = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _errorShake = false);
      });
      SnackbarUtils.showError(context, 'PINs did not match. Try again.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _lockService.savePin(_entry);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _entry = '';
        _confirming = false;
        _firstPin = null;
      });
      SnackbarUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthAnimatedBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _introFade,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.softRose.withValues(alpha: 0.35),
                        AppTheme.peach.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 44,
                    color: Color(0xFF6B4F4A),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isChangingPin ? 'Change app PIN' : 'Secure your app',
                  style: AppTheme.display(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      _subtitle,
                      key: ValueKey(_confirming),
                      textAlign: TextAlign.center,
                      style: AppTheme.body(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _title,
                  style: AppTheme.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.softRose,
                  ),
                ),
                const Spacer(),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: CircularProgressIndicator(color: AppTheme.softRose),
                  )
                else
                  PinPad(
                    filledCount: _entry.length,
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    errorShake: _errorShake,
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
