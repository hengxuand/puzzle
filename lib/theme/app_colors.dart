import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary high saturation colors
  static const Color primary = Color(0xFF0066FF); // Vivid Blue
  static const Color primaryVariant = Color(0xFF0052CC); // Deep Blue
  static const Color secondary = Color(0xFFFF006E); // Vivid Pink
  static const Color secondaryVariant = Color(0xFFCC0058); // Deep Pink

  // Background colors
  static const Color background = Color(0xFFF8F9FF); // Very light blue tint
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF); // White for cards

  // Text colors
  static const Color textPrimary = Color(0xFF1A1B3A); // Dark blue-gray
  static const Color textSecondary = Color(0xFF4A5568); // Medium gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // UI Element colors
  static const Color border = Color(0xFFE2E8F0); // Light gray
  static const Color divider = Color(0xFFCBD5E0); // Medium light gray
  static const Color shadow = Color(0x1A000000); // Light shadow

  // Status colors - high saturation
  static const Color success = Color(0xFF00C853); // Vivid Green
  static const Color warning = Color(0xFFFF6D00); // Vivid Orange
  static const Color error = Color(0xFFFF1744); // Vivid Red
  static const Color info = Color(0xFF00B0FF); // Vivid Cyan

  // Game-specific colors
  static const Color gameBoard = Color(0xFFF5F7FF); // Very light blue
  static const Color tileBackground = Color(0xFFFFFFFF); // White tiles
  static const Color tileBorder = Color(0xFFD1D9FF); // Light blue border
  static const Color emptySlot = Color.fromARGB(
    77,
    111,
    126,
    111,
  ); // Light blue for empty slots

  // Welcome screen colors
  static const Color welcomeCard = Color(0xFFFFFFFF); // White cards
  static const Color welcomeCardShadow = Color(0x33000000); // Card shadow
  static const Color welcomeText = Color(0xFF1E2E45); // Dark blue text
  static const Color welcomeSelected = Color(0xFF9C6936); // Gold accent
  static const Color welcomeLocked = Color(0xFFECECEC); // Light gray for locked
  static const Color welcomeCompleted = Color(
    0xFF2D7D54,
  ); // Green for completed

  // Level selector colors
  static const Color levelCardBackground = Color(0xFFF9F6EF); // Warm white
  static const Color levelCardLocked = Color(0xFFE0E0E0); // Gray for locked
  static const Color levelCardText = Color(0xFF7A4E24); // Brown for text
  static const Color levelCardCompleted = Color(
    0xFF2D7D54,
  ); // Green for completed
  static const Color levelCardLockedText = Color(0xFF7A7A7A); // Gray text

  // Gradient colors
  static const Color gradientStart = Color(0xFFF4D9A9); // Light gold
  static const Color gradientEnd = Color(0xFFF9F6EF); // Warm white

  // Interactive elements
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color iconActive = primary;
  static const Color iconInactive = Color(0xFF9CA3AF); // Medium gray

  // Overlay and transparency
  static const Color overlayDark = Color(0x88000000); // 50% black overlay
  static const Color overlayLight = Color(0x88FFFFFF); // 50% white overlay
  static const Color highlightOverlay = Color(
    0x8876879A,
  ); // Blue-tinted overlay

  // Flame game specific colors
  static const Color flameBackground = Color.fromARGB(
    255,
    153,
    176,
    206,
  ); // Keep original for now
  static const Color flameCardFront = Color(0xFFF3EDE6); // Warm off-white
  static const Color flameCardBack = Color(0xFFFBEFDA); // Light cream
  static const Color flameCardSide = Color(0xFFE7E3DC); // Soft gray
  static const Color flameCardShadow = Color(0xFF1B1B14); // Dark shadow
  static const Color flameCardHighlight = Color(0xFF3A4B61); // Blue highlight
  static const Color flameTextPrimary = Color(0xFF55667D); // Medium blue
  static const Color flameTextSecondary = Color(0xFF4A5E78); // Darker blue
  static const Color flameButton = Color(0xFF64748B); // Slate blue
  static const Color flameSelectedBorder = Color(0xFF9C6936); // Gold border
  static const Color flameUnselectedBorder = Color(0xFFD0C7B8); // Light brown
  static const Color flameRowEven = Color(0xFFF4D9A9); // Light gold
  static const Color flameRowOdd = Color(0xFFF9F6EF); // Warm white
  static const Color flameRowLocked = Color(0xFFECECEC); // Light gray
  static const Color flameNumberBackground = Color(0xFF213147); // Dark blue
  static const Color flameNumberText = Color(0xFF57667A); // Medium blue
  static const Color flameNumberShadow = Color(0xFF5B6D84); // Blue-gray
  static const Color flameHoverOverlay = Color(0x8894A4B8); // Blue overlay
  static const Color flameHoverSelected = Color(0xFF815327); // Brown on hover

  // Special colors
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color green = Colors.green;
}

class AppColorScheme {
  AppColorScheme._();

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnPrimary,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    surface: Color(0xFF1A1B3A),
    onSurface: AppColors.textOnPrimary,
    background: Color(0xFF0F1121),
    onBackground: AppColors.textOnPrimary,
  );
}
