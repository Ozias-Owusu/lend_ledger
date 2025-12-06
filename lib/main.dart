import 'package:flutter/material.dart';
import 'package:lend_ledger/pages/landing_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();

  await appState.loadFromDb();
  runApp(MyApp(appState: appState));
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
