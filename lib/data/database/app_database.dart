import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema. Local-only; nothing leaves the device.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'dont_drink.db';
  static const int _dbVersion = 2;

  /// Table holding one row per logged calendar day, per mode.
  static const String tableEntries = 'day_entries';

  /// Table holding user-created custom modes. Built-in modes are const in
  /// code and never appear here.
  static const String tableModes = 'modes';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openAt(p.join(dir, _dbName));
  }

  /// Open (and migrate) the database at [path]. Exposed so tests can drive the
  /// real schema and migration against a temporary file.
  static Future<Database> openAt(String path) {
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createEntriesSql(tableEntries));
    await db.execute(_createModesSql);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  /// v1 → v2: every existing row belongs to Don't Drink, and the primary key
  /// becomes (mode_id, date_key).
  ///
  /// SQLite cannot add a primary key with ALTER TABLE, so the table is rebuilt.
  /// The whole rebuild runs in one transaction: either the user ends up on v2
  /// with all their data, or nothing changes.
  ///
  /// No `onDowngrade` is supplied, so sqflite's open path can write
  /// `user_version` back down (e.g. a sideloaded older build, or a device
  /// restore pairing a newer DB file with an older app) while leaving the
  /// tables untouched — the next open then sees `oldVersion == 1` against an
  /// already-v2 schema. Downgrade safety is therefore handled by making this
  /// upgrade idempotent: it inspects the actual table shape rather than
  /// trusting the stored version, so running it again on an already-migrated
  /// database is a no-op instead of a crash or, worse, a silent
  /// mode_id-collapsing re-rebuild.
  static Future<void> _migrateToV2(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableEntries)');
    final alreadyV2 = columns.any((c) => c['name'] == 'mode_id');

    await db.transaction((txn) async {
      if (!alreadyV2) {
        await txn.execute(_createEntriesSql('${tableEntries}_new'));
        await txn.execute('''
          INSERT INTO ${tableEntries}_new (mode_id, date_key, level, note, updated_at)
          SELECT 'dont_drink', date_key, level, note, updated_at FROM $tableEntries
        ''');
        await txn.execute('DROP TABLE $tableEntries');
        await txn.execute(
            'ALTER TABLE ${tableEntries}_new RENAME TO $tableEntries');
      }
      await txn.execute(
          _createModesSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    });
  }

  static String _createEntriesSql(String table) => '''
      CREATE TABLE $table (
        mode_id    TEXT NOT NULL,
        date_key   TEXT NOT NULL,
        level      INTEGER NOT NULL,
        note       TEXT,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (mode_id, date_key)
      )
    ''';

  static const String _createModesSql = '''
      CREATE TABLE $tableModes (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        emoji      TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''';

  /// Test/maintenance helper: closes the underlying connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
