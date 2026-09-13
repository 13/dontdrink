import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/ui/calendar/widgets/month_grid.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/month_label_button.dart';
import 'package:dont_drink/ui/widgets/share_image_button.dart';
import 'package:dont_drink/ui/widgets/shareable_palette.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Identifies the boundary the share button photographs. Held by the state
  /// so it survives rebuilds — a key rebuilt each frame would point at a
  /// boundary that no longer exists by the time the capture runs.
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final month = vm.visibleMonth;
    final entries = vm.entriesForMonth(month);
    final counts = vm.monthCounts(month);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(AppLocalizations.of(context).calendarTitle),
              actions: [
                ShareImageButton(
                  boundaryKey: _shareKey,
                  fileName: 'dont-drink-${DateFormat('yyyy-MM').format(month)}',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  _MonthHeader(
                    month: month,
                    onPrev: vm.previousMonth,
                    onNext: vm.nextMonth,
                  ),
                  const SizedBox(height: 12),
                  // Only the month and its grid are captured: a shared image
                  // shows the shape of the month, not the statistics under it
                  // and never a note.
                  RepaintBoundary(
                    key: _shareKey,
                    child: ShareablePalette(
                      child: AppCard(
                        child: Builder(
                          builder: (context) => Column(
                            children: [
                              MonthGrid(
                                month: month,
                                entries: entries,
                                onDayTap: (date) =>
                                    DayEntrySheet.show(context, date),
                              ),
                              const SizedBox(height: 10),
                              // A caption rather than a heading: the header
                              // above already names the month on screen, but a
                              // shared image has to carry its own period. The
                              // Builder picks up the fixed share palette, so
                              // the caption is legible in the picture too.
                              Text(
                                DateFormat(
                                        'MMMM y',
                                        Localizations.localeOf(context)
                                            .toString())
                                    .format(month),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Legend(levels: vm.mode.levels),
                  const SizedBox(height: 24),
                  SectionHeader(
                    AppLocalizations.of(context).calendarMonthStatistics(
                      DateFormat('MMMM', Localizations.localeOf(context).toString())
                          .format(month),
                    ),
                  ),
                  _MonthStats(counts: counts, mode: vm.mode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentMonth = DateOnly.isSameDay(
      DateOnly.firstOfMonth(month),
      DateOnly.firstOfMonth(DateTime.now()),
    );
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: MonthLabelButton(
            month: month,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(
          // Don't allow navigating past the current month.
          onPressed: isCurrentMonth ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.levels});

  final List<TrackedLevel> levels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final level in levels)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: level.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
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

class _MonthStats extends StatelessWidget {
  const _MonthStats({
    required this.counts,
    required this.mode,
  });

  final Map<TrackedLevel, int> counts;
  final ModeDefinition mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (a, b) => a + b);
    final clean = counts[mode.cleanLevel] ?? 0;
    final pct = total == 0 ? 0 : (clean / total * 100).round();

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                  value: '$total',
                  label: AppLocalizations.of(context).calendarLogged),
              _Stat(value: '$clean', label: mode.cleanDayLabel),
              _Stat(
                  value: '$pct%',
                  label: AppLocalizations.of(context).calendarCleanRate),
            ],
          ),
          const Divider(height: 28),
          for (final level in mode.levels)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: level.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(level.label)),
                  Text('${counts[level] ?? 0}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
