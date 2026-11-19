import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/ui/achievements/achievements_screen.dart';
import 'package:dont_drink/ui/calendar/calendar_screen.dart';
import 'package:dont_drink/ui/dashboard/dashboard_screen.dart';
import 'package:dont_drink/ui/more/more_screen.dart';
import 'package:dont_drink/ui/notes/notes_screen.dart';
import 'package:dont_drink/ui/recovery/recovery_screen.dart';
import 'package:dont_drink/ui/statistics/statistics_screen.dart';
import 'package:dont_drink/ui/yearly/yearly_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// Every main screen, on a small phone with large text, in every language.
///
/// Overflow bugs in this app have turned up one widget at a time — the
/// streak card, the statistics tiles, the calendar's month stats, the notes
/// list — each a row that measured fine in English at 1x. This sweeps them
/// all at once, with enough history that every section is populated, and
/// scrolls to the bottom so lazily built content is laid out too.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  final screens = <String, Widget Function()>{
    'dashboard': () => const DashboardScreen(),
    'awards': () => const AchievementsScreen(),
    'statistics': () => const StatisticsScreen(),
    'more': () => const MoreScreen(),
    'calendar': () => const CalendarScreen(),
    'year': () => const YearlyScreen(),
    'notes': () => const NotesScreen(),
    'recovery': () => const RecoveryScreen(),
  };

  for (final locale in const [Locale('en'), Locale('de'), Locale('it')]) {
    for (final screen in screens.entries) {
      testWidgets(
          '${screen.key} fits 320px at 1.8x text (${locale.languageCode})',
          (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        // Forty days: a running streak, every section filled, a slip each
        // week so the charts have more than one level, and a note.
        final today = DateTime.now();
        for (var i = 0; i < 40; i++) {
          await harness.tracker.logDay(
            today.subtract(Duration(days: i)),
            kDontDrinkLevels[i % 7 == 6 ? 2 : 0],
            note: i == 3 ? 'A long evening, but I stayed with water.' : null,
          );
        }
        harness.tracker.clearPendingEarns();

        await tester.pumpWidget(harness.wrap(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: screen.value(),
          ),
          locale: locale,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final scroll = find.byType(Scrollable).first;
        for (var i = 0; i < 15; i++) {
          await tester.drag(scroll, const Offset(0, -400),
              warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'no overflow anywhere down the screen');
        }
      });
    }
  }
}
