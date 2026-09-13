import 'dart:convert';
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

  test(
      'a payload with no version key at all is treated as v1 — the '
      'pre-release backup case', () async {
    // Real pre-release backups never had a `version` key at all (it was
    // added alongside multi-mode support), so this pins the fallback
    // separately from the explicit `'version': 1` case above.
    final result = await service.applyPayload(
      {
        'app': 'dont_drink',
        'entries': [
          {
            'date_key': '2026-06-01',
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
    final stored = await entries.getAll(kDontDrinkMode);
    expect(stored.single.modeId, 'dont_drink');
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

  test(
      'a v2 entry missing mode_id is skipped, not defaulted into '
      "Don't Drink", () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': const [],
        'entries': [
          {
            'date_key': '2026-06-03',
            'level': 3,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect((result as ImportSuccess).count, 0);
    expect(result.skipped, 1);
    expect(await entries.getAll(kDontDrinkMode), isEmpty);
  });

  test('a payload missing the entries key is rejected', () async {
    final result = await service.applyPayload(
      {'version': 2, 'app': 'dont_drink'},
      entries: entries,
      modes: modes,
    );
    expect(result, isA<ImportError>());
  });

  test('a payload whose entries is not a list is rejected', () async {
    final result = await service.applyPayload(
      {'version': 2, 'app': 'dont_drink', 'entries': 'not a list'},
      entries: entries,
      modes: modes,
    );
    expect(result, isA<ImportError>());
  });

  test(
      'a malformed entry row is skipped and the rows after it still import',
      () async {
    // The bad row (non-int level) sits between two good ones, so this also
    // pins that a malformed row does not abort the rest of the file.
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
            'mode_id': 'dont_drink',
            'date_key': '2026-06-02',
            'level': 'not-a-number',
            'note': null,
            'updated_at': 1750000000000,
          },
          {
            'mode_id': 'dont_drink',
            'date_key': '2026-06-03',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect((result as ImportSuccess).count, 2);
    expect(result.skipped, 1);
    expect((await entries.getAll(kDontDrinkMode)).length, 2);
  });

  test(
      'a custom_modes entry with a non-string id is skipped, not thrown',
      () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': [
          {'id': 9, 'name': 'Bad Id'},
        ],
        'entries': const [],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    expect(await modes.customModes(), isEmpty);
  });

  test(
      'buildPayload -> jsonEncode -> jsonDecode -> applyPayload round-trips '
      'entries across built-in and custom modes', () async {
    final custom = await modes.createCustom(name: 'No Sugar', emoji: '🍭');
    final entryDrink = DayEntry(
      modeId: 'dont_drink',
      date: DateTime(2026, 6, 1),
      level: kDontDrinkLevels[2],
      note: 'party night',
    );
    final entrySmoke = DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 2),
      level: kDontSmokeLevels[1],
    );
    final entryCustom = DayEntry(
      modeId: custom.id,
      date: DateTime(2026, 6, 3),
      level: custom.levels[1],
      note: 'slipped',
    );

    final payload = service.buildPayload(
      modes: [custom],
      entriesByMode: {
        'dont_drink': [entryDrink],
        'dont_smoke': [entrySmoke],
        custom.id: [entryCustom],
      },
    );

    // Round-trip through real JSON encode/decode — the path a real backup
    // file actually takes, and the one most likely to surface a type
    // surprise that a hand-built Dart map would never hit.
    final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

    // Wipe everything first, so the restored rows below can only have come
    // from the import, not leftover state.
    for (final id in ['dont_drink', 'dont_smoke']) {
      await entries.deleteAllForMode(id);
    }
    for (final m in await modes.customModes()) {
      await modes.deleteCustom(m.id);
    }

    final result =
        await service.applyPayload(decoded, entries: entries, modes: modes);
    expect(result, isA<ImportSuccess>());
    expect((result as ImportSuccess).count, 3);
    expect(result.skipped, 0);

    final restoredDrink = (await entries.getAll(kDontDrinkMode)).single;
    expect(restoredDrink.level.value, entryDrink.level.value);
    expect(restoredDrink.note, 'party night');
    expect(restoredDrink.dateKey, entryDrink.dateKey);

    final restoredSmoke = (await entries.getAll(kDontSmokeMode)).single;
    expect(restoredSmoke.level.value, entrySmoke.level.value);
    expect(restoredSmoke.dateKey, entrySmoke.dateKey);

    final restoredCustomMode = (await modes.customModes()).single;
    expect(restoredCustomMode.id, custom.id);
    expect(restoredCustomMode.name, 'No Sugar');
    final restoredCustomEntry =
        (await entries.getAll(restoredCustomMode)).single;
    expect(restoredCustomEntry.level.value, entryCustom.level.value);
    expect(restoredCustomEntry.note, 'slipped');
  });

  test('a note survives an export and import round trip', () async {
    const service = ExportImportService();
    final entries = EntryRepository();
    final modes = ModeRepository(entries: entries);
    await entries.deleteAllForMode('dont_drink');

    final day = DateTime(2026, 5, 17);
    await entries.upsert(DayEntry(
      modeId: 'dont_drink',
      date: day,
      level: kDontDrinkLevels[3],
      note: 'Wedding — one too many, slept badly.',
    ));

    final payload = service.buildPayload(
      modes: [kDontDrinkMode],
      entriesByMode: {'dont_drink': await entries.getAll(kDontDrinkMode)},
    );

    // Wipe, then restore from the payload exactly as the importer would.
    await entries.deleteAllForMode('dont_drink');
    expect(await entries.getAll(kDontDrinkMode), isEmpty);

    final result =
        await service.applyPayload(payload, entries: entries, modes: modes);
    expect(result, isA<ImportSuccess>());

    final restored = await entries.getForDate(kDontDrinkMode, day);
    expect(restored?.note, 'Wedding — one too many, slept badly.',
        reason: 'free text is the one thing a user could not reconstruct');
    expect(restored?.level.value, kDontDrinkLevels[3].value);
  });
}
