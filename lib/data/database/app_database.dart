import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema. Local-only; nothing leaves the device.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'dont_drink.db';
  static const int _dbVersion = 1;

  /// Table holding one row per logged calendar day.
  static const String tableEntries = 'day_entries';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEntries (
        date_key   TEXT PRIMARY KEY,
        level      INTEGER NOT NULL,
        note       TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Test/maintenance helper: closes the underlying connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
