import 'package:dont_drink/ui/modes/custom_mode_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// Guards the bug this sheet actually shipped with: the keyboard inset was
/// read from the caller's context, captured once while the keyboard was still
/// closed, so the autofocused name field sat behind the keyboard forever.
///
/// The regression is invisible to a unit test and to `flutter analyze`, which
/// is the whole argument for having widget tests at all.
void main() {
  WidgetHarness.initDatabase();

  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async => harness.dispose());

  testWidgets('the name field stays clear of a keyboard that opens later',
      (tester) async {
    const keyboard = 300.0;
    final insets = ValueNotifier<double>(0);

    // The sheet is opened while the keyboard is still closed and the insets
    // only grow afterwards, which is exactly the sequence the shipped bug
    // could not survive: it captured the caller's MediaQuery once, at open
    // time, when the inset was still zero.
    await tester.pumpWidget(harness.wrap(
      Scaffold(
        body: Builder(
          builder: (inner) => Center(
            child: ElevatedButton(
              onPressed: () => CustomModeEditor.show(inner),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      keyboardInset: insets,
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    insets.value = keyboard; // the keyboard comes up
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final field = tester.getRect(find.byType(TextField));

    expect(
      field.bottom,
      lessThanOrEqualTo(screenHeight - keyboard),
      reason: 'the field must sit above the keyboard, not behind it',
    );
  });

  testWidgets('the editor scrolls rather than clipping its save button',
      (tester) async {
    await tester.pumpWidget(harness.wrap(
      const Scaffold(body: CustomModeEditor()),
      keyboardInset: ValueNotifier<double>(300),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsWidgets,
        reason: 'a short screen must be scrollable, not truncated');

    await tester.dragUntilVisible(
      find.text('Create mode'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -50),
    );
    expect(find.text('Create mode'), findsOneWidget);
  });

  testWidgets('a new mode needs a name before it can be saved',
      (tester) async {
    await tester.pumpWidget(harness.wrap(
      const Scaffold(body: CustomModeEditor()),
    ));
    await tester.pumpAndSettle();

    final saveButton =
        tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(saveButton.onPressed, isNull, reason: 'empty name, nothing to save');

    await tester.enterText(find.byType(TextField), 'No Sugar');
    await tester.pump();

    final enabled =
        tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(enabled.onPressed, isNotNull);
  });
}
