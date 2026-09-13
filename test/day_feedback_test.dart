import 'package:dont_drink/services/day_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules behind the quiet message shown after a log. Kept as a pure
/// function precisely so the "when do we stay silent" cases are pinned down
/// here rather than in a button handler.
void main() {
  group('feedbackFor', () {
    test('a clean day with no badge gets a cheer', () {
      expect(
        feedbackFor(
            isToday: true, isClean: true, earnedBadge: false, changed: true),
        DayFeedback.cheer,
      );
    });

    test('any non-clean day gets comfort', () {
      expect(
        feedbackFor(
            isToday: true, isClean: false, earnedBadge: false, changed: true),
        DayFeedback.comfort,
      );
    });

    test('a badge suppresses the cheer — one dialog per tap', () {
      expect(
        feedbackFor(
            isToday: true, isClean: true, earnedBadge: true, changed: true),
        isNull,
      );
    });

    test('back-filling an earlier day stays silent', () {
      expect(
        feedbackFor(
            isToday: false, isClean: true, earnedBadge: false, changed: true),
        isNull,
      );
      expect(
        feedbackFor(
            isToday: false, isClean: false, earnedBadge: false, changed: true),
        isNull,
        reason: 'a day already lived through should not be reopened',
      );
    });

    test('re-tapping the level already saved stays silent', () {
      expect(
        feedbackFor(
            isToday: true, isClean: true, earnedBadge: false, changed: false),
        isNull,
      );
      expect(
        feedbackFor(
            isToday: true, isClean: false, earnedBadge: false, changed: false),
        isNull,
      );
    });
  });

  group('feedbackVariant', () {
    test('is stable within a calendar day', () {
      final morning = DateTime(2026, 3, 14, 8);
      final night = DateTime(2026, 3, 14, 23, 59);
      expect(feedbackVariant(morning, 5), feedbackVariant(night, 5));
    });

    test('moves on with the next day', () {
      expect(
        feedbackVariant(DateTime(2026, 3, 14), 5),
        isNot(feedbackVariant(DateTime(2026, 3, 15), 5)),
      );
    });

    test('stays inside the list', () {
      for (var day = 1; day <= 366; day++) {
        final index = feedbackVariant(DateTime(2026, 1, day), 5);
        expect(index, inInclusiveRange(0, 4));
      }
    });

    test('an empty list cannot produce an out-of-range index', () {
      expect(feedbackVariant(DateTime(2026, 3, 14), 0), 0);
    });
  });
}
