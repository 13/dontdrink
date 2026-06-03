import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Breakdown of the current month's logged days by drink level, with a
/// proportional bar across the top.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key, required this.counts});

  final Map<DrinkLevel, int> counts;

  int get _total => counts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No days logged this month yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final level in DrinkLevel.values)
                      if ((counts[level] ?? 0) > 0)
                        Expanded(
                          flex: counts[level]!,
                          child: Container(color: level.color),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final level in DrinkLevel.values)
            _LevelRow(level: level, count: counts[level] ?? 0),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.count});

  final DrinkLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(level.label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '$count ${count == 1 ? "day" : "days"}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
