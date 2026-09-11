import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter/foundation.dart';

/// Raised when an activation rule is violated. [message] is written for the
/// user and can be shown directly in a snackbar.
class ModeRuleError implements Exception {
  const ModeRuleError(this.message);
  final String message;

  @override
  String toString() => message;
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
    _all = await _repo.allModes();
    _enabledIds = await _repo.enabledModeIds();
    _active = await _repo.resolveActiveMode();
    await refreshStreaks();
    notifyListeners();
  }

  /// Recompute the cached streak for every enabled mode. Cheap: at most one
  /// row per day per mode.
  Future<void> refreshStreaks() async {
    for (final mode in enabledModes) {
      final rows = await _entries.getAll(mode);
      _streaks[mode.id] = _stats.currentStreak(rows);
    }
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    final mode = _byId(id);
    if (mode == null || mode.id == _active?.id) return;
    _active = mode;
    notifyListeners();
    await _repo.setActiveModeId(id);
    await onActiveModeChanged(mode);
  }

  /// Enable or disable a mode.
  ///
  /// Disabling is refused for the active mode and for the last enabled mode —
  /// the switcher must always have somewhere to land.
  Future<void> setEnabled(String id, bool enabled) async {
    if (!enabled) {
      if (id == activeMode.id) {
        throw const ModeRuleError(
            'Switch to another mode before turning this one off.');
      }
      if (_enabledIds.length <= 1) {
        throw const ModeRuleError('At least one mode has to stay on.');
      }
      _enabledIds = _enabledIds.where((e) => e != id).toList();
    } else if (!_enabledIds.contains(id)) {
      _enabledIds = [..._enabledIds, id];
    } else {
      return;
    }
    notifyListeners();
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks();
  }

  Future<ModeDefinition> createCustom(String name, String emoji) async {
    final mode = await _repo.createCustom(name: name, emoji: emoji);
    _all = await _repo.allModes();
    _enabledIds = [..._enabledIds, mode.id];
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks();
    notifyListeners();
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
    await refreshStreaks();
    notifyListeners();
  }

  /// How many days [modeId] has logged — shown in the delete confirmation.
  Future<int> loggedDayCount(String modeId) async {
    final mode = _byId(modeId);
    if (mode == null) return 0;
    return (await _entries.getAll(mode)).length;
  }
}
