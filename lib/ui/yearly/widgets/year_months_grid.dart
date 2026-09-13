import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A year as twelve small calendars, three across and four down.
///
/// The heatmap answers "what did this year look like"; this answers "what
/// happened on the 14th" — the same data in the shape people actually read
/// dates in, and the one worth handing to someone as a picture.
class YearMonthsGrid extends StatelessWidget {
  const YearMonthsGrid({
    super.key,
    required this.year,
    required this.entries,
    required this.mode,
    this.onDayTap,
  });

  final int year;

  /// Entries of [year], keyed by `yyyy-MM-dd`.
  final Map<String, DayEntry> entries;

  final ModeDefinition mode;
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final today = DateOnly.today();

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = 10.0;
        final monthWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Column(
          children: [
            for (var row = 0; row < 4; row++) ...[
              if (row > 0) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: monthWidth,
                      child: _MiniMonth(
                        month: DateTime(year, row * columns + col + 1),
                        entries: entries,
                        today: today,
                        locale: locale,
                        onDayTap: onDayTap,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.month,
    required this.entries,
    required this.today,
    required this.locale,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, DayEntry> entries;
  final DateTime today;
  final String locale;
  final void Function(DateTime date)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateOnly.daysInMonth(month);
    // Dart's weekday runs Mon=1..Sun=7 and this grid is Monday-first, so the
    // blanks before the 1st are simply weekday - 1.
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;

    // Narrow weekday letters from the locale, rotated to start on Monday:
    // intl indexes them from Sunday.
    final narrow = DateFormat.EEEE(locale).dateSymbols.NARROWWEEKDAYS;
    final weekdayLetters = [for (var i = 1; i <= 7; i++) narrow[i % 7]];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / 7;
        // A cell is about 15 logical pixels wide on a phone. Below 7 the day
        // numbers stop being readable; above 11 they stop fitting.
        final fontSize = (cell * 0.58).clamp(7.0, 11.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.MMMM(locale).format(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                for (final letter in weekdayLetters)
                  SizedBox(
                    width: cell,
                    child: Text(
                      letter,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize * 0.85,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            for (var week = 0; week * 7 < leadingBlanks + daysInMonth; week++)
              Row(
                children: [
                  for (var slot = 0; slot < 7; slot++)
                    _MiniCell(
                      size: cell,
                      fontSize: fontSize,
                      date: _dateFor(week, slot, leadingBlanks, daysInMonth),
                      entries: entries,
                      today: today,
                      locale: locale,
                      onTap: onDayTap,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// The date in this week/weekday slot, or null for the blanks before the 1st
  /// and after the last day.
  DateTime? _dateFor(int week, int slot, int leadingBlanks, int daysInMonth) {
    final day = week * 7 + slot - leadingBlanks + 1;
    if (day < 1 || day > daysInMonth) return null;
    return DateTime(month.year, month.month, day);
  }
}

class _MiniCell extends StatelessWidget {
  const _MiniCell({
    required this.size,
    required this.fontSize,
    required this.date,
    required this.entries,
    required this.today,
    required this.locale,
    required this.onTap,
  });

  final double size;
  final double fontSize;
  final DateTime? date;
  final Map<String, DayEntry> entries;
  final DateTime today;
  final String locale;
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (date == null) return SizedBox(width: size, height: size);

    final entry = entries[DateOnly.keyFor(date!)];
    final isFuture = date!.isAfter(today);
    final level = entry?.level;
    final background = level?.color ??
        theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: isFuture ? 0.3 : 1);
    final foreground = level?.onColor ??
        theme.colorScheme.onSurfaceVariant
            .withValues(alpha: isFuture ? 0.4 : 1);

    final l10n = AppLocalizations.of(context);
    final status = isFuture
        ? l10n.a11yDayFuture
        : (level?.shortLabel ?? l10n.a11yDayUnlogged);
    final dateLabel = DateFormat.yMMMMd(locale).format(date!);
    final hasNote = entry?.note != null && entry!.note!.trim().isNotEmpty;

    return Semantics(
      button: !isFuture && onTap != null,
      label: hasNote
          ? l10n.a11yDayCellWithNote(dateLabel, status)
          : l10n.a11yDayCell(dateLabel, status),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: (isFuture || onTap == null) ? null : () => onTap!(date!),
        child: Padding(
          padding: const EdgeInsets.all(0.5),
          child: Container(
            width: size - 1,
            height: size - 1,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(3),
              border: DateOnly.isSameDay(date!, today)
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date!.day}',
              maxLines: 1,
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
