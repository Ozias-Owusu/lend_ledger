import 'package:flutter/material.dart';
import 'package:lend_ledger/core/security/app_lock_service.dart';
import 'package:lend_ledger/pages/app_lock_screen.dart';

/// Wraps the signed-in shell and shows a lock overlay after [AppLockService.lockAfter].
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => AppLockGateState();
}

class AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lockService = AppLockService();
  bool _locked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _lockService.recordBackgroundTime();
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
  }

  void _unlock() {
    setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked)
          AppLockScreen(onUnlocked: _unlock),
      ],
    );
  }
}
