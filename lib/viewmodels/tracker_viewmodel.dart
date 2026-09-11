import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter/foundation.dart';

/// The central MVVM view model for tracker data.
///
/// Holds the full entry history in memory (the dataset is tiny — at most one
/// row per day) and derives streaks, statistics and achievements from it. UI
/// screens listen to this and call [logDay] / [clearDay] to mutate state.
class TrackerViewModel extends ChangeNotifier {
  TrackerViewModel({
    required EntryRepository repository,
    required ModeDefinition mode,
    StatsService stats = const StatsService(),
    AchievementService achievements = const AchievementService(),
  })  : _repo = repository,
        _mode = mode,
        _stats = stats,
        _achievements = achievements;

  final EntryRepository _repo;
  ModeDefinition _mode;
  final StatsService _stats;
  final AchievementService _achievements;

  /// The tracking mode this view model is scoped to.
  ModeDefinition get mode => _mode;

  /// Called after any change to this mode's entries, so [ModeViewModel] can
  /// refresh its cached per-mode streaks.
  VoidCallback? onDataChanged;

  /// Point this view model at a different mode and reload its history.
  Future<void> switchMode(ModeDefinition mode) async {
    if (mode.id == _mode.id) {
      _mode = mode; // a rename of the same mode
      notifyListeners();
      return;
    }
    _mode = mode;
    _visibleMonth = DateOnly.firstOfMonth(DateTime.now());
    _pendingUnlocks = const [];
    await load();
  }

  bool _loading = true;
  bool get isLoading => _loading;

  /// All entries keyed by `yyyy-MM-dd`.
  final Map<String, DayEntry> _entries = {};

  TrackerStats _statsCache = TrackerStats.empty;
  TrackerStats get stats => _statsCache;

  /// Achievements newly unlocked by the last [logDay] call. The UI reads and
  /// then clears this to drive unlock animations.
  List<Achievement> _pendingUnlocks = const [];
  List<Achievement> get pendingUnlocks => _pendingUnlocks;

  /// The month currently displayed by the calendar.
  DateTime _visibleMonth = DateOnly.firstOfMonth(DateTime.now());
  DateTime get visibleMonth => _visibleMonth;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final all = await _repo.getAll(_mode);
    _entries
      ..clear()
      ..addEntries(all.map((e) => MapEntry(e.dateKey, e)));
    _recompute();
    _loading = false;
    notifyListeners();
  }

  List<DayEntry> get _allEntries => _entries.values.toList();

  /// All entries sorted oldest-first — used by the statistics charts.
  List<DayEntry> get allEntries =>
      _allEntries..sort((a, b) => a.date.compareTo(b.date));

  void _recompute() {
    _statsCache = _stats.compute(_allEntries, _mode);
  }

  /// Entry for [date], or null if unlogged.
  DayEntry? entryFor(DateTime date) => _entries[DateOnly.keyFor(date)];

  /// Entries for the given month, keyed by date — used by the calendar grid.
  Map<String, DayEntry> entriesForMonth(DateTime month) {
    final first = DateOnly.firstOfMonth(month);
    final last = DateOnly.lastOfMonth(month);
    return {
      for (final entry in _entries.entries)
        if (!entry.value.date.isBefore(first) &&
            !entry.value.date.isAfter(last))
          entry.key: entry.value,
    };
  }

  /// Per-level counts for a month.
  Map<TrackedLevel, int> monthCounts(DateTime month) =>
      _stats.monthLevelCounts(entriesForMonth(month), _mode);

  /// Log (or update) the status for [date]. Detects newly unlocked
  /// achievements by comparing the longest streak before and after.
  Future<void> logDay(DateTime date, TrackedLevel level, {String? note}) async {
    final previousLongest = _statsCache.longestStreak;

    final entry = DayEntry(
        modeId: _mode.id,
        date: DateOnly.normalize(date),
        level: level,
        note: note);
    await _repo.upsert(entry);
    _entries[entry.dateKey] = entry;
    _recompute();

    _pendingUnlocks = _achievements.newlyUnlocked(
      achievements: _mode.content.achievements,
      previousLongest: previousLongest,
      newLongest: _statsCache.longestStreak,
    );
    notifyListeners();
    onDataChanged?.call();
  }

  /// Remove the entry for [date].
  Future<void> clearDay(DateTime date) async {
    await _repo.delete(_mode.id, date);
    _entries.remove(DateOnly.keyFor(date));
    _recompute();
    notifyListeners();
    onDataChanged?.call();
  }

  void clearPendingUnlocks() {
    _pendingUnlocks = const [];
  }

  // --- Calendar navigation -------------------------------------------------

  void showMonth(DateTime month) {
    _visibleMonth = DateOnly.firstOfMonth(month);
    notifyListeners();
  }

  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    notifyListeners();
  }

  // --- Derived helpers for the UI -----------------------------------------

  List<AchievementStatus> get achievements => _achievements.evaluate(
        achievements: _mode.content.achievements,
        longestStreak: _statsCache.longestStreak,
      );

  /// The next achievement still to unlock, for the dashboard progress hint.
  Achievement? get nextAchievement => _achievements.nextLocked(
      _mode.content.achievements, _statsCache.longestStreak);
}
