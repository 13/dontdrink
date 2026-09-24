import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/day_feedback.dart';
import 'package:dont_drink/ui/widgets/achievement_unlock_dialog.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/day_feedback_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// What happens after tapping a level in the log sheet. The decision rules are
/// unit-tested in day_feedback_test.dart; this covers the wiring around them,
/// which is exactly the layer that had no tests at all.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  /// Open the sheet for today and tap the level at [index].
  Future<void> logToday(WidgetTester tester, int index) async {
    await tester.pumpWidget(harness.wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => DayEntrySheet.show(context, DateTime.now()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(kDontDrinkLevels[index].label));
    await tester.pumpAndSettle();
  }

  testWidgets('the first clean day earns a badge, and the badge dialog owns it',
      (tester) async {
    await logToday(tester, 0);

    expect(find.byType(AchievementUnlockDialog), findsOneWidget);
    expect(find.byType(DayFeedbackDialog), findsNothing,
        reason: 'one dialog per tap');
  });

  testWidgets('a clean day that crosses no threshold gets the quiet cheer',
      (tester) async {
    // Yesterday takes the day-1 badge out of the way, so today's log crosses
    // nothing and falls through to the cheer.
    await harness.tracker.logDay(
      DateTime.now().subtract(const Duration(days: 1)),
      kDontDrinkLevels[0],
    );
    harness.tracker.clearPendingEarns();

    await logToday(tester, 0);

    expect(find.byType(DayFeedbackDialog), findsOneWidget);
    expect(find.byType(AchievementUnlockDialog), findsNothing);
    expect(find.textContaining('Day 2'), findsOneWidget,
        reason: 'the cheer is headed by the streak');
  });

  testWidgets('a non-clean day gets comfort, not silence', (tester) async {
    await logToday(tester, 3); // "6+ Drinks"

    expect(find.byType(DayFeedbackDialog), findsOneWidget);
    expect(find.byType(AchievementUnlockDialog), findsNothing);
    expect(find.text('Need a boost'), findsOneWidget,
        reason: 'comfort offers a way out, without insisting');
  });

  testWidgets('re-tapping the level already saved says nothing',
      (tester) async {
    await logToday(tester, 3);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await logToday(tester, 3);
    expect(find.byType(DayFeedbackDialog), findsNothing,
        reason: 'nothing changed, so nothing happened');
  });

  testWidgets('the sheet speaks the active language', (tester) async {
    await tester.pumpWidget(harness.wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => DayEntrySheet.show(context, DateTime.now()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      locale: const Locale('de'),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Wie lief der Tag?'), findsOneWidget);
  });

  testWidgets('a note is saved with the day and comes back when reopened',
      (tester) async {
    await tester.pumpWidget(harness.wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => DayEntrySheet.show(context, DateTime.now()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dinner with friends');
    await tester.pump();

    // Typing focuses the field, which scrolls the level options up out of
    // view — the same thing that happens on a phone with the keyboard open.
    await tester.ensureVisible(find.text(kDontDrinkLevels[0].label));
    await tester.pumpAndSettle();

    // The note rides along with the level that is tapped.
    await tester.tap(find.text(kDontDrinkLevels[0].label));
    await tester.pumpAndSettle();

    expect(harness.tracker.entryFor(DateTime.now())?.note,
        'Dinner with friends');

    // Dismiss whatever dialog the log produced, then reopen the day.
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Dinner with friends'), findsOneWidget,
        reason: 'the field is prefilled with what was stored');
  });

  testWidgets('editing only the note saves without re-logging the day',
      (tester) async {
    final today = DateTime.now();
    await harness.tracker.logDay(today, kDontDrinkLevels[3]);
    harness.tracker.clearPendingEarns();

    await tester.pumpWidget(harness.wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => DayEntrySheet.show(context, today),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Rough evening');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(harness.tracker.entryFor(today)?.note, 'Rough evening');
    expect(harness.tracker.entryFor(today)?.level.value,
        kDontDrinkLevels[3].value,
        reason: 'the level is untouched');
    expect(find.byType(DayFeedbackDialog), findsNothing,
        reason: 'writing a note is not the same event as logging the day');
  });


  /// Pump the dialog on its own, at a phone width.
  Future<void> pumpDialog(
    WidgetTester tester, {
    DayFeedback feedback = DayFeedback.comfort,
    int badgesEarned = 4,
    int bestStreak = 18,
    Locale? locale,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness.wrap(
      Scaffold(
        body: DayFeedbackDialog(
          feedback: feedback,
          streak: 3,
          badgesEarned: badgesEarned,
          bestStreak: bestStreak,
          variant: 0,
        ),
      ),
      locale: locale,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the German comfort buttons stay on a phone-width dialog',
      (tester) async {
    await pumpDialog(tester, locale: const Locale('de'));

    // A Row here overflowed and pushed "Schließen" off the dialog.
    expect(tester.takeException(), isNull);
    final dialog = tester.getRect(find.byType(Dialog));
    for (final label in ['Ich brauch was Aufbauendes', 'Schließen']) {
      final button = tester.getRect(find.text(label));
      expect(dialog.left <= button.left && button.right <= dialog.right, isTrue,
          reason: '"$label" must sit inside the dialog');
    }
  });

  testWidgets('comfort shows what is kept, as numbers', (tester) async {
    await pumpDialog(tester);

    expect(find.text('🏅 4 badges'), findsOneWidget);
    expect(find.text('🏆 18-day best'), findsOneWidget);
    expect(find.text('STILL YOURS'), findsOneWidget);
  });

  testWidgets('a part of the chip that is zero is left out', (tester) async {
    await pumpDialog(tester, badgesEarned: 0);

    expect(find.textContaining('badge'), findsNothing);
    expect(find.text('🏆 18-day best'), findsOneWidget);
  });

  testWidgets('with nothing kept yet, there is no chip at all',
      (tester) async {
    await pumpDialog(tester, badgesEarned: 0, bestStreak: 0);

    expect(find.text('STILL YOURS'), findsNothing);
  });

  testWidgets('the cheer has one button and no chip', (tester) async {
    await pumpDialog(tester, feedback: DayFeedback.cheer);

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('STILL YOURS'), findsNothing);
  });
}
