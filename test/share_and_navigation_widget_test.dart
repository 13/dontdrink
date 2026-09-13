import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/share_image_service.dart';
import 'package:dont_drink/ui/achievements/achievements_screen.dart';
import 'package:dont_drink/ui/calendar/calendar_screen.dart';
import 'package:dont_drink/ui/statistics/widgets/distribution_pie.dart';
import 'package:dont_drink/ui/widgets/badge_share_dialog.dart';
import 'package:dont_drink/ui/widgets/month_picker_dialog.dart';
import 'package:dont_drink/ui/yearly/yearly_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  group('month picker', () {
    testWidgets('the month label opens a picker and jumps to the choice',
        (tester) async {
      await harness.tracker
          .logDay(DateTime(2026, 3, 4), kDontDrinkLevels[0]);

      await tester.pumpWidget(harness.wrap(const CalendarScreen()));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final currentLabel = monthHeaderLabel(now);
      // Twice on screen: the tappable header, and the caption inside the card
      // that gives a shared image its period.
      expect(find.text(currentLabel), findsNWidgets(2));

      await tester.tap(find.text(currentLabel).first);
      await tester.pumpAndSettle();
      expect(find.byType(MonthPickerDialog), findsOneWidget);

      // Walk the year arrows back to 2026 if this is running later, then pick.
      while (find.text('${now.year}').evaluate().isNotEmpty &&
          now.year > 2026) {
        await tester.tap(find.byIcon(Icons.chevron_left).first);
        await tester.pumpAndSettle();
        break;
      }

      await tester.tap(find.text('Mar').last);
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerDialog), findsNothing);
      expect(harness.tracker.visibleMonth.month, 3);
    });

    testWidgets('a future month cannot be chosen', (tester) async {
      await tester.pumpWidget(harness.wrap(
        Scaffold(
          body: MonthPickerDialog(
            initialMonth: DateTime(DateTime.now().year, 1),
            monthsWithData: const {},
            firstMonth: DateTime(DateTime.now().year, 1),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final december = DateTime(DateTime.now().year, 12);
      if (december.isAfter(DateTime.now())) {
        final button = tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Dec'),
            matching: find.byType(TextButton),
          ),
        );
        expect(button.onPressed, isNull,
            reason: 'the arrows already stop at this month; so does this');
      }
    });
  });

  group('donut', () {
    testWidgets('tapping a legend row selects and deselects the level',
        (tester) async {
      final counts = {
        kDontDrinkLevels[0]: 5,
        kDontDrinkLevels[3]: 2,
      };

      await tester.pumpWidget(harness.wrap(
        Scaffold(
          body: SizedBox(
            height: 220,
            child: DistributionPie(
              counts: counts,
              levels: kDontDrinkLevels,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // The legend row, not the centre detail — which repeats the same label
      // once something is selected, and is not a tap target.
      final legendRow = find.ancestor(
        of: find.text(kDontDrinkLevels[0].shortLabel),
        matching: find.byType(InkWell),
      );

      // Nothing selected: the hole is empty, so its unit label is absent.
      expect(find.text('days'), findsNothing);

      await tester.tap(legendRow);
      await tester.pumpAndSettle();
      expect(find.text('days'), findsOneWidget,
          reason: 'the centre now names the selected level');

      await tester.tap(legendRow);
      await tester.pumpAndSettle();
      expect(find.text('days'), findsNothing,
          reason: 'tapping the same row again clears it');
    });
  });

  group('yearly view', () {
    testWidgets('renders a cell per day and can step years', (tester) async {
      await harness.tracker
          .logDay(DateTime(DateTime.now().year, 1, 5), kDontDrinkLevels[0]);

      await tester.pumpWidget(harness.wrap(const YearlyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(YearHeatmap), findsOneWidget);
      expect(find.text('${DateTime.now().year}'), findsOneWidget);

      // Forward is blocked: there is no next year to show yet.
      final forward = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right).first,
      );
      expect(forward.onPressed, isNull);
    });
  });

  group('badge sharing', () {
    testWidgets('an earned badge opens a share card, a locked one does not',
        (tester) async {
      // Two clean days earns day_1 and day_3 is still locked.
      await harness.tracker
          .logDay(DateTime.now().subtract(const Duration(days: 1)),
              kDontDrinkLevels[0]);
      await harness.tracker.logDay(DateTime.now(), kDontDrinkLevels[0]);

      await tester.pumpWidget(harness.wrap(const AchievementsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Better Liver Begins'));
      await tester.pumpAndSettle();
      expect(find.byType(BadgeShareDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // A locked badge further down the list: scroll it into view first.
      await tester.dragUntilVisible(
        find.text('One Month Strong'),
        find.byType(ListView).first,
        const Offset(0, -120),
      );
      await tester.tap(find.text('One Month Strong'));
      await tester.pumpAndSettle();
      expect(find.byType(BadgeShareDialog), findsNothing,
          reason: 'a badge you have not earned is not yours to share');
    });
  });

  group('capture', () {
    testWidgets('a boundary that is not mounted fails cleanly',
        (tester) async {
      const service = ShareImageService();
      final key = GlobalKey();

      await expectLater(
        () => service.capture(key: key),
        throwsA(isA<ShareImageException>().having(
          (e) => e.failure,
          'failure',
          ShareFailure.nothingToCapture,
        )),
      );
    });
  });
}

/// The label the month header renders, in the test's default locale.
String monthHeaderLabel(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
