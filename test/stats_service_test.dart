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

  group('cleanRuns', () {
    test('returns one run per unbroken stretch of clean days', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _none),
        _entry(DateTime(2026, 6, 3), _heavy),
        _entry(DateTime(2026, 6, 4), _none),
        _entry(DateTime(2026, 6, 5), _none),
        _entry(DateTime(2026, 6, 6), _none),
      ];
      final runs = service.cleanRuns(entries);
      expect(runs.map((r) => r.length), [2, 3]);
      expect(runs.first.start, DateTime(2026, 6, 1));
      expect(runs.first.end, DateTime(2026, 6, 2));
      expect(runs.last.start, DateTime(2026, 6, 4));
      expect(runs.last.end, DateTime(2026, 6, 6));
    });

    test('a gap in the log splits a run, like currentStreak', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _none),
        // 6-3 unlogged
        _entry(DateTime(2026, 6, 4), _none),
      ];
      expect(service.cleanRuns(entries).map((r) => r.length), [2, 1]);
    });

    test('sorts unordered input before walking it', () {
      final entries = [
        _entry(DateTime(2026, 6, 3), _none),
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _none),
      ];
      expect(service.cleanRuns(entries).single.length, 3);
    });

    test('a light day still breaks the run', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _none),
        _entry(DateTime(2026, 6, 2), _light),
        _entry(DateTime(2026, 6, 3), _none),
      ];
      expect(service.cleanRuns(entries).map((r) => r.length), [1, 1]);
    });

    test('history of only non-clean days has no runs', () {
      final entries = [
        _entry(DateTime(2026, 6, 1), _heavy),
        _entry(DateTime(2026, 6, 2), _heavy),
      ];
      expect(service.cleanRuns(entries), isEmpty);
      expect(service.cleanRuns(const []), isEmpty);
    });

    test('dayReaching gives the day the run crossed a threshold', () {
      final run = service
          .cleanRuns([
            _entry(DateTime(2026, 6, 1), _none),
            _entry(DateTime(2026, 6, 2), _none),
            _entry(DateTime(2026, 6, 3), _none),
          ])
          .single;
      expect(run.dayReaching(1), DateTime(2026, 6, 1));
      expect(run.dayReaching(3), DateTime(2026, 6, 3));
      expect(run.dayReaching(4), isNull);
    });
  });

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
