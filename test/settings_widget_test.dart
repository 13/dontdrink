import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/ui/settings/settings_screen.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/widget_harness.dart';

/// The biggest screen in the app — theme, language, reminders, export, import,
/// updates, About — had no test at all.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;
  late SettingsViewModel settings;

  setUp(() async {
    harness = await WidgetHarness.create();
    SharedPreferences.setMockInitialValues({});
    settings = SettingsViewModel(repository: SettingsRepository());
    await settings.load();
  });

  tearDown(() async => harness.dispose());

  Widget screen({Locale? locale}) => ChangeNotifierProvider.value(
        value: settings,
        child: harness.wrap(const SettingsScreen(), locale: locale),
      );

  /// Settings is a lazy ListView, so anything below the fold is not built
  /// yet. Scroll it into existence before touching it.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(
      target,
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('theme choice is applied and persisted', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.system);

    await scrollTo(tester, find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    expect(await SettingsRepository().getThemeMode(), ThemeMode.dark,
        reason: 'the choice outlives the widget');
  });

  testWidgets('language choice is applied and persisted', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(settings.locale, isNull, reason: 'follows the system by default');

    await scrollTo(tester, find.text('Deutsch'));
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(settings.locale?.languageCode, 'de');
    expect((await SettingsRepository().getLocale())?.languageCode, 'de');
  });

  testWidgets('each language is listed under its own name', (tester) async {
    // Someone who cannot read the current UI language still has to find
    // theirs, so these are deliberately untranslated.
    await tester.pumpWidget(screen(locale: const Locale('it')));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Italiano'));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
    // The app bar stays put while the list scrolls, so it is the stable
    // place to check that the rest of the screen is translated.
    expect(find.text('Impostazioni'), findsWidgets,
        reason: 'the rest of the screen is translated');
  });

  testWidgets('the reminder time row is disabled until the switch is on',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Reminder time'));
    final row = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Reminder time'),
        matching: find.byType(ListTile),
      ),
    );
    expect(row.enabled, isFalse);
    expect(row.onTap, isNull,
        reason: 'a time you cannot be reminded at is not worth picking');
  });

  testWidgets('import asks before it merges anything', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Import data'));
    await tester.tap(find.text('Import data'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('overwritten'), findsOneWidget,
        reason: 'the dialog says what import does to existing days');

    // Cancelling must not reach the file picker, which has no host
    // implementation and would throw if it were opened.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the privacy note is shown and stays truthful', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await scrollTo(
        tester, find.textContaining('stored privately on this device'));
    expect(find.textContaining('stored privately on this device'),
        findsOneWidget);
  });
}
