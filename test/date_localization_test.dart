import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/month_label_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// Dates are the half of translation that a completed .arb file does not
/// cover: every word can be translated and the sentence still be English,
/// because the *order* of the fields lives in the format pattern.
///
/// A hand-written 'EEEE, MMMM d, y' rendered German as "Sonntag, September 13,
/// 2026" — German words, American order, no missing key anywhere for the
/// parity test to find.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  testWidgets('the log sheet writes the date the way each language does',
      (tester) async {
    final date = DateTime(2026, 9, 13);

    Future<Set<String>> textsIn(Locale locale) async {
      await tester.pumpWidget(harness.wrap(
        Scaffold(body: DayEntrySheet(date: date)),
        locale: locale,
      ));
      await tester.pumpAndSettle();
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toSet();
    }

    final english = await textsIn(const Locale('en'));
    expect(english.any((t) => t.contains('September 13, 2026')), isTrue);

    final german = await textsIn(const Locale('de'));
    expect(
      german.any((t) => t.contains('13. September 2026')),
      isTrue,
      reason: 'German puts the day first, with a point after it',
    );
    expect(
      german.any((t) => t.contains('September 13')),
      isFalse,
      reason: 'the American order must not survive translation',
    );

    final italian = await textsIn(const Locale('it'));
    expect(
      italian.any((t) => t.contains('13 settembre 2026')),
      isTrue,
      reason: 'Italian puts the day first and lowercases the month',
    );
  });

  testWidgets('the month heading follows the locale too', (tester) async {
    await harness.tracker.logDay(DateTime(2026, 9, 2), kDontDrinkLevels[0]);

    for (final (locale, expected) in [
      (const Locale('en'), 'September 2026'),
      (const Locale('de'), 'September 2026'),
      (const Locale('it'), 'settembre 2026'),
    ]) {
      await tester.pumpWidget(harness.wrap(
        Scaffold(body: MonthLabelButton(month: DateTime(2026, 9))),
        locale: locale,
      ));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget,
          reason: 'in ${locale.languageCode} the heading reads "$expected"');
    }
  });
}
