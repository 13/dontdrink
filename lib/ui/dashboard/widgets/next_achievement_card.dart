import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Shows the next achievement to earn with a progress bar toward it.
///
/// Progress is measured against the *current* streak, because badges are
/// repeatable: after a relapse the run starts over and so does the bar, even
/// for a badge that has been earned before.
class NextAchievementCard extends StatelessWidget {
  const NextAchievementCard({
    super.key,
    required this.achievement,
    required this.currentStreak,
    this.earnedCount = 0,
  });

  final Achievement achievement;
  final int currentStreak;

  /// How often this badge has already been earned, so a repeat can be framed
  /// as one.
  final int earnedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (currentStreak / achievement.dayThreshold).clamp(0.0, 1.0);
    final remaining = achievement.dayThreshold - currentStreak;

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
                    if (earnedCount > 0)
                      Text(
                        'Earned $earnedCount time${earnedCount == 1 ? '' : 's'}'
                        ' before',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
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
                ? '$remaining more ${remaining == 1 ? "day" : "days"} to earn'
                    '${earnedCount > 0 ? " it again" : " it"}'
                : 'Earned!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
