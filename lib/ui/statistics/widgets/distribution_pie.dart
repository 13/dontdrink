import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Pie chart of logged days by level, with a side legend.
class DistributionPie extends StatelessWidget {
  const DistributionPie({
    super.key,
    required this.counts,
    required this.levels,
  });

  final Map<TrackedLevel, int> counts;
  final List<TrackedLevel> levels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (a, b) => a + b);
    final present = levels.where((l) => (counts[l] ?? 0) > 0).toList();

    if (total == 0) {
      return Center(
          child: Text(AppLocalizations.of(context).statsNoDataYet));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final level in present)
                  PieChartSectionData(
                    value: counts[level]!.toDouble(),
                    color: level.color,
                    radius: 52,
                    title:
                        '${(counts[level]! / total * 100).round()}%',
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: level.onColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final level in present)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: level.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          level.shortLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${counts[level]}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
