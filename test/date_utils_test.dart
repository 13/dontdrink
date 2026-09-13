import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rollover rule. A tracker for nights out cannot file 01:00 against the
/// day that started an hour ago.
void main() {
  group('trackingDay', () {
    test('before the rollover hour it is still yesterday', () {
      final lateNight = DateTime(2026, 5, 17, 1, 30);
      expect(DateOnly.trackingDay(lateNight), DateTime(2026, 5, 16));
    });

    test('at the rollover hour the new day begins', () {
      expect(
        DateOnly.trackingDay(DateTime(2026, 5, 17, 4)),
        DateTime(2026, 5, 17),
      );
    });

    test('the rest of the day is itself', () {
      expect(
        DateOnly.trackingDay(DateTime(2026, 5, 17, 22, 15)),
        DateTime(2026, 5, 17),
      );
    });

    test('it crosses a month boundary backwards', () {
      expect(
        DateOnly.trackingDay(DateTime(2026, 6, 1, 0, 5)),
        DateTime(2026, 5, 31),
      );
    });

    test('isTrackingToday follows the same rule', () {
      final lateNight = DateTime(2026, 5, 17, 2);
      expect(DateOnly.isTrackingToday(DateTime(2026, 5, 16), lateNight), isTrue);
      expect(
          DateOnly.isTrackingToday(DateTime(2026, 5, 17), lateNight), isFalse);
    });
  });
}
