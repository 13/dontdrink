import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/share_image_button.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A whole year, one cell per day.
///
/// Twelve rows of up to 31 cells, coloured by the level logged that day, so a
/// year reads as a pattern rather than a list: the bad month, the week it
/// turned around, the stretch that became a streak.
class YearlyScreen extends StatefulWidget {
  const YearlyScreen({super.key});

  @override
  State<YearlyScreen> createState() => _YearlyScreenState();
}

class _YearlyScreenState extends State<YearlyScreen> {
  late int _year = DateTime.now().year;

  /// Wraps only the heatmap, so a shared image carries the year and the grid
  /// and nothing else — no counts, no rates, and never a note.
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<TrackerViewModel>();
    final entries = {
      for (final entry in vm.allEntries)
        if (entry.date.year == _year) entry.dateKey: entry,
    };
    final firstYear = vm.firstLoggedMonth.year;
    final thisYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yearlyTitle),
        actions: [
          ShareImageButton(
            boundaryKey: _shareKey,
            fileName: 'dont-drink-$_year',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _year > firstYear
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _year < thisYear
                      ? () => setState(() => _year++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _shareKey,
              child: AppCard(
                child: YearHeatmap(
                  year: _year,
                  entries: entries,
                  mode: vm.mode,
                  onDayTap: (date) => DayEntrySheet.show(context, date),
                ),
              ),
            ),
            if (entries.isEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.yearNoData('$_year'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _Legend(mode: vm.mode),
          ],
        ),
      ),
    );
  }
}

/// The grid itself, split out so the share capture and the tests can build it
/// without a Scaffold around it.
class YearHeatmap extends StatelessWidget {
  const YearHeatmap({
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
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat('MMM', locale);
    final today = DateOnly.today();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 31 columns plus the month label have to fit whatever width we get,
        // so the cell size follows the screen rather than the other way round.
        const labelWidth = 34.0;
        const spacing = 2.0;
        final cell =
            ((constraints.maxWidth - labelWidth) / 31) - spacing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var month = 1; month <= 12; month++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: spacing / 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        monthLabel.format(DateTime(year, month)),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (var day = 1; day <= 31; day++)
                      _Cell(
                        size: cell,
                        spacing: spacing,
                        date: day <= DateOnly.daysInMonth(DateTime(year, month))
                            ? DateTime(year, month, day)
                            : null,
                        entry: entries[
                            DateOnly.keyFor(DateTime(year, month, day))],
                        mode: mode,
                        today: today,
                        onTap: onDayTap,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.size,
    required this.spacing,
    required this.date,
    required this.entry,
    required this.mode,
    required this.today,
    required this.onTap,
  });

  final double size;
  final double spacing;

  /// Null for the 30th of February and friends — the grid is rectangular, the
  /// calendar is not.
  final DateTime? date;

  final DayEntry? entry;
  final ModeDefinition mode;
  final DateTime today;
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (date == null) {
      return SizedBox(width: size + spacing, height: size);
    }

    final isFuture = date!.isAfter(today);
    final color = entry != null
        ? entry!.level.color
        : theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: isFuture ? 0.35 : 1);

    final l10n = AppLocalizations.of(context);
    final status = isFuture
        ? l10n.a11yDayFuture
        : (entry?.level.shortLabel ?? l10n.a11yDayUnlogged);
    final dateLabel = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date!);
    final hasNote = entry?.note != null && entry!.note!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(right: spacing),
      child: Semantics(
        button: !isFuture && onTap != null,
        label: hasNote
            ? l10n.a11yDayCellWithNote(dateLabel, status)
            : l10n.a11yDayCell(dateLabel, status),
        child: GestureDetector(
          onTap: (isFuture || onTap == null) ? null : () => onTap!(date!),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: DateOnly.isSameDay(date!, today)
                  ? Border.all(color: theme.colorScheme.onSurface, width: 1)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.mode});

  final ModeDefinition mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final level in mode.levels)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(level.shortLabel, style: theme.textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
