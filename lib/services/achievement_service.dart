import 'package:dont_drink/core/models/achievement.dart';

/// A view of an achievement plus whether the user has unlocked it.
class AchievementStatus {
  const AchievementStatus({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;
}

/// Derives achievement unlock state from streak data.
///
/// An achievement is considered permanently earned once the user's *longest*
/// streak in that mode has ever reached its threshold — so a relapse doesn't
/// erase a badge. The achievement list comes from the active mode's content
/// pack, so badges never cross between modes.
class AchievementService {
  const AchievementService();

  List<AchievementStatus> evaluate({
    required List<Achievement> achievements,
    required int longestStreak,
  }) {
    return achievements
        .map((a) => AchievementStatus(
              achievement: a,
              unlocked: longestStreak >= a.dayThreshold,
            ))
        .toList();
  }

  /// Achievements newly crossed when the longest streak grows from
  /// [previousLongest] to [newLongest]. Used to trigger unlock animations.
  List<Achievement> newlyUnlocked({
    required List<Achievement> achievements,
    required int previousLongest,
    required int newLongest,
  }) {
    return achievements
        .where((a) =>
            a.dayThreshold > previousLongest && a.dayThreshold <= newLongest)
        .toList();
  }

  /// The next achievement the user is working toward, or null if all unlocked.
  Achievement? nextLocked(List<Achievement> achievements, int longestStreak) {
    for (final a in achievements) {
      if (longestStreak < a.dayThreshold) return a;
    }
    return null;
  }
}
