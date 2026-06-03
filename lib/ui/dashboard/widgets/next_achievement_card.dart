import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Shows the next achievement to unlock with a progress bar toward it.
class NextAchievementCard extends StatelessWidget {
  const NextAchievementCard({
    super.key,
    required this.achievement,
    required this.longestStreak,
  });

  final Achievement achievement;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (longestStreak / achievement.dayThreshold).clamp(0.0, 1.0);
    final remaining = achievement.dayThreshold - longestStreak;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? '$remaining more ${remaining == 1 ? "day" : "days"} to unlock'
                : 'Unlocked!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
