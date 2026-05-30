import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:lend_ledger/app/app_keys.dart';
import 'package:lend_ledger/core/auth/email_verification_deep_link_service.dart';
import 'package:lend_ledger/core/notifications/firebase_messaging_service.dart';
import 'package:lend_ledger/core/service_locator.dart';
import 'package:lend_ledger/pages/app_shell_page.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/widgets/app_lock_gate.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

final EmailVerificationDeepLinkService emailVerificationDeepLinks =
    EmailVerificationDeepLinkService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();

  ServiceLocator.init(
    onSessionExpired: appState.navigateToSignInLanding,
  );

  await FirebaseMessagingService.instance.initialize();

  await _requestPermissions();
  await appState.initialize();
  await emailVerificationDeepLinks.initialize();

  runApp(MyApp(appState: appState, isLoggedIn: appState.isLoggedIn));
}

Future<void> _requestPermissions() async {
  final permissionsToRequest = <Permission>[
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.notification,
  ];

  if (Platform.isAndroid) {
    permissionsToRequest.add(Permission.photos);
    permissionsToRequest.add(Permission.videos);
  }

  final results = await permissionsToRequest.request();

  final permanentlyDenied = results.entries
      .where((e) => e.value.isPermanentlyDenied)
      .map((e) => e.key)
      .toList();

  if (permanentlyDenied.isNotEmpty) {
    openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  final AppState appState;
  final bool isLoggedIn;
  const MyApp({super.key, required this.appState, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'Loan Management',
        theme: AppTheme.light(),
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: BouncingScrollWrapper.builder(context, child!),
          breakpoints: const [
            Breakpoint(start: 0, end: 349, name: MOBILE),
            Breakpoint(start: 350, end: 599, name: TABLET),
            Breakpoint(start: 600, end: 1199, name: DESKTOP),
            Breakpoint(start: 1200, end: double.infinity, name: '4K'),
          ],
        ),
        home: isLoggedIn
            ? const AppLockGate(child: AppShellPage())
            : const LandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
