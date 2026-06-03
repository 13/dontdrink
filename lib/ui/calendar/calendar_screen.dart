import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/ui/calendar/widgets/month_grid.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

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
            const SliverAppBar(floating: true, title: Text('Calendar')),
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
                  AppCard(
                    child: MonthGrid(
                      month: month,
                      entries: entries,
                      onDayTap: (date) => DayEntrySheet.show(context, date),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _Legend(),
                  const SizedBox(height: 24),
                  SectionHeader(
                      '${DateFormat('MMMM').format(month)} Statistics'),
                  _MonthStats(counts: counts),
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
          child: Text(
            DateFormat('MMMM y').format(month),
            textAlign: TextAlign.center,
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
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final level in DrinkLevel.values)
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
  const _MonthStats({required this.counts});

  final Map<DrinkLevel, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (a, b) => a + b);
    final free = counts[DrinkLevel.none] ?? 0;
    final pct = total == 0 ? 0 : (free / total * 100).round();

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(value: '$total', label: 'Logged'),
              _Stat(value: '$free', label: 'Alcohol-free'),
              _Stat(value: '$pct%', label: 'Free rate'),
            ],
          ),
          const Divider(height: 28),
          for (final level in DrinkLevel.values)
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
