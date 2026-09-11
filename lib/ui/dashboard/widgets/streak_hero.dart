import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Compact streak counter shown at the top of the dashboard.
class StreakHero extends StatelessWidget {
  const StreakHero({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.cleanDayLabel,
  });

  final int currentStreak;
  final int longestStreak;
  final String cleanDayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasStreak = currentStreak > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: hasStreak
              ? [AppColors.green, const Color(0xFF2E9E83)]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasStreak ? l10n.streakCurrent : l10n.streakStart,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: hasStreak
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$currentStreak',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: hasStreak
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.dayUnit(currentStreak),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: hasStreak
                          ? Colors.white70
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (hasStreak)
                Text(
                  l10n.streakOf(cleanDayLabel.toLowerCase()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (hasStreak ? Colors.white : theme.colorScheme.primary)
                  .withValues(alpha: hasStreak ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '🏆',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '$longestStreak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: hasStreak ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.streakBest,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasStreak
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
