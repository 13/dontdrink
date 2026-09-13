import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/share_image_service.dart';
import 'package:dont_drink/ui/achievements/achievements_screen.dart';
import 'package:dont_drink/ui/calendar/calendar_screen.dart';
import 'package:dont_drink/ui/dashboard/dashboard_screen.dart';
import 'package:dont_drink/ui/statistics/widgets/distribution_pie.dart';
import 'package:dont_drink/ui/widgets/badge_share_dialog.dart';
import 'package:dont_drink/ui/widgets/month_picker_dialog.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/yearly/widgets/year_months_grid.dart';
import 'package:dont_drink/ui/yearly/yearly_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    testWidgets('every past month is reachable, even with no history',
        (tester) async {
      // The first version bounded the picker by the first logged entry, so a
      // user whose history started this month found eleven of twelve buttons
      // greyed out — exactly when back-filling last week matters most.
      final now = DateTime.now();
      await tester.pumpWidget(harness.wrap(
        Scaffold(
          body: MonthPickerDialog(
            initialMonth: DateTime(now.year, now.month),
            monthsWithData: {DateTime(now.year, now.month)},
            firstMonth: DateTime(now.year, now.month),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final months = tester
          .widgetList<TextButton>(find.descendant(
            of: find.byType(GridView),
            matching: find.byType(TextButton),
          ))
          .toList();
      final disabled = months.where((b) => b.onPressed == null).length;

      expect(disabled, 12 - now.month,
          reason: 'only months still in the future may be unreachable');
      // Selection is a filled background on the same widget every other month
      // uses, not a different button type with different metrics.
      final current = tester.widget<TextButton>(find.ancestor(
        of: find.text(DateFormat('MMM').format(now)),
        matching: find.byType(TextButton),
      ));
      expect(
        current.style?.backgroundColor?.resolve(const {}),
        isNotNull,
        reason: 'the month being shown is marked as selected',
      );
    });

    testWidgets('the year arrows reach back before the first entry',
        (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(harness.wrap(
        Scaffold(
          body: MonthPickerDialog(
            initialMonth: DateTime(now.year, now.month),
            monthsWithData: const {},
            firstMonth: DateTime(now.year, now.month),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('${now.year - 1}'), findsOneWidget,
          reason: 'last year is reachable on a fresh install');
    });

    testWidgets('the selected month is readable, at any text size',
        (tester) async {
      // It was not: the row height came from the cell width, leaving 48.2pt
      // for a 48.3pt button, and the selected month's label was clipped to a
      // sliver — worse at a larger text scale, which is how it shipped.
      for (final scale in [1.0, 1.3, 1.8]) {
        await tester.pumpWidget(harness.wrap(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: MonthPickerDialog(
                initialMonth: DateTime(2026, 9),
                monthsWithData: {DateTime(2026, 9)},
                firstMonth: DateTime(2026, 1),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final label = tester.getRect(find.text('Sep'));
        final button = tester.getRect(find.ancestor(
          of: find.text('Sep'),
          matching: find.byType(TextButton),
        ));

        expect(label.height, greaterThan(8 * scale),
            reason: 'at scale $scale the label is more than a sliver');
        expect(button.top, lessThanOrEqualTo(label.top),
            reason: 'at scale $scale the label sits inside its button');
        expect(button.bottom, greaterThanOrEqualTo(label.bottom),
            reason: 'at scale $scale the label is not clipped off the bottom');
      }
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

  group('yearly layouts', () {
    testWidgets('switching to months draws twelve calendars, still shareable',
        (tester) async {
      await harness.tracker
          .logDay(DateTime(DateTime.now().year, 3, 14), kDontDrinkLevels[0]);
      harness.tracker.clearPendingEarns();

      await tester.pumpWidget(harness.wrap(const YearlyScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(YearHeatmap), findsOneWidget);
      expect(find.byType(YearMonthsGrid), findsNothing);

      await tester.tap(find.text('Months'));
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthsGrid), findsOneWidget);
      expect(find.byType(YearHeatmap), findsNothing);
      expect(find.text('March'), findsOneWidget,
          reason: 'each mini calendar names its month');
      expect(find.text('14'), findsWidgets,
          reason: 'and carries real day numbers');

      // The share button captures whatever is on screen, so the boundary has
      // to still be there after the switch.
      expect(
        find.descendant(
          of: find.byType(RepaintBoundary),
          matching: find.byType(YearMonthsGrid),
        ),
        findsOneWidget,
      );
    });

    testWidgets('twelve calendars survive a narrow screen and large text',
        (tester) async {
      // Twelve calendars of seven columns is the densest thing in the app, and
      // density is where this app's layout bugs have lived.
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness.wrap(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: YearlyScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Months'));
      await tester.pumpAndSettle();

      expect(find.byType(YearMonthsGrid), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'no overflow at 320px wide with 1.8x text');
    });

    testWidgets('a day in the months layout opens that day', (tester) async {
      await tester.pumpWidget(harness.wrap(const YearlyScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Months'));
      await tester.pumpAndSettle();

      // The 2nd of January is always in the first mini calendar.
      await tester.tap(find.text('2').first);
      await tester.pumpAndSettle();

      expect(find.byType(DayEntrySheet), findsOneWidget);
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

  group('first run', () {
    testWidgets('an empty mode is told what to do, and told once',
        (tester) async {
      await tester.pumpWidget(harness.wrap(const DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Start where you are'), findsOneWidget);
      expect(find.textContaining('stays on this device'), findsOneWidget);

      // Logging anything retires it, with no flag to persist and nothing to
      // dismiss.
      await harness.tracker.logDay(DateTime.now(), kDontDrinkLevels[0]);
      await tester.pumpAndSettle();

      expect(find.text('Start where you are'), findsNothing);
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