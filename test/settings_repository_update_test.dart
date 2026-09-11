import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('last update check is null before any check', () async {
    expect(await SettingsRepository().getLastUpdateCheck(), isNull);
  });

  test('last update check round-trips to the second', () async {
    final repo = SettingsRepository();
    final when = DateTime.fromMillisecondsSinceEpoch(1750000000000);
    await repo.setLastUpdateCheck(when);
    expect(await repo.getLastUpdateCheck(), when);
  });

  test('skipped version is null by default and round-trips', () async {
    final repo = SettingsRepository();
    expect(await repo.getSkippedVersion(), isNull);
    await repo.setSkippedVersion('1.2.0');
    expect(await repo.getSkippedVersion(), '1.2.0');
  });

  test('clearing the skipped version removes it', () async {
    final repo = SettingsRepository();
    await repo.setSkippedVersion('1.2.0');
    await repo.clearSkippedVersion();
    expect(await repo.getSkippedVersion(), isNull);
  });
}
