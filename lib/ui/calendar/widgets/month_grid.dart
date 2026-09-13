import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A color-coded month calendar. Each cell is tinted by that day's
/// [TrackedLevel]; future days are disabled.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.entries,
    required this.onDayTap,
  });

  final DateTime month;

  /// Entries for this month keyed by `yyyy-MM-dd`.
  final Map<String, DayEntry> entries;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateOnly.firstOfMonth(month);
    final daysInMonth = DateOnly.daysInMonth(month);
    // Monday-first grid. Dart weekday: Mon=1..Sun=7.
    final leadingBlanks = first.weekday - 1;
    final today = DateOnly.today();

    final l10n = AppLocalizations.of(context);
    final weekdayLabels = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _DayCell(
                date: DateTime(month.year, month.month, day),
                entry: entries[
                    DateOnly.keyFor(DateTime(month.year, month.month, day))],
                isToday: DateOnly.isSameDay(
                    DateTime(month.year, month.month, day), today),
                isFuture:
                    DateTime(month.year, month.month, day).isAfter(today),
                onTap: onDayTap,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entry,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final DayEntry? entry;
  final bool isToday;
  final bool isFuture;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = entry?.level;
    final bg = level?.color ??
        (isFuture
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest);
    final fg = level?.onColor ??
        (isFuture
            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
            : theme.colorScheme.onSurface);

    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final hasNote = entry?.note != null && entry!.note!.trim().isNotEmpty;
    // Colour is the only thing this cell says visually, which says nothing at
    // all to a screen reader. Spell it out instead: the date, what was logged,
    // and whether there is a note behind it.
    final status = isFuture
        ? l10n.a11yDayFuture
        : (entry?.level.shortLabel ?? l10n.a11yDayUnlogged);
    final dateLabel = DateFormat.yMMMMd(locale).format(date);

    return Semantics(
      button: !isFuture,
      label: hasNote
          ? l10n.a11yDayCellWithNote(dateLabel, status)
          : l10n.a11yDayCell(dateLabel, status),
      excludeSemantics: true,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isFuture ? null : () => onTap(date),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${date.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              // A day carrying a note gets a dot, so the note is findable
              // later without opening every day to look. The note itself is
              // never drawn here: this grid is what gets shared as an image.
              if (entry?.note != null && entry!.note!.trim().isNotEmpty)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
