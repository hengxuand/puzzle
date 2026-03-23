import 'package:flutter/material.dart';
import 'package:puzzle/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: AppColorScheme.lightColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.shadow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconActive,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: AppColorScheme.darkColorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F1121),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1B3A),
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1B3A),
        elevation: 2,
        shadowColor: AppColors.shadow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconActive,
      ),
    );
  }
}
