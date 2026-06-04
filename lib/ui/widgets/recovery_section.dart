import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full recovery timeline section — reused in both Stats and Awards screens.
class RecoverySection extends StatelessWidget {
  const RecoverySection({super.key});

  @override
  Widget build(BuildContext context) {
    final streakHours =
        context.select<TrackerViewModel, int>((vm) => vm.stats.currentStreak) *
            24;
    final byTier = kRecoveryByTier;
    final totalMilestones = kRecoveryTimeline.length;
    final reachedCount =
        kRecoveryTimeline.where((m) => streakHours >= m.afterHours).length;

    return Column(
      children: [
        RecoveryProgressHeader(reached: reachedCount, total: totalMilestones),
        const SizedBox(height: 16),
        for (final tier in RecoveryTier.values) ...[
          RecoveryTierSection(
            tier: tier,
            milestones: byTier[tier]!,
            streakHours: streakHours,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class RecoveryProgressHeader extends StatelessWidget {
  const RecoveryProgressHeader({
    super.key,
    required this.reached,
    required this.total,
  });

  final int reached;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$reached of $total milestones reached',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : reached / total,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
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

class RecoveryTierSection extends StatelessWidget {
  const RecoveryTierSection({
    super.key,
    required this.tier,
    required this.milestones,
    required this.streakHours,
  });

  final RecoveryTier tier;
  final List<RecoveryMilestone> milestones;
  final int streakHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierReached =
        milestones.where((m) => streakHours >= m.afterHours).length;
    final tierTotal = milestones.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                tier.label.split(' ').first,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tier.label.replaceFirst(RegExp(r'^[^ ]+ '), ''),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tier.color,
                  ),
                ),
              ),
              Text(
                '$tierReached/$tierTotal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final milestone in milestones)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecoveryMilestoneTile(
              milestone: milestone,
              reached: streakHours >= milestone.afterHours,
            ),
          ),
      ],
    );
  }
}

class RecoveryMilestoneTile extends StatelessWidget {
  const RecoveryMilestoneTile({
    super.key,
    required this.milestone,
    required this.reached,
  });

  final RecoveryMilestone milestone;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = milestone.tier.color;

    return AppCard(
      child: Opacity(
        opacity: reached ? 1.0 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: reached
                    ? tierColor.withValues(alpha: 0.18)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached ? tierColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                reached ? Icons.check : milestone.icon,
                color:
                    reached ? tierColor : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          milestone.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          milestone.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: reached ? tierColor : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.benefits.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
