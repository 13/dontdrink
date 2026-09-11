import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the rule that makes badges repeatable: a badge is earned once per
/// clean run that reaches its threshold, so a relapse costs the streak but
/// never the badge, and climbing back earns it again.
void main() {
  const service = AchievementService();

  const day3 = Achievement(
    id: 'test.day_3',
    dayThreshold: 3,
    title: 'Three days',
    description: '',
  );
  const day7 = Achievement(
    id: 'test.day_7',
    dayThreshold: 7,
    title: 'One week',
    description: '',
  );
  const day30 = Achievement(
    id: 'test.day_30',
    dayThreshold: 30,
    title: 'One month',
    description: '',
  );
  const achievements = [day3, day7, day30];

  StreakRun run(DateTime start, int length) => StreakRun(
        start: start,
        end: start.add(Duration(days: length - 1)),
        length: length,
      );

  group('earnCounts', () {
    test('counts every run that reaches the threshold', () {
      final runs = [
        run(DateTime(2026, 1, 1), 12),
        run(DateTime(2026, 2, 1), 3),
        run(DateTime(2026, 3, 1), 45),
        run(DateTime(2026, 5, 1), 8),
      ];
      final counts =
          service.earnCounts(achievements: achievements, runs: runs);
      expect(counts['test.day_3'], 4);
      expect(counts['test.day_7'], 3);
      expect(counts['test.day_30'], 1);
    });

    test('a run shorter than every threshold earns nothing', () {
      final counts = service.earnCounts(
        achievements: achievements,
        runs: [run(DateTime(2026, 1, 1), 2)],
      );
      expect(counts.values, everyElement(0));
    });

    test('no history means no earns', () {
      final counts =
          service.earnCounts(achievements: achievements, runs: const []);
      expect(counts.values, everyElement(0));
    });
  });

  group('evaluate', () {
    test('reports the count and the first and last earning days', () {
      final runs = [
        run(DateTime(2026, 1, 1), 10), // day_3 on Jan 3, day_7 on Jan 7
        run(DateTime(2026, 4, 1), 4), // day_3 on Apr 3
      ];
      final statuses =
          service.evaluate(achievements: achievements, runs: runs);
      final three = statuses.firstWhere((s) => s.achievement.id == day3.id);
      final seven = statuses.firstWhere((s) => s.achievement.id == day7.id);
      final thirty = statuses.firstWhere((s) => s.achievement.id == day30.id);

      expect(three.earnedCount, 2);
      expect(three.isRepeated, isTrue);
      expect(three.firstEarnedOn, DateTime(2026, 1, 3));
      expect(three.lastEarnedOn, DateTime(2026, 4, 3));

      expect(seven.earnedCount, 1);
      expect(seven.isRepeated, isFalse);
      expect(seven.firstEarnedOn, DateTime(2026, 1, 7));
      expect(seven.lastEarnedOn, DateTime(2026, 1, 7));

      expect(thirty.unlocked, isFalse);
      expect(thirty.firstEarnedOn, isNull);
      expect(thirty.lastEarnedOn, isNull);
    });

    test('a badge earned once stays earned after a relapse', () {
      final statuses = service.evaluate(
        achievements: achievements,
        // The long run is over; the current one is a single day.
        runs: [run(DateTime(2026, 1, 1), 40), run(DateTime(2026, 3, 1), 1)],
      );
      expect(
        statuses.firstWhere((s) => s.achievement.id == day30.id).unlocked,
        isTrue,
      );
    });
  });

  group('newlyEarned', () {
    test('reports each badge whose count grew, with the new total', () {
      final earned = service.newlyEarned(
        achievements: achievements,
        previousCounts: const {'test.day_3': 1, 'test.day_7': 0},
        currentCounts: const {'test.day_3': 2, 'test.day_7': 1},
      );
      expect(earned.map((e) => e.achievement.id), ['test.day_3', 'test.day_7']);
      expect(earned.first.count, 2);
      expect(earned.first.isRepeat, isTrue);
      expect(earned.last.count, 1);
      expect(earned.last.isRepeat, isFalse);
    });

    test('unchanged counts report nothing', () {
      expect(
        service.newlyEarned(
          achievements: achievements,
          previousCounts: const {'test.day_3': 2},
          currentCounts: const {'test.day_3': 2},
        ),
        isEmpty,
      );
    });

    test('a dropped count is not an earn', () {
      expect(
        service.newlyEarned(
          achievements: achievements,
          previousCounts: const {'test.day_3': 2},
          currentCounts: const {'test.day_3': 1},
        ),
        isEmpty,
      );
    });
  });

  group('nextLocked', () {
    test('follows the current run, not the personal best', () {
      expect(service.nextLocked(achievements, 0)?.id, day3.id);
      expect(service.nextLocked(achievements, 3)?.id, day7.id);
      expect(service.nextLocked(achievements, 29)?.id, day30.id);
    });

    test('returns null once the current run has passed them all', () {
      expect(service.nextLocked(achievements, 30), isNull);
    });
  });
}
