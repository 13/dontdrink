import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

DayEntry _entry(DateTime date, DrinkLevel level) =>
    DayEntry(date: date, level: level);

void main() {
  const service = StatsService();
  final now = DateTime(2026, 6, 3);

  group('currentStreak', () {
    test('counts consecutive alcohol-free days ending today', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), DrinkLevel.none),
        _entry(DateTime(2026, 6, 2), DrinkLevel.none),
        _entry(DateTime(2026, 6, 3), DrinkLevel.none),
      ];
      expect(service.currentStreak(entries, now: now), 3);
    });

    test('returns 0 when today is a drinking day', () {
      final entries = [
        _entry(DateTime(2026, 6, 2), DrinkLevel.none),
        _entry(DateTime(2026, 6, 3), DrinkLevel.heavy),
      ];
      expect(service.currentStreak(entries, now: now), 0);
    });

    test('uses yesterday when today is unlogged', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), DrinkLevel.none),
        _entry(DateTime(2026, 6, 2), DrinkLevel.none),
      ];
      expect(service.currentStreak(entries, now: now), 2);
    });

    test('breaks the streak on a gap', () {
      final entries = [
        _entry(DateTime(2026, 5, 30), DrinkLevel.none),
        // 31st missing
        _entry(DateTime(2026, 6, 2), DrinkLevel.none),
        _entry(DateTime(2026, 6, 3), DrinkLevel.none),
      ];
      expect(service.currentStreak(entries, now: now), 2);
    });
  });

  group('longestStreak', () {
    test('finds the best run across history', () {
      final entries = [
        _entry(DateTime(2026, 1, 1), DrinkLevel.none),
        _entry(DateTime(2026, 1, 2), DrinkLevel.none),
        _entry(DateTime(2026, 1, 3), DrinkLevel.heavy),
        _entry(DateTime(2026, 1, 4), DrinkLevel.none),
        _entry(DateTime(2026, 1, 5), DrinkLevel.none),
        _entry(DateTime(2026, 1, 6), DrinkLevel.none),
      ];
      expect(service.longestStreak(entries), 3);
    });
  });

  group('compute', () {
    test('aggregates totals and percentage', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), DrinkLevel.none),
        _entry(DateTime(2026, 6, 2), DrinkLevel.light),
        _entry(DateTime(2026, 6, 3), DrinkLevel.none),
      ];
      final stats = service.compute(entries, now: now);
      expect(stats.totalLoggedDays, 3);
      expect(stats.totalAlcoholFreeDays, 2);
      expect(stats.alcoholFreePercentage, closeTo(66.67, 0.1));
    });
  });

  group('recentMonths', () {
    test('zero-fills to the requested count', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), DrinkLevel.none),
        _entry(DateTime(2026, 6, 2), DrinkLevel.heavy),
      ];
      final months = service.recentMonths(entries, count: 6, now: now);
      expect(months.length, 6);
      expect(months.last.alcoholFreeDays, 1);
      expect(months.last.drinkingDays, 1);
    });
  });
}
