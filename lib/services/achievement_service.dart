import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/services/stats_service.dart';

/// A view of an achievement plus how often the user has earned it.
class AchievementStatus {
  const AchievementStatus({
    required this.achievement,
    required this.earnedCount,
    this.firstEarnedOn,
    this.lastEarnedOn,
  });

  final Achievement achievement;

  /// How many separate clean runs have reached this achievement's threshold.
  final int earnedCount;

  /// Day the first qualifying run crossed the threshold.
  final DateTime? firstEarnedOn;

  /// Day the most recent qualifying run crossed the threshold.
  final DateTime? lastEarnedOn;

  bool get unlocked => earnedCount > 0;

  /// True once the same badge has been earned more than once.
  bool get isRepeated => earnedCount > 1;
}

/// One earning of an achievement, carrying the running total so the UI can
/// say whether this was the first time or the fourth.
class AchievementEarn {
  const AchievementEarn({required this.achievement, required this.count});

  final Achievement achievement;

  /// Total times the badge has now been earned — 1 on the first earn.
  final int count;

  bool get isRepeat => count > 1;
}

/// Derives achievement state from clean-streak runs.
///
/// A badge is earned once per run that reaches its threshold, so it is not a
/// one-off unlock: relapsing and climbing back to the same length earns it
/// again and the count grows. Earned badges are never taken away — a run that
/// already qualified stays in history — and the achievement list comes from
/// the active mode's content pack, so badges never cross between modes.
class AchievementService {
  const AchievementService();

  /// How often each achievement has been earned, keyed by achievement id.
  Map<String, int> earnCounts({
    required List<Achievement> achievements,
    required List<StreakRun> runs,
  }) {
    return {
      for (final a in achievements)
        a.id: runs.where((r) => r.length >= a.dayThreshold).length,
    };
  }

  List<AchievementStatus> evaluate({
    required List<Achievement> achievements,
    required List<StreakRun> runs,
  }) {
    return achievements.map((a) {
      final qualifying =
          runs.where((r) => r.length >= a.dayThreshold).toList();
      return AchievementStatus(
        achievement: a,
        earnedCount: qualifying.length,
        firstEarnedOn: qualifying.isEmpty
            ? null
            : qualifying.first.dayReaching(a.dayThreshold),
        lastEarnedOn: qualifying.isEmpty
            ? null
            : qualifying.last.dayReaching(a.dayThreshold),
      );
    }).toList();
  }

  /// Achievements whose earn count grew between two snapshots, used to trigger
  /// the celebration.
  ///
  /// Comparing counts rather than streak length also catches the case where
  /// back-filling a forgotten day completes an *older* run: the current streak
  /// never moved, but a badge was still earned.
  List<AchievementEarn> newlyEarned({
    required List<Achievement> achievements,
    required Map<String, int> previousCounts,
    required Map<String, int> currentCounts,
  }) {
    final earned = <AchievementEarn>[];
    for (final a in achievements) {
      final before = previousCounts[a.id] ?? 0;
      final now = currentCounts[a.id] ?? 0;
      if (now > before) {
        earned.add(AchievementEarn(achievement: a, count: now));
      }
    }
    return earned;
  }

  /// The next achievement the user is working toward from their *current*
  /// streak, or null if the current run has already passed them all.
  ///
  /// This tracks the run in progress, not the personal best: after a relapse
  /// the goal is the first milestone again, even when it has been earned
  /// several times before.
  Achievement? nextLocked(List<Achievement> achievements, int currentStreak) {
    for (final a in achievements) {
      if (currentStreak < a.dayThreshold) return a;
    }
    return null;
  }
}
