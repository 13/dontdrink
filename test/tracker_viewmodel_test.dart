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

  test(
      'a badge is earned again after a relapse, and the earn carries the '
      'running count', () async {
    final vm = TrackerViewModel(repository: repo, mode: kDontDrinkMode);
    await vm.load();

    final clean = kDontDrinkLevels[0];
    final heavy = kDontDrinkLevels[3];
    final start = DateTime(2026, 1, 1);

    // First run of three clean days earns the day-1 and day-3 badges.
    for (var i = 0; i < 3; i++) {
      await vm.logDay(start.add(Duration(days: i)), clean);
    }
    expect(
      vm.pendingEarns.map((e) => e.achievement.id),
      contains('dont_drink.day_3'),
    );
    expect(vm.pendingEarns.single.count, 1);
    vm.clearPendingEarns();

    // Relapse, then a second three-day run.
    await vm.logDay(start.add(const Duration(days: 3)), heavy);
    expect(vm.pendingEarns, isEmpty);
    for (var i = 4; i < 7; i++) {
      await vm.logDay(start.add(Duration(days: i)), clean);
    }

    final again = vm.pendingEarns
        .firstWhere((e) => e.achievement.id == 'dont_drink.day_3');
    expect(again.count, 2, reason: 'the day-3 badge was earned a second time');
    expect(again.isRepeat, isTrue);

    final day3 = vm.achievements
        .firstWhere((s) => s.achievement.id == 'dont_drink.day_3');
    expect(day3.earnedCount, 2);
    expect(day3.firstEarnedOn, DateTime(2026, 1, 3));
    expect(day3.lastEarnedOn, DateTime(2026, 1, 7));
    expect(vm.totalEarns, greaterThan(2));
  });

  test('back-filling a forgotten day completes an older run and earns it',
      () async {
    final vm = TrackerViewModel(repository: repo, mode: kDontDrinkMode);
    await vm.load();

    final clean = kDontDrinkLevels[0];
    // Two clean days with a hole between them: two one-day runs, so the
    // day-3 badge is not earned yet.
    await vm.logDay(DateTime(2026, 2, 1), clean);
    await vm.logDay(DateTime(2026, 2, 3), clean);
    vm.clearPendingEarns();
    expect(
      vm.achievements
          .firstWhere((s) => s.achievement.id == 'dont_drink.day_3')
          .earnedCount,
      0,
    );

    // Filling the hole joins them into a three-day run. The *current* streak
    // never moved, so only a count comparison catches this earn.
    await vm.logDay(DateTime(2026, 2, 2), clean);

    expect(
      vm.pendingEarns.map((e) => e.achievement.id),
      contains('dont_drink.day_3'),
    );
  });

  test('logDay reports whether the day actually changed', () async {
    final vm = TrackerViewModel(repository: repo, mode: kDontDrinkMode);
    await vm.load();

    final clean = kDontDrinkLevels[0];
    final heavy = kDontDrinkLevels[3];
    final day = DateTime(2026, 4, 1);

    expect(await vm.logDay(day, clean), isTrue, reason: 'a new entry');
    expect(await vm.logDay(day, clean), isFalse,
        reason: 're-tapping the level already saved changes nothing');
    expect(await vm.logDay(day, heavy), isTrue, reason: 'a different level');
    expect(await vm.logDay(day, heavy, note: 'rough one'), isTrue,
        reason: 'the note changed');
  });
}
