import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Two-by-two grid of headline statistics.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.stats,
    required this.cleanDayLabel,
  });

  final TrackerStats stats;
  final String cleanDayLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = [
      _StatData(
        icon: Icons.percent,
        color: AppColors.green,
        value: '${stats.cleanDayPercentage.toStringAsFixed(0)}%',
        label: cleanDayLabel,
      ),
      _StatData(
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF9800),
        value: '${stats.currentStreak}',
        label: l10n.statCurrentStreak,
      ),
      _StatData(
        icon: Icons.emoji_events,
        color: const Color(0xFFFFC107),
        value: '${stats.longestStreak}',
        label: l10n.statLongestStreak,
      ),
      _StatData(
        icon: Icons.event_available,
        color: AppColors.brand,
        value: '${stats.totalCleanDays}',
        label: l10n.statTotalCleanDays,
      ),
    ];

    // Two rows of two, each row as tall as its taller tile. Not a grid with
    // a fixed aspect ratio: that sets the height from the width, and with
    // large text the labels need more than the width allows.
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StatTile(data: tiles[i])),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(data: tiles[i + 1])),
              ],
            ),
          ),
        ],
      ],
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
        children: [
          Icon(data.icon, color: data.color, size: 22),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
