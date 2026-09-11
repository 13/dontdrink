import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/database/app_database.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/static/modes/custom_mode.dart';
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Owns which modes exist, which are enabled, and which one is active.
///
/// Built-in modes are `const` in code; only user-created custom modes are
/// stored in the `modes` table. Enabled/active selection lives in
/// [SharedPreferences] alongside the other lightweight preferences.
class ModeRepository {
  ModeRepository({AppDatabase? db, EntryRepository? entries})
      : _appDb = db ?? AppDatabase.instance,
        _entries = entries ?? EntryRepository();

  static const _kEnabledModeIds = 'enabled_mode_ids';
  static const _kActiveModeId = 'active_mode_id';

  final AppDatabase _appDb;
  final EntryRepository _entries;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── Custom modes ─────────────────────────────────────────────────────────

  Future<List<ModeDefinition>> customModes() async {
    final db = await _appDb.database;
    final rows = await db.query(AppDatabase.tableModes, orderBy: 'created_at ASC');
    return [
      for (final row in rows)
        customModeFrom(
          id: row['id'] as String,
          name: row['name'] as String,
          emoji: row['emoji'] as String,
        ),
    ];
  }

  /// Built-in modes first, then custom modes oldest-first.
  Future<List<ModeDefinition>> allModes() async {
    return [...kBuiltInModes, ...await customModes()];
  }

  Future<ModeDefinition> createCustom({
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'custom_$now';
    await db.insert(
      AppDatabase.tableModes,
      {'id': id, 'name': name, 'emoji': emoji, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customModeFrom(id: id, name: name, emoji: emoji);
  }

  /// Recreate a custom mode with its original id — used when importing a
  /// backup, where entries already reference that id.
  Future<ModeDefinition> restoreCustom({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    await db.insert(
      AppDatabase.tableModes,
      {
        'id': id,
        'name': name,
        'emoji': emoji,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customModeFrom(id: id, name: name, emoji: emoji);
  }

  Future<void> updateCustom(
    String id, {
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    await db.update(
      AppDatabase.tableModes,
      {'name': name, 'emoji': emoji},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a custom mode along with every day it logged, and drop it from the
  /// enabled list so nothing points at a mode that no longer exists.
  Future<void> deleteCustom(String id) async {
    final db = await _appDb.database;
    await db.delete(AppDatabase.tableModes, where: 'id = ?', whereArgs: [id]);
    await _entries.deleteAllForMode(id);

    final enabled = await enabledModeIds();
    if (enabled.contains(id)) {
      final remaining = enabled.where((e) => e != id).toList();
      await setEnabledModeIds(
          remaining.isEmpty ? [kDefaultMode.id] : remaining);
    }
    if (await activeModeId() == id) {
      await setActiveModeId((await enabledModeIds()).first);
    }
  }

  // ── Selection ────────────────────────────────────────────────────────────

  Future<List<String>> enabledModeIds() async {
    final prefs = await _p;
    final stored = prefs.getStringList(_kEnabledModeIds);
    if (stored == null || stored.isEmpty) return [kDefaultMode.id];
    return stored;
  }

  Future<void> setEnabledModeIds(List<String> ids) async {
    final prefs = await _p;
    await prefs.setStringList(_kEnabledModeIds, ids);
  }

  Future<String> activeModeId() async {
    final prefs = await _p;
    return prefs.getString(_kActiveModeId) ?? kDefaultMode.id;
  }

  Future<void> setActiveModeId(String id) async {
    final prefs = await _p;
    await prefs.setString(_kActiveModeId, id);
  }

  /// The mode the app should open in. Falls back to [kDefaultMode] when the
  /// stored id names a custom mode that has since been deleted.
  Future<ModeDefinition> resolveActiveMode() async {
    final id = await activeModeId();
    final builtIn = builtInModeById(id);
    if (builtIn != null) return builtIn;
    for (final mode in await customModes()) {
      if (mode.id == id) return mode;
    }
    return kDefaultMode;
  }
}
