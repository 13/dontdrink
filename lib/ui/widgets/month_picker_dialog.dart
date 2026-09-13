import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Jump straight to a month instead of stepping there one arrow at a time.
///
/// Months that hold no entries are dimmed rather than disabled — an empty
/// month is still worth opening to fill in — and months in the future are
/// disabled, matching the ‹ › arrows, which already stop at the current one.
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

  /// Oldest month the user can reach: their first entry, or this month on a
  /// fresh install. Stops the year arrows wandering into empty decades.
  final DateTime firstMonth;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat('MMM', locale);
    final now = DateOnly.firstOfMonth(DateTime.now());

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed:
                _year > widget.firstMonth.year ? () => setState(() => _year--) : null,
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
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            for (var month = 1; month <= 12; month++)
              _MonthButton(
                label: monthName.format(DateTime(_year, month)),
                month: DateTime(_year, month),
                selected: _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month,
                hasData: widget.monthsWithData.contains(DateTime(_year, month)),
                enabled: !DateTime(_year, month).isAfter(now) &&
                    !DateTime(_year, month).isBefore(widget.firstMonth),
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
    final onPressed =
        enabled ? () => Navigator.of(context).pop(month) : null;

    if (selected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        // Dimmed, not disabled: a month with nothing in it is exactly the one
        // you might open to fill it in.
        foregroundColor: hasData
            ? AppColors.brand
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        textStyle: TextStyle(
          fontWeight: hasData ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      child: Text(label),
    );
  }
}
