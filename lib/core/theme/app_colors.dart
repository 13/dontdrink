import 'package:flutter/material.dart';

/// Centralized palette. The five status colors are shared with [DrinkLevel];
/// these constants exist for use outside of an enum context (gradients, charts).
class AppColors {
  AppColors._();

  // Status colors (mirror DrinkLevel).
  static const Color green = Color(0xFF4CAF50);
  static const Color yellow = Color(0xFFFFC107);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFF44336);
  static const Color black = Color(0xFF000000);

  // Brand accent — a calm teal/green that reads as "healthy".
  static const Color brand = Color(0xFF2E9E83);
  static const Color brandDark = Color(0xFF1F7A65);

  // Light theme surfaces.
  static const Color lightBackground = Color(0xFFF5F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark theme surfaces.
  static const Color darkBackground = Color(0xFF101417);
  static const Color darkSurface = Color(0xFF1A2025);
}
