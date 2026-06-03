import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// The large central streak counter at the top of the dashboard.
class StreakHero extends StatelessWidget {
  const StreakHero({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = currentStreak > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: hasStreak
              ? [AppColors.green, Color(0xFF2E9E83)]
              : [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            hasStreak ? '🔥 Current Streak' : 'Start your streak',
            style: theme.textTheme.titleMedium?.copyWith(
              color: hasStreak ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currentStreak',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 84,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: hasStreak ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  currentStreak == 1 ? 'day' : 'days',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: hasStreak
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasStreak ? 'alcohol-free' : 'Log an alcohol-free day to begin',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: hasStreak ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (hasStreak ? Colors.white : theme.colorScheme.primary)
                  .withValues(alpha: hasStreak ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Longest streak: $longestStreak ${longestStreak == 1 ? "day" : "days"}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: hasStreak ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
