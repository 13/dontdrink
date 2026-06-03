/// A streak-based achievement. Achievements unlock automatically once the
/// user's longest (or current) alcohol-free streak reaches [dayThreshold].
class Achievement {
  const Achievement({
    required this.id,
    required this.dayThreshold,
    required this.title,
    required this.description,
    this.emoji = '🏆',
    this.isLegendary = false,
  });

  /// Stable identifier (used for persistence of unlock dates if needed).
  final String id;

  /// Number of consecutive alcohol-free days required to unlock.
  final int dayThreshold;

  final String title;
  final String description;
  final String emoji;

  /// Whether reaching this milestone triggers the big confetti celebration.
  final bool isLegendary;
}
