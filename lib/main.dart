import 'package:flutter/material.dart';
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
  await [
    Permission.camera,
    Permission.storage,
    Permission.photos, // Recommended for iOS
    Permission.videos, // Recommended for Android 13+
  ].request();

  // You can check the status of each permission and handle it accordingly.
  // For example, show a dialog if a permission is permanently denied.
  if (await Permission.camera.isPermanentlyDenied ||
      await Permission.storage.isPermanentlyDenied) {
    // The user has permanently denied the permission, open app settings.
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
