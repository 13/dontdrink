import 'dart:io';

import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/services/export_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDbDir =
        Directory.systemTemp.createTempSync('dontdrink_export_import');
    await databaseFactory.setDatabasesPath(tempDbDir.path);
  });

  tearDownAll(() {
    if (tempDbDir.existsSync()) tempDbDir.deleteSync(recursive: true);
  });

  const service = ExportImportService();
  late EntryRepository entries;
  late ModeRepository modes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entries = EntryRepository();
    modes = ModeRepository(entries: entries);
    for (final id in ['dont_drink', 'dont_smoke']) {
      await entries.deleteAllForMode(id);
    }
    for (final m in await modes.customModes()) {
      await modes.deleteCustom(m.id);
    }
  });

  test('buildPayload is version 2 and carries mode ids', () {
    final payload = service.buildPayload(
      modes: const [],
      entriesByMode: {
        'dont_drink': [
          DayEntry(
            modeId: 'dont_drink',
            date: DateTime(2026, 6, 1),
            level: kDontDrinkLevels[0],
          ),
        ],
        'dont_smoke': [
          DayEntry(
            modeId: 'dont_smoke',
            date: DateTime(2026, 6, 1),
            level: kDontSmokeLevels[2],
          ),
        ],
      },
    );

    expect(payload['version'], 2);
    expect(payload['app'], 'dont_drink');
    final rows = payload['entries'] as List;
    expect(rows.length, 2);
    expect(rows.map((r) => (r as Map)['mode_id']).toSet(),
        {'dont_drink', 'dont_smoke'});
  });

  test('buildPayload includes custom mode definitions', () async {
    final custom = await modes.createCustom(name: 'No Sugar', emoji: '🍭');
    final payload = service.buildPayload(
      modes: [custom],
      entriesByMode: const {},
    );
    final defs = payload['custom_modes'] as List;
    expect(defs.length, 1);
    expect((defs.first as Map)['name'], 'No Sugar');
    expect((defs.first as Map)['id'], custom.id);
  });

  test('a version 1 payload imports into Don\'t Drink', () async {
    final result = await service.applyPayload(
      {
        'version': 1,
        'app': 'dont_drink',
        'entries': [
          {
            'date_key': '2026-06-01',
            'level': 0,
            'note': 'legacy',
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    final stored = await entries.getAll(kDontDrinkMode);
    expect(stored.length, 1);
    expect(stored.single.modeId, 'dont_drink');
    expect(stored.single.note, 'legacy');
  });

  test('a version 2 payload restores several modes', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': const [],
        'entries': [
          {
            'mode_id': 'dont_drink',
            'date_key': '2026-06-01',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
          {
            'mode_id': 'dont_smoke',
            'date_key': '2026-06-01',
            'level': 2,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    expect((await entries.getAll(kDontDrinkMode)).length, 1);
    final smoke = await entries.getAll(kDontSmokeMode);
    expect(smoke.single.level.label, '6–15 Cigarettes');
  });

  test('importing recreates a custom mode and its entries', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': [
          {'id': 'custom_9', 'name': 'No Sugar', 'emoji': '🍭'},
        ],
        'entries': [
          {
            'mode_id': 'custom_9',
            'date_key': '2026-06-01',
            'level': 1,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    final restored = (await modes.customModes()).single;
    expect(restored.id, 'custom_9');
    expect(restored.name, 'No Sugar');
    expect((await entries.getAll(restored)).single.level.shortLabel, 'Slip');
  });

  test('a payload from another app is rejected', () async {
    final result = await service.applyPayload(
      {'version': 2, 'app': 'something_else', 'entries': const []},
      entries: entries,
      modes: modes,
    );
    expect(result, isA<ImportError>());
  });

  test('entries for an unknown mode are skipped, not fatal', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': const [],
        'entries': [
          {
            'mode_id': 'custom_gone',
            'date_key': '2026-06-01',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
          {
            'mode_id': 'dont_drink',
            'date_key': '2026-06-02',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect((result as ImportSuccess).count, 1);
    expect((await entries.getAll(kDontDrinkMode)).length, 1);
  });
}
