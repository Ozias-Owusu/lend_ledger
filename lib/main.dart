import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:lend_ledger/pages/app_shell_page.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();

  // Request permissions at startup
  await _requestPermissions();

  await appState.loadFromDb();

  // Check login status using SharedPreferences
  final sp = await SharedPreferences.getInstance();
  bool isLoggedIn = sp.getBool('isLoggedIn') ?? false;

  runApp(MyApp(appState: appState, isLoggedIn: isLoggedIn));
}

// Function to request necessary permissions
Future<void> _requestPermissions() async {
  // Request multiple permissions at once.
  // Note: file uploads via `file_picker` typically don't need broad storage
  // permissions on Android (SAF), but we still request the commonly-used
  // permissions your app currently uses for media selection/capture.
  final permissionsToRequest = <Permission>[
    Permission.camera,
    Permission.storage,
    Permission.photos, // iOS / media library
    Permission.videos, // Android 13+ media access
  ];

  // Android 11+ "all files" access is rarely needed; we only request if present.
  if (Platform.isAndroid) {
    permissionsToRequest.add(Permission.photos);
    permissionsToRequest.add(Permission.videos);
  }

  final results = await permissionsToRequest.request();

  // If any permission is permanently denied, guide user to app settings.
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
        home: isLoggedIn ? const AppShellPage() : const LandingPage(),
        // home: LandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
