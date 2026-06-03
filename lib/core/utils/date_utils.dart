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
