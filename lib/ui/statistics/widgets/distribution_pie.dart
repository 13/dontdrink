import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Donut of logged days by level, with a side legend.
///
/// Tapping a slice — or its legend row — selects that level: the slice grows
/// and the hole in the middle names it and gives its count. Tapping the same
/// one again clears the selection, so the chart is never stuck in a state the
/// user has to work out how to leave.
class DistributionPie extends StatefulWidget {
  const DistributionPie({
    super.key,
    required this.counts,
    required this.levels,
  });

  final Map<TrackedLevel, int> counts;
  final List<TrackedLevel> levels;

  @override
  State<DistributionPie> createState() => _DistributionPieState();
}

class _DistributionPieState extends State<DistributionPie> {
  /// Index into the *present* levels, or null when nothing is selected.
  int? _selected;

  @override
  void didUpdateWidget(DistributionPie oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A mode switch or a cleared day can shrink the list out from under the
    // selection, the same way the motivation pager's index had to be clamped.
    if (_selected != null && _selected! >= _present().length) {
      _selected = null;
    }
  }

  List<TrackedLevel> _present() =>
      widget.levels.where((l) => (widget.counts[l] ?? 0) > 0).toList();

  void _select(int index) {
    setState(() => _selected = _selected == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.counts.values.fold(0, (a, b) => a + b);
    final present = _present();

    if (total == 0) {
      return Center(child: Text(AppLocalizations.of(context).statsNoDataYet));
    }

    final selected = _selected == null ? null : present[_selected!];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // Only a deliberate tap counts. Without this the
                      // selection flickers under every hover and drag event
                      // fl_chart reports.
                      if (event is! FlTapUpEvent) return;
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      if (index == null || index < 0) return;
                      _select(index);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < present.length; i++)
                      _section(present[i], i, total),
                  ],
                ),
              ),
              if (selected != null)
                _CentreDetail(
                  level: selected,
                  count: widget.counts[selected]!,
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < present.length; i++)
                _LegendRow(
                  level: present[i],
                  count: widget.counts[present[i]]!,
                  selected: _selected == i,
                  onTap: () => _select(i),
                ),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _section(TrackedLevel level, int index, int total) {
    final isSelected = _selected == index;
    final count = widget.counts[level]!;
    return PieChartSectionData(
      value: count.toDouble(),
      color: level.color,
      // Only the selected slice grows, so the ring keeps its shape and the
      // only thing that changes is the answer to "which one is this?".
      radius: isSelected ? 60 : 52,
      title: '${(count / total * 100).round()}%',
      titleStyle: TextStyle(
        fontSize: isSelected ? 13 : 12,
        fontWeight: FontWeight.w700,
        color: level.onColor,
      ),
    );
  }
}

/// What sits in the hole while a slice is selected.
class _CentreDetail extends StatelessWidget {
  const _CentreDetail({required this.level, required this.count});

  final TrackedLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: level.color,
              height: 1,
            ),
          ),
          Text(
            AppLocalizations.of(context).dayUnit(count),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.shortLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.level,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final TrackedLevel level;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      selected: selected,
      // The chart itself is a picture to a screen reader; the legend is what
      // actually carries the numbers, so it is the part that must speak.
      label: selected
          ? l10n.a11ySliceSelected(level.shortLabel, count)
          : l10n.a11ySlice(level.shortLabel, count),
      excludeSemantics: true,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: level.color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                level.shortLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : null,
                ),
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
