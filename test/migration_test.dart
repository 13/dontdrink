import 'dart:io';

import 'package:dont_drink/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dontdrink_migration');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// A fresh on-disk path. An in-memory database would be destroyed the moment
  /// the v1 connection closes, so the migration would have nothing to migrate.
  String newDbPath() => p.join(tempDir.path, 'test_${DateTime.now().microsecondsSinceEpoch}.db');

  /// Build a database with the exact v1 schema the app shipped with.
  Future<Database> openV1(String path) async {
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE day_entries (
              date_key   TEXT PRIMARY KEY,
              level      INTEGER NOT NULL,
              note       TEXT,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  test('v1 rows are assigned to dont_drink and keep their values', () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 0,
      'note': 'felt good',
      'updated_at': 1750000000000,
    });
    await v1.insert('day_entries', {
      'date_key': '2026-06-02',
      'level': 3,
      'note': null,
      'updated_at': 1750000100000,
    });
    await v1.close();

    final v2 = await AppDatabase.openAt(path);
    final rows = await v2.query('day_entries', orderBy: 'date_key ASC');

    expect(rows.length, 2);
    expect(rows[0]['mode_id'], 'dont_drink');
    expect(rows[0]['date_key'], '2026-06-01');
    expect(rows[0]['level'], 0);
    expect(rows[0]['note'], 'felt good');
    expect(rows[0]['updated_at'], 1750000000000);
    expect(rows[1]['mode_id'], 'dont_drink');
    expect(rows[1]['level'], 3);
    expect(rows[1]['note'], null);
    expect(rows[1]['updated_at'], 1750000100000);
    await v2.close();
  });

  test('after migration the primary key is (mode_id, date_key)', () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 0,
      'note': null,
      'updated_at': 1750000000000,
    });
    await v1.close();

    final v2 = await AppDatabase.openAt(path);

    // The same date in another mode must coexist, not replace.
    await v2.insert('day_entries', {
      'mode_id': 'dont_smoke',
      'date_key': '2026-06-01',
      'level': 2,
      'note': null,
      'updated_at': 1750000200000,
    });
    final all = await v2.query('day_entries');
    expect(all.length, 2);

    // The same (mode, date) must still collide.
    await v2.insert(
      'day_entries',
      {
        'mode_id': 'dont_smoke',
        'date_key': '2026-06-01',
        'level': 4,
        'note': null,
        'updated_at': 1750000300000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final after = await v2.query('day_entries');
    expect(after.length, 2);
    expect(
      after.firstWhere((r) => r['mode_id'] == 'dont_smoke')['level'],
      4,
    );
    await v2.close();
  });

  test('the modes table exists after migration', () async {
    final path = newDbPath();
    final v1 = await openV1(path);
    await v1.close();

    final v2 = await AppDatabase.openAt(path);
    await v2.insert('modes', {
      'id': 'custom_1',
      'name': 'My Mode',
      'emoji': '🎯',
      'created_at': 1750000000000,
    });
    expect((await v2.query('modes')).length, 1);
    await v2.close();
  });

  test('a fresh install creates both tables at v2', () async {
    final db = await AppDatabase.openAt(newDbPath());
    expect(await db.getVersion(), 2);
    await db.insert('day_entries', {
      'mode_id': 'dont_drink',
      'date_key': '2026-06-01',
      'level': 0,
      'note': null,
      'updated_at': 1750000000000,
    });
    expect((await db.query('day_entries')).length, 1);
    expect((await db.query('modes')).length, 0);
    await db.close();
  });

  test('opening an already-migrated v2 file a second time is a no-op',
      () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 1,
      'note': 'first migration',
      'updated_at': 1750000000000,
    });
    await v1.close();

    // First migration.
    final firstOpen = await AppDatabase.openAt(path);
    await firstOpen.close();

    // Reopen the already-v2 file.
    final secondOpen = await AppDatabase.openAt(path);
    expect(await secondOpen.getVersion(), 2);

    final rows = await secondOpen.query('day_entries');
    expect(rows.length, 1);
    expect(rows.first['mode_id'], 'dont_drink');
    expect(rows.first['note'], 'first migration');

    // No leftover rebuild table from a second, no-op migration attempt.
    final tables = await secondOpen.query(
      'sqlite_master',
      where: "type = 'table' AND name = ?",
      whereArgs: ['day_entries_new'],
    );
    expect(tables, isEmpty);

    await secondOpen.close();
  });

  test(
      'a downgrade to v1 and re-upgrade does not crash and does not '
      'collapse mode_id', () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 0,
      'note': 'original',
      'updated_at': 1750000000000,
    });
    await v1.close();

    // Migrate to v2, then add a row in a non-default mode.
    final v2 = await AppDatabase.openAt(path);
    await v2.insert('day_entries', {
      'mode_id': 'dont_smoke',
      'date_key': '2026-06-02',
      'level': 2,
      'note': null,
      'updated_at': 1750000200000,
    });
    await v2.close();

    // Simulate an older build (or a device restore) writing the stored
    // version back down without touching the (still v2-shaped) tables.
    final raw = await databaseFactory.openDatabase(path);
    await raw.execute('PRAGMA user_version = 1');
    await raw.close();

    // Reopening must migrate cleanly rather than throwing "table modes
    // already exists", and must not re-rebuild day_entries (which would
    // rewrite every row's mode_id to 'dont_drink' and collapse rows on the
    // primary key).
    final reopened = await AppDatabase.openAt(path);
    expect(await reopened.getVersion(), 2);

    final rows = await reopened.query('day_entries', orderBy: 'date_key ASC');
    expect(rows.length, 2);
    expect(rows[0]['mode_id'], 'dont_drink');
    expect(rows[0]['note'], 'original');
    expect(rows[1]['mode_id'], 'dont_smoke');
    expect(rows[1]['date_key'], '2026-06-02');

    await reopened.close();
  });

  test('an empty v1 database migrates cleanly to an empty v2 schema',
      () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.close();

    final v2 = await AppDatabase.openAt(path);
    expect(await v2.getVersion(), 2);
    expect((await v2.query('day_entries')).length, 0);
    expect((await v2.query('modes')).length, 0);
    await v2.close();
  });
}
