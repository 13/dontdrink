import 'dart:io';

import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers [TrackerViewModel.switchMode] — the method that actually makes
/// "each mode has its own history" true in the running app. Nothing else in
/// the test suite exercises it: mode_viewmodel_test.dart substitutes a fake
/// callback, and mode_isolation_test.dart proves isolation only at the
/// repository layer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDbDir =
        Directory.systemTemp.createTempSync('dontdrink_tracker_viewmodel');
    await databaseFactory.setDatabasesPath(tempDbDir.path);
  });

  tearDownAll(() {
    if (tempDbDir.existsSync()) tempDbDir.deleteSync(recursive: true);
  });

  late EntryRepository repo;

  setUp(() async {
    repo = EntryRepository();
    await repo.deleteAllForMode('dont_drink');
    await repo.deleteAllForMode('dont_smoke');
  });

  test(
      'switchMode clears the previous mode\'s in-memory state and loads the '
      'new mode\'s, and switching back restores it', () async {
    final today = DateOnly.normalize(DateTime.now());

    final vm = TrackerViewModel(repository: repo, mode: kDontDrinkMode);
    await vm.load();

    await vm.logDay(today, kDontDrinkLevels[0]);
    expect(vm.entryFor(today), isNotNull);
    expect(vm.stats.currentStreak, greaterThan(0));

    await vm.switchMode(kDontSmokeMode);
    expect(vm.mode.id, 'dont_smoke');
    expect(vm.allEntries, isEmpty);
    expect(vm.stats.currentStreak, 0);
    expect(vm.stats.longestStreak, 0);
    expect(vm.stats.totalLoggedDays, 0);
    expect(vm.visibleMonth, DateOnly.firstOfMonth(DateTime.now()));

    await vm.switchMode(kDontDrinkMode);
    expect(vm.mode.id, 'dont_drink');
    expect(vm.entryFor(today), isNotNull);
    expect(vm.stats.currentStreak, greaterThan(0));
  });

  test(
      'switchMode with the same id (a rename) updates the held mode without '
      'reloading from the repository', () async {
    final today = DateOnly.normalize(DateTime.now());

    final vm = TrackerViewModel(repository: repo, mode: kDontDrinkMode);
    await vm.load();
    await vm.logDay(today, kDontDrinkLevels[0]);
    expect(vm.mode.name, "Don't Drink");

    // Delete the entry directly in the repository, bypassing the view
    // model. If switchMode's same-id branch reloaded from the repository,
    // this entry would vanish from the view model too; if it genuinely
    // updates the held mode in place without reloading, the in-memory entry
    // survives.
    await repo.delete('dont_drink', today);

    final renamed = kDontDrinkMode.copyWith(name: 'No Booze');
    await vm.switchMode(renamed);

    expect(vm.mode.id, 'dont_drink');
    expect(vm.mode.name, 'No Booze');
    expect(vm.entryFor(today), isNotNull,
        reason: 'a same-id switchMode must not reload from the repository');
  });
}
