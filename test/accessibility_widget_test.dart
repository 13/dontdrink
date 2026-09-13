import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/ui/achievements/achievements_screen.dart';
import 'package:dont_drink/ui/calendar/calendar_screen.dart';
import 'package:dont_drink/ui/statistics/widgets/distribution_pie.dart';
import 'package:dont_drink/ui/yearly/yearly_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// The calendar, the heatmap, the donut and the badges say everything through
/// colour, which says nothing to a screen reader. These tests pin the labels
/// that make them speak — they are cheap to break and invisible when broken.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  testWidgets('a calendar cell announces its date, status and note',
      (tester) async {
    final handle = tester.ensureSemantics();
    final today = DateTime.now();

    await harness.tracker.logDay(today, kDontDrinkLevels[0], note: 'quiet day');

    await tester.pumpWidget(harness.wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    // The grid appears twice on this screen only if something is duplicated;
    // matching by prefix keeps the test about the label, not the layout.
    final labels = _semanticLabels(tester);
    expect(
      labels.any((l) => l.contains('has a note') && l.contains('None')),
      isTrue,
      reason: 'the logged day carries its level and the note marker',
    );
    expect(
      labels.any((l) => l.contains('not logged')),
      isTrue,
      reason: 'an empty day says so rather than staying silent',
    );

    handle.dispose();
  });

  testWidgets('heatmap cells are labelled, not anonymous squares',
      (tester) async {
    final handle = tester.ensureSemantics();
    final today = DateTime.now();
    await harness.tracker.logDay(today, kDontDrinkLevels[3]);

    await tester.pumpWidget(harness.wrap(const YearlyScreen()));
    await tester.pumpAndSettle();

    final labels = _semanticLabels(tester);
    expect(labels.any((l) => l.contains('Heavy')), isTrue);
    expect(labels.any((l) => l.contains('in the future')), isTrue,
        reason: 'days that have not happened say so');

    handle.dispose();
  });

  testWidgets('donut legend rows carry the numbers the chart only draws',
      (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(harness.wrap(
      Scaffold(
        body: SizedBox(
          height: 220,
          child: DistributionPie(
            counts: {kDontDrinkLevels[0]: 4, kDontDrinkLevels[3]: 1},
            levels: kDontDrinkLevels,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      _semanticLabels(tester).any((l) => l.contains('None, 4 days')),
      isTrue,
    );

    await tester.tap(find.ancestor(
      of: find.text(kDontDrinkLevels[0].shortLabel),
      matching: find.byType(InkWell),
    ));
    await tester.pumpAndSettle();

    expect(
      _semanticLabels(tester).any((l) => l.contains('None, 4 days, selected')),
      isTrue,
      reason: 'selection is not only a thicker ring',
    );

    handle.dispose();
  });

  testWidgets('badges say whether they are earned and shareable',
      (tester) async {
    final handle = tester.ensureSemantics();
    await harness.tracker.logDay(DateTime.now(), kDontDrinkLevels[0]);

    await tester.pumpWidget(harness.wrap(const AchievementsScreen()));
    await tester.pumpAndSettle();

    final labels = _semanticLabels(tester);
    expect(
      labels.any((l) =>
          l.contains('Better Liver Begins') && l.contains('tap to share')),
      isTrue,
    );
    expect(
      labels.any((l) => l.contains('not earned yet')),
      isTrue,
      reason: 'a locked badge is distinguishable without seeing the padlock',
    );

    handle.dispose();
  });
}

/// Every semantic label currently in the tree.
List<String> _semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.rootElement!.renderObject!.debugSemantics!);
  return labels;
}
