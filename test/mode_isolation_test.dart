import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final repo = EntryRepository();

  setUp(() async {
    await repo.deleteAllForMode('dont_drink');
    await repo.deleteAllForMode('dont_smoke');
  });

  test('the same date can be logged in two modes independently', () async {
    final date = DateTime(2026, 6, 1);

    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: date,
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: date,
      level: kDontSmokeLevels[3],
    ));

    final drink = await repo.getForDate(kDontDrinkMode, date);
    final smoke = await repo.getForDate(kDontSmokeMode, date);

    expect(drink!.level.label, 'No Drinks');
    expect(smoke!.level.label, '16+ Cigarettes');
  });

  test('getAll returns only the requested mode\'s entries', () async {
    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: DateTime(2026, 6, 1),
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 1),
      level: kDontSmokeLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 2),
      level: kDontSmokeLevels[0],
    ));

    expect((await repo.getAll(kDontDrinkMode)).length, 1);
    expect((await repo.getAll(kDontSmokeMode)).length, 2);
  });

  test('streaks are computed per mode', () async {
    const stats = StatsService();
    final now = DateTime(2026, 6, 3);

    // Don't Drink: three clean days. Don't Smoke: relapsed today.
    for (final day in [1, 2, 3]) {
      await repo.upsert(DayEntry(
        modeId: 'dont_drink',
        date: DateTime(2026, 6, day),
        level: kDontDrinkLevels[0],
      ));
    }
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 3),
      level: kDontSmokeLevels[3],
    ));

    final drink = await repo.getAll(kDontDrinkMode);
    final smoke = await repo.getAll(kDontSmokeMode);

    expect(stats.currentStreak(drink, now: now), 3);
    expect(stats.currentStreak(smoke, now: now), 0);
  });

  test('deleting one mode\'s entries leaves the other untouched', () async {
    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: DateTime(2026, 6, 1),
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 1),
      level: kDontSmokeLevels[0],
    ));

    await repo.deleteAllForMode('dont_smoke');

    expect((await repo.getAll(kDontDrinkMode)).length, 1);
    expect((await repo.getAll(kDontSmokeMode)), isEmpty);
  });
}
