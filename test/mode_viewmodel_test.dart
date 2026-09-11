import 'dart:io';

import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/database/app_database.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
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
        Directory.systemTemp.createTempSync('dontdrink_mode_viewmodel');
    await databaseFactory.setDatabasesPath(tempDbDir.path);
  });

  tearDownAll(() {
    if (tempDbDir.existsSync()) tempDbDir.deleteSync(recursive: true);
  });

  late EntryRepository entries;
  late List<String> switched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entries = EntryRepository();
    switched = [];
    for (final id in ['dont_drink', 'dont_smoke', 'no_contact']) {
      await entries.deleteAllForMode(id);
    }
    // Custom modes created by one test otherwise leak into the next, since
    // AppDatabase.instance is a process-wide singleton shared by every test
    // in this file.
    final db = await AppDatabase.instance.database;
    await db.delete(AppDatabase.tableModes);
  });

  Future<ModeViewModel> buildVm() async {
    final vm = ModeViewModel(
      repository: ModeRepository(entries: entries),
      entries: entries,
      onActiveModeChanged: (mode) async => switched.add(mode.id),
    );
    await vm.load();
    return vm;
  }

  test('starts on Don\'t Drink with only Don\'t Drink enabled', () async {
    final vm = await buildVm();
    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink']);
    expect(vm.allAvailableModes.length, 3);
  });

  test('enabling a mode adds it to the switcher', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink', 'dont_smoke']);
  });

  test('setActive notifies the tracker', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    await vm.setActive('dont_smoke');
    expect(vm.activeMode.id, 'dont_smoke');
    expect(switched, ['dont_smoke']);
  });

  test('cannot deactivate the active mode', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    await vm.setActive('dont_smoke');
    await expectLater(
      vm.setEnabled('dont_smoke', false),
      throwsA(isA<ModeRuleError>()),
    );
    expect(vm.enabledModes.length, 2);
  });

  test('cannot disable the last enabled mode', () async {
    final vm = await buildVm();
    await expectLater(
      vm.setEnabled('dont_drink', false),
      throwsA(isA<ModeRuleError>()),
    );
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink']);
  });

  test('streakFor reports a non-active mode\'s streak', () async {
    await entries.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime.now().subtract(const Duration(days: 1)),
      level: kDontDrinkLevels[0],
    ));
    await entries.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime.now(),
      level: kDontDrinkLevels[0],
    ));

    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);

    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.streakFor('dont_smoke'), 2);
    expect(vm.streakFor('dont_drink'), 0);
  });

  test('creating a custom mode enables and lists it', () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('No Sugar', '🍭');
    expect(vm.allAvailableModes.map((m) => m.id), contains(mode.id));
    expect(vm.enabledModes.map((m) => m.id), contains(mode.id));
  });

  test('deleting the active custom mode falls back to an enabled one',
      () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('Temp', '🎯');
    await vm.setActive(mode.id);
    switched.clear();

    await vm.deleteCustom(mode.id);

    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.allAvailableModes.map((m) => m.id), isNot(contains(mode.id)));
    expect(switched, ['dont_drink']);
  });

  test('updateCustom renames a non-active mode without touching activeMode',
      () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('No Sugar', '🍭');
    // dont_drink stays active — the new custom mode is not.
    expect(vm.activeMode.id, 'dont_drink');

    await vm.updateCustom(mode.id, 'No Sugar At All', '🚫');

    final updated =
        vm.allAvailableModes.firstWhere((m) => m.id == mode.id);
    expect(updated.name, 'No Sugar At All');
    expect(updated.emoji, '🚫');
    expect(vm.activeMode.id, 'dont_drink');
  });

  test('updateCustom renaming the active mode refreshes the held instance',
      () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('Temp', '🎯');
    await vm.setActive(mode.id);
    switched.clear();

    await vm.updateCustom(mode.id, 'Renamed', '✨');

    expect(vm.activeMode.id, mode.id);
    expect(vm.activeMode.name, 'Renamed');
    expect(vm.activeMode.emoji, '✨');
  });

  test(
      'logging and clearing a day refreshes the tracker\'s mode streak '
      'through onDataChanged, with no explicit refreshStreaks call',
      () async {
    final vm = await buildVm();
    final tracker =
        TrackerViewModel(repository: entries, mode: kDontDrinkMode);
    await tracker.load();

    // onDataChanged is a fire-and-forget VoidCallback (it must be, to match
    // TrackerViewModel's signature) even though ModeViewModel.refreshStreaks
    // is async and does a real database query. Rather than pumping the event
    // queue and hoping the query finishes in time — which is exactly the
    // race that made this test flaky under parallel load — capture the
    // future the callback creates and await that directly. If
    // onDataChanged were never invoked, pendingRefresh would stay null and
    // `await null` would complete immediately, so the assertions below would
    // still fail as they should.
    Future<void>? pendingRefresh;
    tracker.onDataChanged = () {
      pendingRefresh = vm.refreshStreaks();
    };

    expect(vm.streakFor('dont_drink'), 0);

    await tracker.logDay(DateTime.now(), kDontDrinkLevels[0]);
    await pendingRefresh;
    expect(vm.streakFor('dont_drink'), 1);

    await tracker.clearDay(DateTime.now());
    await pendingRefresh;
    expect(vm.streakFor('dont_drink'), 0);
  });
}
