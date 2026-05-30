import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/services/auth_api_service.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:lend_ledger/widgets/auth/auth_glass_card.dart';
import 'package:lend_ledger/widgets/auth/password_form_field.dart';
import 'package:provider/provider.dart';

import 'app_shell_page.dart';
import 'forgot_password_page.dart';
import 'verify_email_pending_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  bool _loading = false;
  bool _isLogin = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _canUseBiometrics = false;
  String _selectedRole = AuthApiService.availableRoles.first;

  late final AnimationController _entranceController;
  late final AnimationController _modeController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _modeFade;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _modeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _modeFade = CurvedAnimation(
      parent: _modeController,
      curve: Curves.easeInOut,
    );

    _entranceController.forward();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _modeController.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmPassCtl.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final canUse = await appState.areBiometricsEnabled();
    if (mounted) setState(() => _canUseBiometrics = canUse);
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _loading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.biometricLogin();

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const AppShellPage()),
      );
    } else {
      SnackbarUtils.showError(
        context,
        'Biometric login failed or was canceled.',
      );
    }
  }

  Future<void> _toggleFormType() async {
    await _modeController.reverse();
    if (!mounted) return;
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailCtl.clear();
      _passCtl.clear();
      _confirmPassCtl.clear();
      _nameCtl.clear();
      _selectedRole = AuthApiService.availableRoles.first;
    });
    await _modeController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (_isLogin) {
        final success = await appState.login(
          _emailCtl.text.trim(),
          _passCtl.text,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const AppShellPage()),
          );
        } else {
          SnackbarUtils.showError(context, 'Invalid login credentials.');
        }
      } else {
        final email = _emailCtl.text.trim();
        final message = await appState.signUp(
          name: _nameCtl.text.trim(),
          email: email,
          password: _passCtl.text,
          confirmPassword: _confirmPassCtl.text,
          role: _selectedRole,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => VerifyEmailPendingPage(
              email: email,
              registrationMessage: message,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleFont = AppTheme.display(fontSize: 28, height: 1.1);
    final subtitleFont = AppTheme.body();

    return Scaffold(
      body: AuthAnimatedBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        _buildHeader(titleFont, subtitleFont),
                        const SizedBox(height: 22),
                        AuthGlassCard(
                          child: Form(
                            key: _formKey,
                            child: FadeTransition(
                              opacity: _modeFade,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _AuthModeToggle(
                                    isLogin: _isLogin,
                                    onChanged: _loading ? null : _toggleFormType,
                                  ),
                                  const SizedBox(height: 22),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.03),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      _isLogin
                                          ? 'Sign in to your account'
                                          : 'Create your account',
                                      key: ValueKey(_isLogin),
                                      style: subtitleFont.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: const Color(0xFF4A3F3D),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (!_isLogin) ...[
                                    _AuthField(
                                      controller: _nameCtl,
                                      label: 'Full name',
                                      icon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Name is required'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _AuthField(
                                    controller: _emailCtl,
                                    label: 'Email address',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Email is required';
                                      }
                                      final emailRegex =
                                          RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                      if (!emailRegex.hasMatch(v)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  if (_isLogin)
                                    _AuthField(
                                      controller: _passCtl,
                                      label: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: !_showPassword,
                                      textInputAction: TextInputAction.done,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                          color: const Color(0xFF8A7A76),
                                        ),
                                        onPressed: () => setState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password is required';
                                        }
                                        return null;
                                      },
                                    )
                                  else
                                    PasswordFormField(
                                      controller: _passCtl,
                                      label: 'Password',
                                      textInputAction: TextInputAction.next,
                                    ),
                                  if (!_isLogin) ...[
                                    const SizedBox(height: 14),
                                    _AuthField(
                                      controller: _confirmPassCtl,
                                      label: 'Confirm password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: !_showConfirmPassword,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _showConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                          color: const Color(0xFF8A7A76),
                                        ),
                                        onPressed: () => setState(
                                          () => _showConfirmPassword =
                                              !_showConfirmPassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (v != _passCtl.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _AuthRoleDropdown(
                                      value: _selectedRole,
                                      onChanged: _loading
                                          ? null
                                          : (v) {
                                              if (v != null) {
                                                setState(() => _selectedRole = v);
                                              }
                                            },
                                    ),
                                  ],
                                  if (_isLogin) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ForgotPasswordPage(
                                                      initialEmail:
                                                          _emailCtl.text.trim(),
                                                    ),
                                                  ),
                                                );
                                              },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.softRose,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: AppTheme.body(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    const SizedBox(height: 8),
                                  const SizedBox(height: 8),
                                  _AuthPrimaryButton(
                                    label: _isLogin ? 'Sign in' : 'Create account',
                                    loading: _loading,
                                    onPressed: _submit,
                                  ),
                                  if (_isLogin && _canUseBiometrics) ...[
                                    const SizedBox(height: 14),
                                    _AuthOutlineButton(
                                      icon: Icons.fingerprint_rounded,
                                      label: 'Sign in with biometrics',
                                      onPressed:
                                          _loading ? null : _handleBiometricLogin,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? 'New here? '
                                            : 'Already registered? ',
                                        style: subtitleFont,
                                      ),
                                      GestureDetector(
                                        onTap: _loading ? null : _toggleFormType,
                                        child: Text(
                                          _isLogin ? 'Create account' : 'Sign in',
                                          style: AppTheme.body(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.softRose,
                                            decoration: TextDecoration.underline,
                                            decorationColor: AppTheme.softRose
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Secure lending, beautifully simple.',
                          style: subtitleFont.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextStyle titleFont, TextStyle subtitleFont) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.88, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.softRose.withValues(alpha: 0.5),
                  AppTheme.peach.withValues(alpha: 0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softRose.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/images/auth.jpg'),
              backgroundColor: Color(0xFFFFF6F2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Lend Ledger', style: titleFont),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            _isLogin
                ? 'Welcome back — manage loans with confidence.'
                : 'Join us — start tracking loans in minutes.',
            key: ValueKey(_isLogin),
            textAlign: TextAlign.center,
            style: subtitleFont,
          ),
        ),
      ],
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.isLogin,
    required this.onChanged,
  });

  final bool isLogin;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.peach.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.mintGray.withValues(alpha: 0.45),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: isLogin ? 4 : 4 + half,
                top: 4,
                bottom: 4,
                width: half,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.softRose.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ToggleLabel(
                      label: 'Sign in',
                      selected: isLogin,
                      onTap: isLogin ? null : onChanged,
                    ),
                  ),
                  Expanded(
                    child: _ToggleLabel(
                      label: 'Sign up',
                      selected: !isLogin,
                      onTap: !isLogin ? null : onChanged,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: AppTheme.body(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? const Color(0xFF4A3F3D)
                  : const Color(0xFF8A7A76),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: AppTheme.body(
        fontSize: 15,
        color: const Color(0xFF3D3533),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.body(
          color: const Color(0xFF8A7A76),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 22, color: AppTheme.softRose),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.65),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.mintGray.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.mintGray.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.softRose, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _AuthRoleDropdown extends StatelessWidget {
  const _AuthRoleDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      style: AppTheme.body(
        fontSize: 15,
        color: const Color(0xFF3D3533),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Your role',
        labelStyle: AppTheme.body(
          color: const Color(0xFF8A7A76),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.badge_outlined,
          size: 22,
          color: AppTheme.softRose,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.mintGray.withValues(alpha: 0.55),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.mintGray.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.softRose, width: 1.6),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      items: AuthApiService.availableRoles
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      validator: (v) =>
          v == null || v.isEmpty ? 'Please select a role' : null,
    );
  }
}

class _AuthPrimaryButton extends StatefulWidget {
  const _AuthPrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<_AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.loading ? null : (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.loading
                  ? [
                      AppTheme.softRose.withValues(alpha: 0.6),
                      AppTheme.peach.withValues(alpha: 0.5),
                    ]
                  : [
                      AppTheme.softRose,
                      const Color(0xFFC4928C),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: widget.loading
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.softRose.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.loading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: AppTheme.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthOutlineButton extends StatelessWidget {
  const _AuthOutlineButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppTheme.softRose),
        label: Text(
          label,
          style: AppTheme.body(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A3F3D),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.softRose.withValues(alpha: 0.55),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
