import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// Aggregate statistics computed from a set of [DayEntry] rows.
class TrackerStats {
  const TrackerStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalAlcoholFreeDays,
    required this.totalLoggedDays,
    required this.levelCounts,
  });

  /// Consecutive alcohol-free days ending today (or yesterday if today is
  /// unlogged — see [StatsService.currentStreak]).
  final int currentStreak;

  /// Best alcohol-free run ever recorded.
  final int longestStreak;

  final int totalAlcoholFreeDays;
  final int totalLoggedDays;

  /// Count of logged days per drink level.
  final Map<DrinkLevel, int> levelCounts;

  /// Alcohol-free percentage of logged days (0–100).
  double get alcoholFreePercentage {
    if (totalLoggedDays == 0) return 0;
    return (totalAlcoholFreeDays / totalLoggedDays) * 100;
  }

  static const empty = TrackerStats(
    currentStreak: 0,
    longestStreak: 0,
    totalAlcoholFreeDays: 0,
    totalLoggedDays: 0,
    levelCounts: {},
  );
}

/// Pure functions that turn entry data into streaks and statistics.
///
/// Kept stateless so it is trivial to unit-test and reuse across view models.
class StatsService {
  const StatsService();

  /// Build a map from date-key to entry for fast lookup.
  Map<String, DayEntry> _index(List<DayEntry> entries) => {
        for (final e in entries) e.dateKey: e,
      };

  /// Current alcohol-free streak.
  ///
  /// Counts consecutive alcohol-free days ending today. If today has not been
  /// logged yet, the streak is measured ending yesterday so the number does not
  /// reset to zero just because the user hasn't opened the app today.
  int currentStreak(List<DayEntry> entries, {DateTime? now}) {
    if (entries.isEmpty) return 0;
    final index = _index(entries);
    final today = DateOnly.normalize(now ?? DateTime.now());

    // Decide where to start counting back from.
    DateTime cursor = today;
    final todayEntry = index[DateOnly.keyFor(today)];
    if (todayEntry == null) {
      // Today unlogged: start from yesterday.
      cursor = today.subtract(const Duration(days: 1));
    } else if (!todayEntry.level.isAlcoholFree) {
      // Today logged as a drinking day: streak is zero.
      return 0;
    }

    int streak = 0;
    while (true) {
      final entry = index[DateOnly.keyFor(cursor)];
      if (entry == null || !entry.level.isAlcoholFree) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest alcohol-free streak across all history.
  int longestStreak(List<DayEntry> entries) {
    if (entries.isEmpty) return 0;
    // Entries from the repo are sorted ascending, but don't rely on it.
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    int best = 0;
    int run = 0;
    DateTime? prev;
    for (final entry in sorted) {
      if (!entry.level.isAlcoholFree) {
        run = 0;
        prev = entry.date;
        continue;
      }
      if (prev != null && DateOnly.daysBetween(prev, entry.date) == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = entry.date;
    }
    return best;
  }

  /// Compute the full statistics bundle.
  TrackerStats compute(List<DayEntry> entries, {DateTime? now}) {
    final counts = {for (final level in DrinkLevel.values) level: 0};
    int alcoholFree = 0;
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
      if (entry.level.isAlcoholFree) alcoholFree++;
    }
    return TrackerStats(
      currentStreak: currentStreak(entries, now: now),
      longestStreak: longestStreak(entries),
      totalAlcoholFreeDays: alcoholFree,
      totalLoggedDays: entries.length,
      levelCounts: counts,
    );
  }

  /// Count entries by level for a single month.
  Map<DrinkLevel, int> monthLevelCounts(Map<String, DayEntry> monthEntries) {
    final counts = {for (final level in DrinkLevel.values) level: 0};
    for (final entry in monthEntries.values) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }
}

/// Alcohol-free vs. drinking counts for one calendar month.
class MonthlyTotals {
  const MonthlyTotals({
    required this.month,
    required this.alcoholFreeDays,
    required this.drinkingDays,
  });

  final DateTime month;
  final int alcoholFreeDays;
  final int drinkingDays;

  int get loggedDays => alcoholFreeDays + drinkingDays;
}

extension MonthlyAggregation on StatsService {
  /// Alcohol-free / drinking totals for the [count] most recent months ending
  /// with the month containing [now]. Always returns [count] entries (zero-
  /// filled) so charts have a stable x-axis.
  List<MonthlyTotals> recentMonths(
    List<DayEntry> entries, {
    int count = 6,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final buckets = <String, MonthlyTotals>{};

    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month}';
      final existing = buckets[key];
      final free = entry.level.isAlcoholFree ? 1 : 0;
      buckets[key] = MonthlyTotals(
        month: DateTime(entry.date.year, entry.date.month),
        alcoholFreeDays: (existing?.alcoholFreeDays ?? 0) + free,
        drinkingDays: (existing?.drinkingDays ?? 0) + (1 - free),
      );
    }

    final result = <MonthlyTotals>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(reference.year, reference.month - i);
      final key = '${m.year}-${m.month}';
      result.add(
        buckets[key] ??
            MonthlyTotals(month: m, alcoholFreeDays: 0, drinkingDays: 0),
      );
    }
    return result;
  }
}
