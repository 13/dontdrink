import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// Read/write access to logged [DayEntry] rows.
///
/// This is the single source of truth for tracker data; view models depend on
/// it rather than touching the database directly (MVVM data layer).
class EntryRepository {
  EntryRepository({AppDatabase? db}) : _appDb = db ?? AppDatabase.instance;

  final AppDatabase _appDb;

  /// Insert or update the entry for its day. One entry per (mode, date) is
  /// enforced by the composite primary key + replace conflict strategy.
  Future<void> upsert(DayEntry entry) async {
    final db = await _appDb.database;
    await db.insert(
      AppDatabase.tableEntries,
      entry.copyWith(updatedAt: DateTime.now()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove the entry for [date] in [modeId], if any (clears the day).
  Future<void> delete(String modeId, DateTime date) async {
    final db = await _appDb.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key = ?',
      whereArgs: [modeId, DateOnly.keyFor(date)],
    );
  }

  /// The entry for [date] in [mode], or null if the day has not been logged.
  Future<DayEntry?> getForDate(ModeDefinition mode, DateTime date) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key = ?',
      whereArgs: [mode.id, DateOnly.keyFor(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first, mode);
  }

  /// All entries for [mode], ordered oldest-first.
  Future<List<DayEntry>> getAll(ModeDefinition mode) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ?',
      whereArgs: [mode.id],
      orderBy: 'date_key ASC',
    );
    return [for (final row in rows) DayEntry.fromMap(row, mode)];
  }

  /// All entries for [mode] within the inclusive [start]–[end] range, keyed
  /// by date.
  Future<Map<String, DayEntry>> getRange(
      ModeDefinition mode, DateTime start, DateTime end) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key BETWEEN ? AND ?',
      whereArgs: [mode.id, DateOnly.keyFor(start), DateOnly.keyFor(end)],
    );
    return {
      for (final row in rows)
        row['date_key'] as String: DayEntry.fromMap(row, mode),
    };
  }

  /// All entries for [mode] in the month containing [month], keyed by date.
  Future<Map<String, DayEntry>> getMonth(ModeDefinition mode, DateTime month) {
    return getRange(
        mode, DateOnly.firstOfMonth(month), DateOnly.lastOfMonth(month));
  }

  /// Entries from [since] onwards, oldest first.
  ///
  /// Exists for the streak cache: a current streak can only be as long as the
  /// run ending today, so there is no reason to read a decade of history to
  /// compute it.
  Future<List<DayEntry>> getSince(ModeDefinition mode, DateTime since) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key >= ?',
      whereArgs: [mode.id, DateOnly.keyFor(since)],
      orderBy: 'date_key ASC',
    );
    return [for (final row in rows) DayEntry.fromMap(row, mode)];
  }

  /// Count of entries grouped by level across [mode]'s whole history.
  Future<Map<TrackedLevel, int>> levelCounts(ModeDefinition mode) async {
    final entries = await getAll(mode);
    final counts = {for (final level in mode.levels) level: 0};
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }

  /// Delete every entry belonging to [modeId]. Used when a custom mode is
  /// deleted.
  Future<void> deleteAllForMode(String modeId) async {
    final db = await _appDb.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'mode_id = ?',
      whereArgs: [modeId],
    );
  }
}
