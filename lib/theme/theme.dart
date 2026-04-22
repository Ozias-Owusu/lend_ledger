import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color softRose = Color(0xFFD7A9A4);
  static const Color peach = Color(0xFFE7C6B7);
  static const Color mintGray = Color(0xFFC9D9D3);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: softRose,
      brightness: Brightness.light,
      primary: softRose,
      secondary: peach,
      tertiary: mintGray,
      surface: const Color(0xFFFFFAF8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: softRose,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: softRose,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: peach.withValues(alpha: 0.18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mintGray.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softRose, width: 1.6),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: softRose,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
