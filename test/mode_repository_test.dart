import 'package:dont_drink/data/database/app_database.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // AppDatabase.instance is a process-wide singleton shared by every test
    // in this file, so custom modes created by one test would otherwise
    // leak into the next. Clear the table each test cares about instead of
    // constructing a second AppDatabase.
    final db = await AppDatabase.instance.database;
    await db.delete(AppDatabase.tableModes);
  });

  test('a fresh install enables and activates Don\'t Drink', () async {
    final repo = ModeRepository();
    expect(await repo.enabledModeIds(), ['dont_drink']);
    expect(await repo.activeModeId(), 'dont_drink');
    expect((await repo.resolveActiveMode()).id, 'dont_drink');
  });

  test('createCustom stores a mode and returns it', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'No Sugar', emoji: '🍭');

    expect(mode.id, startsWith('custom_'));
    expect(mode.name, 'No Sugar');
    expect(mode.emoji, '🍭');
    expect(mode.isBuiltIn, isFalse);
    expect(mode.levels.length, 3);

    final stored = await repo.customModes();
    expect(stored.map((m) => m.id), [mode.id]);
  });

  test('allModes lists built-ins then customs', () async {
    final repo = ModeRepository();
    await repo.createCustom(name: 'No Sugar', emoji: '🍭');
    final all = await repo.allModes();
    expect(all.take(3).map((m) => m.id),
        ['dont_drink', 'dont_smoke', 'no_contact']);
    expect(all.last.name, 'No Sugar');
  });

  test('updateCustom renames without changing the id', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'Old', emoji: '🎯');
    await repo.updateCustom(mode.id, name: 'New', emoji: '🎲');
    final stored = (await repo.customModes()).single;
    expect(stored.id, mode.id);
    expect(stored.name, 'New');
    expect(stored.emoji, '🎲');
  });

  test('deleteCustom removes the mode and drops it from enabled ids', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'Temp', emoji: '🎯');
    await repo.setEnabledModeIds(['dont_drink', mode.id]);

    await repo.deleteCustom(mode.id);

    expect(await repo.customModes(), isEmpty);
    expect(await repo.enabledModeIds(), ['dont_drink']);
  });

  test('resolveActiveMode falls back when the stored id is gone', () async {
    final repo = ModeRepository();
    await repo.setActiveModeId('custom_deleted');
    expect((await repo.resolveActiveMode()).id, 'dont_drink');
  });

  test('enabled and active ids round-trip', () async {
    final repo = ModeRepository();
    await repo.setEnabledModeIds(['dont_drink', 'no_contact']);
    await repo.setActiveModeId('no_contact');
    expect(await repo.enabledModeIds(), ['dont_drink', 'no_contact']);
    expect((await repo.resolveActiveMode()).id, 'no_contact');
  });
}
