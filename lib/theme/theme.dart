import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color softRose = Color(0xFFD7A9A4);
  static const Color peach = Color(0xFFE7C6B7);
  static const Color mintGray = Color(0xFFC9D9D3);

  /// Primary text — matches Settings screen.
  static const Color textPrimary = Color(0xFF4A3F3D);
  static const Color textSecondary = Color(0xFF6B5E5B);
  static const Color textMuted = Color(0xFF8A7A76);

  /// Display headings (Settings title, landing hero).
  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? height,
  }) {
    return GoogleFonts.dmSerifDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Body copy, labels, buttons (Settings lists, forms).
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textSecondary,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.45,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextTheme _buildTextTheme() {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme();

    return jakarta.copyWith(
      displayLarge: display(fontSize: 36),
      displayMedium: display(fontSize: 32),
      displaySmall: display(fontSize: 28),
      headlineLarge: display(fontSize: 28),
      headlineMedium: body(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: body(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: body(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: body(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: body(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: textMuted),
      labelLarge: body(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: body(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
      ),
      labelSmall: body(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textMuted,
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: softRose,
      brightness: Brightness.light,
      primary: softRose,
      secondary: peach,
      tertiary: mintGray,
      surface: const Color(0xFFFFFAF8),
      onSurface: textPrimary,
    );

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: softRose,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: body(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        toolbarTextStyle: body(color: Colors.white),
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
        labelStyle: body(fontSize: 14, color: textMuted),
        hintStyle: body(fontSize: 14, color: textMuted),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: body(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: body(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: body(fontWeight: FontWeight.w600, color: softRose),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: body(fontWeight: FontWeight.w600, color: textPrimary),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: body(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        subtitleTextStyle: body(fontSize: 12, color: textMuted),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: body(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: body(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: softRose,
        contentTextStyle: body(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: body(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: body(fontSize: 12, color: textMuted),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: body(fontWeight: FontWeight.w600, color: textPrimary),
        unselectedLabelStyle: body(color: textMuted),
      ),
    );
  }
}
