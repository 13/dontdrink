import 'package:flutter/material.dart';

/// Centralized palette for app chrome. Per-day status colors live on each
/// mode's [TrackedLevel]s, not here.
class AppColors {
  AppColors._();

  /// Used by the streak gradient and "good news" accents.
  static const Color green = Color(0xFF4CAF50);

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
