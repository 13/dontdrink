import 'package:flutter/material.dart';

/// The five drinking statuses a user can log for a given day.
///
/// The integer [value] is what gets persisted in the database, so the order
/// and numbers must remain stable across releases.
enum DrinkLevel {
  none(
    value: 0,
    label: 'No Drinks',
    shortLabel: 'None',
    meaning: '0 alcoholic drinks',
    color: Color(0xFF4CAF50), // Green
    emoji: '💚',
  ),
  light(
    value: 1,
    label: '1–2 Drinks',
    shortLabel: 'Light',
    meaning: 'Light drinking',
    color: Color(0xFFFFC107), // Yellow / Amber
    emoji: '🟡',
  ),
  moderate(
    value: 2,
    label: '3–5 Drinks',
    shortLabel: 'Moderate',
    meaning: 'Moderate drinking',
    color: Color(0xFFFF9800), // Orange
    emoji: '🟠',
  ),
  heavy(
    value: 3,
    label: '6+ Drinks',
    shortLabel: 'Heavy',
    meaning: 'Heavy drinking',
    color: Color(0xFFF44336), // Red
    emoji: '🔴',
  ),
  blackout(
    value: 4,
    label: 'Blackout',
    shortLabel: 'Blackout',
    meaning: 'Extreme drinking / memory loss',
    color: Color(0xFF000000), // Black
    emoji: '⚫',
  );

  const DrinkLevel({
    required this.value,
    required this.label,
    required this.shortLabel,
    required this.meaning,
    required this.color,
    required this.emoji,
  });

  /// Persisted integer code.
  final int value;

  /// Full label, e.g. "1–2 Drinks".
  final String label;

  /// Compact label for tight spaces, e.g. "Light".
  final String shortLabel;

  /// Human description of what this level means.
  final String meaning;

  /// Calendar / chart color.
  final Color color;

  /// Emoji used in lists and notifications.
  final String emoji;

  /// True when this status counts toward an alcohol-free streak.
  bool get isAlcoholFree => this == DrinkLevel.none;

  /// A readable foreground color that sits well on top of [color].
  Color get onColor {
    // Black and red are dark enough to need white text; amber needs dark text.
    switch (this) {
      case DrinkLevel.light:
      case DrinkLevel.moderate:
        return Colors.black87;
      case DrinkLevel.none:
      case DrinkLevel.heavy:
      case DrinkLevel.blackout:
        return Colors.white;
    }
  }

  /// Restore a [DrinkLevel] from its persisted [value].
  static DrinkLevel fromValue(int value) {
    return DrinkLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DrinkLevel.none,
    );
  }
}
