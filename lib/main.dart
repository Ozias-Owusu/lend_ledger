import 'package:flutter/material.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();

  // Request permissions at startup
  await _requestPermissions();

  await appState.loadFromDb();
  runApp(MyApp(appState: appState));
}
// Function to request necessary permissions
Future<void> _requestPermissions() async {
  // Request multiple permissions at once.
  Map<Permission, PermissionStatus> statuses = await [
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
  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // Retrieves the default theme for the platform
  TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    // TextTheme textTheme = createTextTheme(context, "Montez", "Noto Sans Mro");
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Loan Management',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
