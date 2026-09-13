import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/l10n/content/content_strings.dart';
import 'package:dont_drink/l10n/content/mode_localizer.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter/foundation.dart';

/// Which activation rule was violated. The wording lives in the .arb files —
/// this view model has no business choosing the user's language.
enum ModeRule {
  /// The active mode cannot be switched off; move somewhere else first.
  switchBeforeDisabling,

  /// The last enabled mode cannot be switched off either.
  keepOneEnabled,
}

/// Raised when an activation rule is violated.
class ModeRuleError implements Exception {
  const ModeRuleError(this.rule);
  final ModeRule rule;

  @override
  String toString() => 'ModeRuleError(${rule.name})';
}

/// Owns which tracking modes exist, which are enabled, and which one the app
/// is currently showing.
///
/// It also caches a current streak per enabled mode, because the switcher and
/// the settings list show streaks for modes that [TrackerViewModel] — which is
/// scoped to exactly one mode — knows nothing about.
class ModeViewModel extends ChangeNotifier {
  ModeViewModel({
    required ModeRepository repository,
    required EntryRepository entries,
    required this.onActiveModeChanged,
    StatsService stats = const StatsService(),
  })  : _repo = repository,
        _entries = entries,
        _stats = stats;

  final ModeRepository _repo;
  final EntryRepository _entries;
  final StatsService _stats;

  /// The language every mode's content is presented in. Mode ids and level
  /// values are untouched by it — only the copy changes.
  ContentStrings _strings = ContentStrings.english;

  /// Switch the language of every mode this view model hands out.
  void setContentStrings(ContentStrings strings) {
    if (strings.languageCode == _strings.languageCode) return;
    _strings = strings;
    _all = [for (final mode in _all) mode.localized(strings)];
    _active = _active?.localized(strings);
    notifyListeners();
  }

  /// Called whenever the active mode changes, so the tracker can reload.
  final Future<void> Function(ModeDefinition mode) onActiveModeChanged;

  List<ModeDefinition> _all = const [];
  List<ModeDefinition> get allAvailableModes => List.unmodifiable(_all);

  List<String> _enabledIds = const [];
  List<ModeDefinition> get enabledModes =>
      [for (final id in _enabledIds) _byId(id)].nonNulls.toList();

  ModeDefinition? _active;
  ModeDefinition get activeMode => _active ?? _all.first;

  final Map<String, int> _streaks = {};

  /// Current streak for [modeId], or 0 if it has not been computed.
  int streakFor(String modeId) => _streaks[modeId] ?? 0;

  ModeDefinition? _byId(String id) {
    for (final mode in _all) {
      if (mode.id == id) return mode;
    }
    return null;
  }

  Future<void> load() async {
    _all = [
      for (final mode in await _repo.allModes()) mode.localized(_strings),
    ];
    _enabledIds = await _repo.enabledModeIds();
    _active = (await _repo.resolveActiveMode()).localized(_strings);
    await refreshStreaks(); // ends in its own notifyListeners()
  }

  /// How far back a current streak is read.
  ///
  /// A current streak ends today, so only the run leading up to today can
  /// matter. Reading everything meant every logged day re-parsed the entire
  /// history of every enabled mode — three modes and three years is thousands
  /// of rows for a number that can only be as long as this window. Five years
  /// is far beyond any plausible unbroken run and still a bounded query.
  static const int _streakWindowDays = 1826;

  /// Recompute the cached streak for every enabled mode.
  Future<void> refreshStreaks() async {
    final since =
        DateTime.now().subtract(const Duration(days: _streakWindowDays));
    for (final mode in enabledModes) {
      final rows = await _entries.getSince(mode, since);
      _streaks[mode.id] = _stats.currentStreak(rows);
    }
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    final mode = _byId(id);
    if (mode == null || mode.id == _active?.id) return;
    _active = mode;
    // Persist and switch the tracker over before announcing the change, so
    // any listener that reads activeMode alongside the tracker never sees
    // the new mode name paired with the old mode's still-loaded data.
    await _repo.setActiveModeId(id);
    await onActiveModeChanged(mode);
    notifyListeners();
  }

  /// Enable or disable a mode.
  ///
  /// Disabling is refused for the active mode and for the last enabled mode —
  /// the switcher must always have somewhere to land.
  Future<void> setEnabled(String id, bool enabled) async {
    if (!enabled) {
      if (id == activeMode.id) {
        throw const ModeRuleError(ModeRule.switchBeforeDisabling);
      }
      if (_enabledIds.length <= 1) {
        throw const ModeRuleError(ModeRule.keepOneEnabled);
      }
      _enabledIds = _enabledIds.where((e) => e != id).toList();
    } else if (!_enabledIds.contains(id)) {
      _enabledIds = [..._enabledIds, id];
    } else {
      return;
    }
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks(); // ends in its own notifyListeners()
  }

  Future<ModeDefinition> createCustom(String name, String emoji) async {
    final mode = await _repo.createCustom(name: name, emoji: emoji);
    _all = await _repo.allModes();
    _enabledIds = [..._enabledIds, mode.id];
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks(); // ends in its own notifyListeners()
    return mode;
  }

  Future<void> updateCustom(String id, String name, String emoji) async {
    await _repo.updateCustom(id, name: name, emoji: emoji);
    _all = await _repo.allModes();
    if (_active?.id == id) {
      _active = _byId(id);
      await onActiveModeChanged(activeMode);
    }
    notifyListeners();
  }

  /// Delete a custom mode and everything it logged. If it was active, fall
  /// back to the first remaining enabled mode.
  Future<void> deleteCustom(String id) async {
    final wasActive = _active?.id == id;
    await _repo.deleteCustom(id);
    _all = await _repo.allModes();
    _enabledIds = await _repo.enabledModeIds();
    if (wasActive) {
      _active = await _repo.resolveActiveMode();
      await onActiveModeChanged(activeMode);
    }
    _streaks.remove(id);
    await refreshStreaks(); // ends in its own notifyListeners()
  }

  /// How many days [modeId] has logged — shown in the delete confirmation.
  Future<int> loggedDayCount(String modeId) async {
    final mode = _byId(modeId);
    if (mode == null) return 0;
    return (await _entries.getAll(mode)).length;
  }
}
