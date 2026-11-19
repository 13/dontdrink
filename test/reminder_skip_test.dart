import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/widget_harness.dart';

/// The daily reminder stays quiet on a day that is already logged.
void main() {
  group('nextReminderAt', () {
    const eight = TimeOfDay(hour: 20, minute: 0);
    final morning = DateTime(2026, 3, 10, 9);
    final night = DateTime(2026, 3, 10, 21);

    test('later today, or tomorrow once the time has passed', () {
      expect(NotificationService.nextReminderAt(morning, eight),
          DateTime(2026, 3, 10, 20));
      expect(NotificationService.nextReminderAt(night, eight),
          DateTime(2026, 3, 11, 20));
    });

    test('a logged today moves the next reminder to tomorrow', () {
      expect(
        NotificationService.nextReminderAt(morning, eight,
            skipDay: DateTime(2026, 3, 10)),
        DateTime(2026, 3, 11, 20),
      );
    });

    test('skipping a day the next reminder does not fall on changes nothing',
        () {
      // Already past eight: the next one is tomorrow's either way.
      expect(
        NotificationService.nextReminderAt(night, eight,
            skipDay: DateTime(2026, 3, 10)),
        DateTime(2026, 3, 11, 20),
      );
    });

    test('steps across a month end by calendar day', () {
      expect(
        NotificationService.nextReminderAt(DateTime(2026, 3, 31, 9), eight,
            skipDay: DateTime(2026, 3, 31)),
        DateTime(2026, 4, 1, 20),
      );
    });
  });

  group('allEnabledLoggedOn', () {
    WidgetHarness.initDatabase();

    late WidgetHarness harness;
    setUp(() async => harness = await WidgetHarness.create());
    tearDown(() async => harness.dispose());

    test('is true only once the day is logged', () async {
      final today = DateOnly.today();
      expect(await harness.modes.allEnabledLoggedOn(today), isFalse);

      await harness.tracker.logDay(today, kDontDrinkLevels[0]);
      expect(await harness.modes.allEnabledLoggedOn(today), isTrue);

      await harness.tracker.clearDay(today);
      expect(await harness.modes.allEnabledLoggedOn(today), isFalse,
          reason: 'clearing the day brings the reminder back');
    });
  });
}
