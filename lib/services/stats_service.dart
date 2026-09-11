import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// One unbroken run of clean days.
///
/// Runs are what makes an achievement repeatable: a badge is earned once per
/// run that reaches its threshold, so relapsing and climbing back earns it
/// again rather than leaving the first unlock as the only record.
class StreakRun {
  const StreakRun({
    required this.start,
    required this.end,
    required this.length,
  });

  /// First clean day of the run.
  final DateTime start;

  /// Last clean day of the run.
  final DateTime end;

  /// Number of days in the run.
  final int length;

  /// The day this run reached [days] clean days, or null if it never got
  /// that far.
  DateTime? dayReaching(int days) {
    if (days <= 0 || length < days) return null;
    return DateOnly.normalize(start.add(Duration(days: days - 1)));
  }
}

/// Aggregate statistics computed from a set of [DayEntry] rows, all belonging
/// to a single mode.
class TrackerStats {
  const TrackerStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCleanDays,
    required this.totalLoggedDays,
    required this.levelCounts,
  });

  /// Consecutive clean days ending today (or yesterday if today is unlogged —
  /// see [StatsService.currentStreak]).
  final int currentStreak;

  /// Best clean run ever recorded.
  final int longestStreak;

  final int totalCleanDays;
  final int totalLoggedDays;

  /// Count of logged days per level.
  final Map<TrackedLevel, int> levelCounts;

  /// Clean percentage of logged days (0–100).
  double get cleanDayPercentage {
    if (totalLoggedDays == 0) return 0;
    return (totalCleanDays / totalLoggedDays) * 100;
  }

  static const empty = TrackerStats(
    currentStreak: 0,
    longestStreak: 0,
    totalCleanDays: 0,
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

  /// Current clean streak.
  ///
  /// Counts consecutive clean days ending today. If today has not been
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
    } else if (!todayEntry.level.isClean) {
      // Today logged as a non-clean day: streak is zero.
      return 0;
    }

    int streak = 0;
    while (true) {
      final entry = index[DateOnly.keyFor(cursor)];
      if (entry == null || !entry.level.isClean) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Every unbroken run of clean days in [entries], oldest first.
  ///
  /// A run ends at a non-clean day *or* at a gap in the log: two clean days
  /// with an unlogged day between them are two runs, matching how
  /// [currentStreak] stops counting at the first missing day.
  List<StreakRun> cleanRuns(List<DayEntry> entries) {
    if (entries.isEmpty) return const [];
    // Entries from the repo are sorted ascending, but don't rely on it.
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    final runs = <StreakRun>[];
    DateTime? runStart;
    DateTime? prev;
    int run = 0;

    void closeRun() {
      if (run > 0) {
        runs.add(StreakRun(start: runStart!, end: prev!, length: run));
      }
      run = 0;
      runStart = null;
    }

    for (final entry in sorted) {
      final date = DateOnly.normalize(entry.date);
      if (!entry.level.isClean) {
        closeRun();
        prev = date;
        continue;
      }
      if (run > 0 && DateOnly.daysBetween(prev!, date) == 1) {
        run += 1;
      } else {
        closeRun();
        run = 1;
        runStart = date;
      }
      prev = date;
    }
    closeRun();
    return runs;
  }

  /// Longest clean streak across all history.
  int longestStreak(List<DayEntry> entries) {
    int best = 0;
    for (final run in cleanRuns(entries)) {
      if (run.length > best) best = run.length;
    }
    return best;
  }

  /// Compute the full statistics bundle for [mode].
  TrackerStats compute(
    List<DayEntry> entries,
    ModeDefinition mode, {
    DateTime? now,
  }) {
    final counts = {for (final level in mode.levels) level: 0};
    int clean = 0;
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
      if (entry.level.isClean) clean++;
    }
    return TrackerStats(
      currentStreak: currentStreak(entries, now: now),
      longestStreak: longestStreak(entries),
      totalCleanDays: clean,
      totalLoggedDays: entries.length,
      levelCounts: counts,
    );
  }

  /// Count entries by level for a single month of [mode].
  Map<TrackedLevel, int> monthLevelCounts(
    Map<String, DayEntry> monthEntries,
    ModeDefinition mode,
  ) {
    final counts = {for (final level in mode.levels) level: 0};
    for (final entry in monthEntries.values) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }
}

/// Clean vs. non-clean counts for one calendar month.
class MonthlyTotals {
  const MonthlyTotals({
    required this.month,
    required this.cleanDays,
    required this.otherDays,
  });

  final DateTime month;
  final int cleanDays;
  final int otherDays;

  int get loggedDays => cleanDays + otherDays;
}

extension MonthlyAggregation on StatsService {
  /// Clean / non-clean totals for the [count] most recent months ending with
  /// the month containing [now]. Always returns [count] entries (zero-filled)
  /// so charts have a stable x-axis.
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
      final clean = entry.level.isClean ? 1 : 0;
      buckets[key] = MonthlyTotals(
        month: DateTime(entry.date.year, entry.date.month),
        cleanDays: (existing?.cleanDays ?? 0) + clean,
        otherDays: (existing?.otherDays ?? 0) + (1 - clean),
      );
    }

    final result = <MonthlyTotals>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(reference.year, reference.month - i);
      final key = '${m.year}-${m.month}';
      result.add(
        buckets[key] ?? MonthlyTotals(month: m, cleanDays: 0, otherDays: 0),
      );
    }
    return result;
  }
}
