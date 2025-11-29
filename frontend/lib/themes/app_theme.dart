import 'package:flutter/material.dart';

class AppTheme {
  // Netflix-style color palette
  static const Color primaryRed = Color(0xFFE50914);
  static const Color darkRed = Color(0xFFB20710);
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF141414);
  static const Color mediumGray = Color(0xFF2F2F2F);
  static const Color lightGray = Color(0xFF808080);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: darkRed,
        surface: darkGray,
        background: black,
        error: primaryRed,
        onPrimary: white,
        onSecondary: white,
        onSurface: white,
        onBackground: white,
        onError: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        iconTheme: IconThemeData(color: white),
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkGray,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: white, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: white, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: white, fontSize: 16),
        bodyMedium: TextStyle(color: lightGray, fontSize: 14),
        bodySmall: TextStyle(color: lightGray, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mediumGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: lightGray),
      ),
    );
  }
}

