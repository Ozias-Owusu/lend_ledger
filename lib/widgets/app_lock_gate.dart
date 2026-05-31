import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/pages/app_lock_screen.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';

/// Wraps the signed-in shell and shows a lock overlay after [AppLockService.lockAfter].
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => AppLockGateState();
}

class AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lockService = AppLockService();
  Timer? _idleTimer;
  bool _locked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _evaluateLock();
    if (!_locked) {
      await _onUserActivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _lockService.recordBackgroundTime();
      _idleTimer?.cancel();
    }
    if (state == AppLifecycleState.resumed) {
      _evaluateLock();
    }
  }

  Future<void> _evaluateLock() async {
    final should = await _lockService.shouldLock();
    if (!mounted) return;
    setState(() {
      _locked = should;
      _checking = false;
    });
    if (!_locked) {
      _scheduleIdleLock();
    } else {
      _idleTimer?.cancel();
    }
  }

  void _scheduleIdleLock() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AppLockService.lockAfter, () async {
      if (!mounted || _locked) return;
      final enabled = await _lockService.isSecurityEnabled();
      if (!enabled) return;
      setState(() => _locked = true);
    });
  }

  Future<void> _onUserActivity() async {
    if (_locked) return;
    await _lockService.recordUserActivity();
    _scheduleIdleLock();
  }

  Future<void> _unlock() async {
    await _lockService.clearLockTimestamps();
    if (!mounted) return;
    setState(() => _locked = false);
    await _onUserActivity();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: AuthAnimatedBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.softRose),
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_locked)
            AppLockScreen(onUnlocked: _unlock),
        ],
      ),
    );
  }
}
