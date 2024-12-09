import 'package:flutter/material.dart';

class AppColors {
  // Define the color palette
  static const Color primaryYellow = Color(0xFFE8C766); // Main Yellow
  static const Color secondaryYellow =
      Color(0xFFE8AF30); // Darker Yellow/Orange
  static const Color lightYellow = Color(0xFFFFF3D8); // Light Yellow
  static const Color accentBlue = Color(0xFF3361AC); // Blue for accents
  static const Color darkBlue = Color(0xFF162F65); // Dark Blue for contrast
  static const Color darkestBlue = Color(0xFF0F2043); // Darkest Blue for text
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryYellow,
      secondary: AppColors.secondaryYellow,
      tertiary: AppColors.accentBlue,
      background: AppColors.lightYellow,
      surface: Colors.white,
      onPrimary: AppColors.darkestBlue,
      onSecondary: Colors.white,
      onBackground: AppColors.darkestBlue,
      onSurface: AppColors.darkestBlue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: AppColors.darkestBlue,
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.lightYellow,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryYellow,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondaryYellow,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondaryYellow),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondaryYellow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
    ),
  );
}
