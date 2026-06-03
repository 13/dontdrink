import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/drink_level.dart';
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

  /// Insert or update the entry for its day. One entry per date is enforced by
  /// the `date_key` primary key + replace conflict strategy.
  Future<void> upsert(DayEntry entry) async {
    final db = await _appDb.database;
    await db.insert(
      AppDatabase.tableEntries,
      entry.copyWith(updatedAt: DateTime.now()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove the entry for [date], if any (clears the day).
  Future<void> delete(DateTime date) async {
    final db = await _appDb.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'date_key = ?',
      whereArgs: [DateOnly.keyFor(date)],
    );
  }

  /// The entry for [date], or null if the day has not been logged.
  Future<DayEntry?> getForDate(DateTime date) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'date_key = ?',
      whereArgs: [DateOnly.keyFor(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first);
  }

  /// All entries, ordered oldest-first.
  Future<List<DayEntry>> getAll() async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      orderBy: 'date_key ASC',
    );
    return rows.map(DayEntry.fromMap).toList();
  }

  /// All entries within the inclusive [start]–[end] range, keyed by date.
  Future<Map<String, DayEntry>> getRange(DateTime start, DateTime end) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'date_key BETWEEN ? AND ?',
      whereArgs: [DateOnly.keyFor(start), DateOnly.keyFor(end)],
    );
    return {
      for (final row in rows)
        row['date_key'] as String: DayEntry.fromMap(row),
    };
  }

  /// All entries for the month containing [month], keyed by date.
  Future<Map<String, DayEntry>> getMonth(DateTime month) {
    return getRange(DateOnly.firstOfMonth(month), DateOnly.lastOfMonth(month));
  }

  /// Count of entries grouped by drink level across the whole history.
  Future<Map<DrinkLevel, int>> levelCounts() async {
    final entries = await getAll();
    final counts = {for (final level in DrinkLevel.values) level: 0};
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }
}
