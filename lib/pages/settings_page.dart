import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lend_ledger/app/app_keys.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/pages/EditProfilePage.dart';
import 'package:lend_ledger/pages/admin_users_page.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/pages/notifications_page.dart';
import 'package:lend_ledger/pages/pin_setup_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';
import 'package:lend_ledger/widgets/user_profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AppLockService _lockService = AppLockService();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  bool _securityExpanded = false;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  bool _pinEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
    _loadSecurityState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.loadCurrentUserProfile(force: true);
      appState.refreshLocalProfileImage();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityState() async {
    try {
      final bioList = await _localAuth.getAvailableBiometrics();
      final canCheck = await _localAuth.canCheckBiometrics;
      final sp = await SharedPreferences.getInstance();
      final pinOn = await _lockService.isPinEnabled();
      if (!mounted) return;
      setState(() {
        _availableBiometrics = bioList;
        _biometricsAvailable = canCheck && bioList.isNotEmpty;
        _biometricsEnabled = sp.getBool('biometricsEnabled') ?? false;
        _pinEnabled = pinOn;
      });
    } catch (_) {}
  }

  Future<void> _enableBiometric(BiometricType type) async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to enable biometrics',
        biometricOnly: false,
      );
      if (ok) {
        final sp = await SharedPreferences.getInstance();
        await sp.setBool('biometricsEnabled', true);
      }
      if (!mounted) return;
      await _loadSecurityState();
      SnackbarUtils.show(
        context,
        ok ? 'Biometrics enabled.' : 'Biometric setup canceled.',
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      );
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e);
    }
  }

  Future<void> _openPinSetup() async {
    final created = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PinSetupPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (created == true && mounted) {
      await _loadSecurityState();
      SnackbarUtils.showSuccess(context, 'App PIN is ready.');
    }
  }

  Future<void> _openEditProfile(AppState appState) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    if (!mounted) return;
    await appState.refreshLocalProfileImage();
  }

  Future<void> _handleLogout(AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out?',
          style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'You will be signed out on this device. Your PIN and profile photo stay saved for next sign-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await appState.logout();
    } catch (_) {}

    if (!mounted) return;
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: AuthAnimatedBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      'Settings',
                      style: AppTheme.display(fontSize: 32),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ProfileHeroCard(appState: appState),
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
                if (appState.isAdmin)
                  SliverToBoxAdapter(
                    child: _AnimatedSection(
                      delay: 80,
                      child: _SettingsSection(
                        title: 'Admin',
                        children: [
                          _SettingsTile(
                            icon: Icons.group_outlined,
                            title: 'Manage users',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminUsersPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    delay: 120,
                    child: _SettingsSection(
                      title: 'Account',
                      children: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit profile',
                          subtitle: 'Photo & password',
                          onTap: () => _openEditProfile(appState),
                        ),
                        _SecurityExpandable(
                          expanded: _securityExpanded,
                          onToggle: () => setState(
                            () => _securityExpanded = !_securityExpanded,
                          ),
                          biometricsAvailable: _biometricsAvailable,
                          biometricsEnabled: _biometricsEnabled,
                          pinEnabled: _pinEnabled,
                          availableBiometrics: _availableBiometrics,
                          onBiometricTap: _enableBiometric,
                          onPinSetup: _openPinSetup,
                        ),
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: appState.notificationPermissionGranted
                              ? 'Alerts enabled'
                              : 'Tap to enable',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    delay: 180,
                    child: _SettingsSection(
                      title: 'Support',
                      children: [
                        _SettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & support',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.article_outlined,
                          title: 'Terms & policies',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    delay: 220,
                    child: _SettingsSection(
                      title: 'Actions',
                      children: [
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          title: 'Log out',
                          destructive: true,
                          onTap: () => _handleLogout(appState),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    if (appState.isLoadingUserProfile && appState.currentUserProfile == null) {
      return _glassCard(
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: AppTheme.softRose)),
        ),
      );
    }

    final profile = appState.currentUserProfile;
    if (profile == null) {
      return _glassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                appState.userProfileError ?? 'Could not load profile.',
                style: TextStyle(color: Colors.red.shade700),
              ),
              TextButton(
                onPressed: () =>
                    appState.loadCurrentUserProfile(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            UserProfileAvatar(
              key: ValueKey(
                'settings_avatar_${appState.localProfileImagePath ?? profile.id}',
              ),
              profile: profile,
              radius: 40,
              localImagePath: appState.localProfileImagePath,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: AppTheme.body(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: AppTheme.body(fontSize: 13),
                  ),
                  if (profile.primaryRole != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softRose.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.primaryRole!,
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B4F4A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityExpandable extends StatelessWidget {
  const _SecurityExpandable({
    required this.expanded,
    required this.onToggle,
    required this.biometricsAvailable,
    required this.biometricsEnabled,
    required this.pinEnabled,
    required this.availableBiometrics,
    required this.onBiometricTap,
    required this.onPinSetup,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final bool biometricsAvailable;
  final bool biometricsEnabled;
  final bool pinEnabled;
  final List<BiometricType> availableBiometrics;
  final void Function(BiometricType) onBiometricTap;
  final VoidCallback onPinSetup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Security',
          subtitle: pinEnabled
              ? 'PIN active'
              : biometricsEnabled
                  ? 'Biometrics on'
                  : 'Set up protection',
          trailing: AnimatedRotation(
            turns: expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 280),
            child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A7A76)),
          ),
          onTap: onToggle,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                if (biometricsAvailable) ...[
                  ...availableBiometrics.map(
                    (b) => _SecurityOption(
                      icon: _biometricIcon(b),
                      label: _biometricLabel(b),
                      enabled: biometricsEnabled,
                      onTap: () => onBiometricTap(b),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _SecurityOption(
                  icon: Icons.dialpad_rounded,
                  label: pinEnabled ? 'Change app PIN' : 'Set up app PIN',
                  enabled: pinEnabled,
                  onTap: onPinSetup,
                  highlight: !pinEnabled && !biometricsAvailable,
                ),
                if (!biometricsAvailable && !pinEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                    child: Text(
                      'No biometrics detected. Create a 6-digit PIN to lock the app after 1 hour away.',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: const Color(0xFF7A6E6A),
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  IconData _biometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return Icons.fingerprint_rounded;
      case BiometricType.face:
        return Icons.face_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  String _biometricLabel(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Use fingerprint';
      case BiometricType.face:
        return 'Use face unlock';
      default:
        return 'Use biometrics';
    }
  }
}

class _SecurityOption extends StatelessWidget {
  const _SecurityOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = false,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight
          ? AppTheme.peach.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.softRose, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.body(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF4A3F3D),
                  ),
                ),
              ),
              if (enabled)
                Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppTheme.body(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: const Color(0xFF8A7A76),
              ),
            ),
          ),
          _glassCard(
            child: Column(children: children),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : const Color(0xFF4A3F3D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: destructive
                      ? Colors.red.shade50
                      : AppTheme.softRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: destructive ? Colors.red.shade700 : AppTheme.softRose,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTheme.body(
                          fontSize: 12,
                          color: const Color(0xFF8A7A76),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatefulWidget {
  const _AnimatedSection({
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

Widget _glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              const Color(0xFFFFF8F5).withValues(alpha: 0.8),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.softRose.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}
