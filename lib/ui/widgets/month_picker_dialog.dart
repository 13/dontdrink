import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Jump straight to a month instead of stepping there one arrow at a time.
///
/// Only the future is out of bounds. Months with no entries are dimmed but
/// selectable — an empty month is exactly the one you open to fill in, and
/// someone who started today still has last week to record. Anchoring the
/// lower bound to the first logged month, as this first did, greyed out
/// eleven of twelve buttons for a new user and made the picker look broken.
class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({
    super.key,
    required this.initialMonth,
    required this.monthsWithData,
    required this.firstMonth,
  });

  /// The month currently being shown.
  final DateTime initialMonth;

  /// First-of-month dates that have at least one entry.
  final Set<DateTime> monthsWithData;

  /// Oldest month with an entry, used only to decide how far back the year
  /// arrows are worth offering — never to block a month from being picked.
  final DateTime firstMonth;

  /// How far back the year arrows go beyond recorded history. Far enough to
  /// back-fill a past year, short of wandering into empty decades.
  static const int _extraYearsBack = 2;

  /// Returns the chosen month, or null if dismissed.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialMonth,
    required Set<DateTime> monthsWithData,
    required DateTime firstMonth,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => MonthPickerDialog(
        initialMonth: initialMonth,
        monthsWithData: monthsWithData,
        firstMonth: firstMonth,
      ),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _year = widget.initialMonth.year;

  /// The oldest year the arrows offer: a couple before the oldest entry, and
  /// before this year too, so a fresh install can still reach last year.
  int get _earliestYear {
    final byHistory = widget.firstMonth.year;
    final byClock = DateTime.now().year;
    final base = byHistory < byClock ? byHistory : byClock;
    return base - MonthPickerDialog._extraYearsBack;
  }

  /// How much room the row needs relative to the default text size. Never
  /// less than 1: a smaller setting does not buy back space the button's own
  /// minimum height still takes.
  static double _textScale(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return scale < 1 ? 1 : scale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat.MMM(locale);
    final now = DateOnly.firstOfMonth(DateTime.now());

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: _year > _earliestYear
                ? () => setState(() => _year--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: _year < now.year ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: SizedBox(
        width: 320,
        child: GridView(
          shrinkWrap: true,
          // A fixed row height, not one derived from the cell width. With
          // childAspectRatio the row was 48.2pt while the button inside it is
          // 48.3pt tall, so the selected month's label was clipped to a sliver
          // — and any larger text scale clipped it away entirely.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 52 * _textScale(context),
          ),
          children: [
            for (var month = 1; month <= 12; month++)
              _MonthButton(
                label: monthName.format(DateTime(_year, month)),
                month: DateTime(_year, month),
                selected: _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month,
                hasData: widget.monthsWithData.contains(DateTime(_year, month)),
                // Only the future is unreachable. Everything else is a day
                // you might want to fill in.
                enabled: !DateTime(_year, month).isAfter(now),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.label,
    required this.month,
    required this.selected,
    required this.hasData,
    required this.enabled,
  });

  final String label;
  final DateTime month;
  final bool selected;
  final bool hasData;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPressed = enabled ? () => Navigator.of(context).pop(month) : null;

    // One widget for both states, differing only in colour. Swapping a
    // TextButton for a FilledButton also swapped their default metrics, which
    // is how the selected month ended up taller than the row holding it.
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.brand : null,
        // Dimmed, not disabled: a month with nothing in it is exactly the one
        // you might open to fill it in.
        foregroundColor: selected
            ? Colors.white
            : (hasData
                ? AppColors.brand
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontWeight:
              selected || hasData ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
