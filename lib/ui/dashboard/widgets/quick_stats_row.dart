import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Two-by-two grid of headline statistics.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key, required this.stats});

  final TrackerStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatData(
        icon: Icons.percent,
        color: AppColors.green,
        value: '${stats.alcoholFreePercentage.toStringAsFixed(0)}%',
        label: 'Alcohol-free',
      ),
      _StatData(
        icon: Icons.local_fire_department,
        color: AppColors.orange,
        value: '${stats.currentStreak}',
        label: 'Current streak',
      ),
      _StatData(
        icon: Icons.emoji_events,
        color: AppColors.yellow,
        value: '${stats.longestStreak}',
        label: 'Longest streak',
      ),
      _StatData(
        icon: Icons.event_available,
        color: AppColors.brand,
        value: '${stats.totalAlcoholFreeDays}',
        label: 'Total free days',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [for (final t in tiles) _StatTile(data: t)],
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: data.color, size: 22),
          const Spacer(),
          Text(
            data.value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            data.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
