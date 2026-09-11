import 'package:flutter/material.dart';

/// One loggable status within a tracking mode.
///
/// The integer [value] is what gets persisted in the database, so a mode's
/// values must remain stable across releases. Value `0` is always the clean
/// day — the one that counts toward a streak.
@immutable
class TrackedLevel {
  const TrackedLevel({
    required this.value,
    required this.label,
    required this.shortLabel,
    required this.meaning,
    required this.color,
    required this.emoji,
    this.isClean = false,
  });

  /// Persisted integer code, unique within its mode.
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

  /// True when this status counts toward a streak.
  final bool isClean;

  /// A readable foreground color that sits well on top of [color].
  ///
  /// The 0.4 threshold (rather than the usual 0.5) is deliberate: it keeps
  /// amber and orange on dark text, matching the palette the app shipped with.
  Color get onColor =>
      color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedLevel && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}
