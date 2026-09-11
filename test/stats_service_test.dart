import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

// `const` is not possible here: indexing a const list is not a constant
// expression in Dart.
final _none = kDontDrinkLevels[0];
final _light = kDontDrinkLevels[1];
final _heavy = kDontDrinkLevels[3];

DayEntry _entry(DateTime date, TrackedLevel level) =>
    DayEntry(modeId: 'dont_drink', date: date, level: level);

void main() {
  const service = StatsService();
  final now = DateTime(2026, 6, 3);

  group('currentStreak', () {
    test('counts consecutive alcohol-free days ending today', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _none),
        _entry(DateTime(2026, 6, 3), _none),
      ];
      expect(service.currentStreak(entries, now: now), 3);
    });

    test('returns 0 when today is a drinking day', () {
      final entries = [
        _entry(DateTime(2026, 6, 2), _none),
        _entry(DateTime(2026, 6, 3), _heavy),
      ];
      expect(service.currentStreak(entries, now: now), 0);
    });

    test('uses yesterday when today is unlogged', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _none),
      ];
      expect(service.currentStreak(entries, now: now), 2);
    });

    test('breaks the streak on a gap', () {
      final entries = [
        _entry(DateTime(2026, 5, 30), _none),
        // 31st missing
        _entry(DateTime(2026, 6, 2), _none),
        _entry(DateTime(2026, 6, 3), _none),
      ];
      expect(service.currentStreak(entries, now: now), 2);
    });
  });

  group('longestStreak', () {
    test('finds the best run across history', () {
      final entries = [
        _entry(DateTime(2026, 1, 1), _none),
        _entry(DateTime(2026, 1, 2), _none),
        _entry(DateTime(2026, 1, 3), _heavy),
        _entry(DateTime(2026, 1, 4), _none),
        _entry(DateTime(2026, 1, 5), _none),
        _entry(DateTime(2026, 1, 6), _none),
      ];
      expect(service.longestStreak(entries), 3);
    });
  });

  group('compute', () {
    test('aggregates totals and percentage', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _light),
        _entry(DateTime(2026, 6, 3), _none),
      ];
      final stats = service.compute(entries, kDontDrinkMode, now: now);
      expect(stats.totalLoggedDays, 3);
      expect(stats.totalCleanDays, 2);
      expect(stats.cleanDayPercentage, closeTo(66.67, 0.1));
    });
  });

  group('recentMonths', () {
    test('zero-fills to the requested count', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _heavy),
      ];
      final months = service.recentMonths(entries, count: 6, now: now);
      expect(months.length, 6);
      expect(months.last.cleanDays, 1);
      expect(months.last.otherDays, 1);
    });
  });
}
