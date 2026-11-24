import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0B1F3A);
  static const lightBlue = Color(0xFFE3F0FF);
  static const gray = Color(0xFFF2F4F7);
  static const green = Color(0xFF2E9E5B);
  static const orange = Color(0xFFF28C28);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: const Color(0xFF3B82F6),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.gray,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}
