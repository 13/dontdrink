import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
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
}
