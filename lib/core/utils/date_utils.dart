import 'package:intl/intl.dart';

/// Helpers for working with date-only values (no time component).
///
/// The app keys everything by calendar day, so these utilities centralize the
/// normalization and `yyyy-MM-dd` formatting used throughout the codebase.
class DateOnly {
  DateOnly._();

  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  /// Strip the time component, returning midnight local time for [date].
  static DateTime normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Today at midnight local time.
  static DateTime today() => normalize(DateTime.now());

  /// The hour a tracked day rolls over.
  ///
  /// Not midnight: someone logging a night out at 01:00 means the night that
  /// just happened, not the day that started an hour ago. Four in the morning
  /// is the usual convention for this, and it is late enough that an early
  /// riser at 05:00 still gets the new day.
  static const int dayStartHour = 4;

  /// Which tracked day [now] belongs to.
  ///
  /// Between midnight and [dayStartHour] that is still yesterday.
  static DateTime trackingDay([DateTime? now]) {
    final at = now ?? DateTime.now();
    final day = normalize(at);
    return at.hour < dayStartHour
        ? day.subtract(const Duration(days: 1))
        : day;
  }

  /// True when [date] is the day the user is currently living, by the same
  /// rule.
  static bool isTrackingToday(DateTime date, [DateTime? now]) =>
      isSameDay(date, trackingDay(now));

  /// The `yyyy-MM-dd` key used as the database primary key.
  static String keyFor(DateTime date) => _keyFormat.format(date);

  /// Parse a `yyyy-MM-dd` key back into a normalized [DateTime].
  static DateTime parseKey(String key) => _keyFormat.parse(key);

  /// Whole-day difference (b - a), ignoring time and DST quirks.
  static int daysBetween(DateTime a, DateTime b) {
    final from = normalize(a);
    final to = normalize(b);
    return (to.difference(from).inHours / 24).round();
  }

  /// True if the two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// First day of the month containing [date].
  static DateTime firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Last day of the month containing [date].
  static DateTime lastOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// Number of days in the month containing [date].
  static int daysInMonth(DateTime date) => lastOfMonth(date).day;
}
