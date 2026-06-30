import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF); // Vibrant Purple
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal Accent
  static const Color backgroundColor = Color(0xFF121212); // Dark Background
  static const Color surfaceColor =
      Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color errorColor = Color(0xFFCF6679);
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Colors.white;
  static const Color textSecondary = Colors.grey;

  static const Color lightPrimary = Color(0xFF6C63FF); // Same purple
  static const Color lightSecondary = Color(0xFF00BFA6); // Slightly deeper teal
  static const Color lightBackground = Color(0xFFF5F5F7); // Soft white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color lightError = Color(0xFFB00020);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnBackground = Color(0xFF1A1A1A); // Almost black text
  static const Color lightTextSecondary = Color(0xFF6E6E6E); // Neutral grey

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: onPrimary,
        onSurface: onBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily:
              'Outfit', // Assuming we might add a font later, or use default
        ),
        iconTheme: IconThemeData(color: onBackground),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: onBackground),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: onBackground),
        bodyLarge: TextStyle(fontSize: 16, color: onBackground),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBackground,
        error: lightError,
        onPrimary: lightOnPrimary,
        onSurface: lightOnBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
        iconTheme: IconThemeData(color: lightOnBackground),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightOnBackground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightOnBackground,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: lightOnBackground),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: lightOnPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: lightTextSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
