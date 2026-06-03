import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = context.select<TrackerViewModel, int>(
        (vm) => vm.stats.currentStreak);
    final streakHours = streak * 24;
    final byTier = kRecoveryByTier;

    // Flat list of items to render: tier header then its milestones.
    final items = <_ListItem>[];
    for (final tier in RecoveryTier.values) {
      final milestones = byTier[tier]!;
      items.add(_TierHeaderItem(tier));
      for (int i = 0; i < milestones.length; i++) {
        final isLastInTier = i == milestones.length - 1;
        final isLastOverall =
            tier == RecoveryTier.diamond && isLastInTier;
        items.add(_MilestoneItem(
          milestone: milestones[i],
          reached: streakHours >= milestones[i].afterHours,
          isLastInTier: isLastInTier,
          isLastOverall: isLastOverall,
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Timeline')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              streak > 0
                  ? "You're $streak ${streak == 1 ? 'day' : 'days'} into recovery. "
                      "Here's what your body is doing."
                  : 'Start an alcohol-free streak to begin your recovery journey.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final item in items)
              switch (item) {
                _TierHeaderItem h => _TierBanner(tier: h.tier),
                _MilestoneItem m => _TimelineItem(
                    milestone: m.milestone,
                    reached: m.reached,
                    isLastInTier: m.isLastInTier,
                    isLastOverall: m.isLastOverall,
                  ),
              },
          ],
        ),
      ),
    );
  }
}

// ── Internal list-item types ────────────────────────────────────────────────

sealed class _ListItem {}

class _TierHeaderItem extends _ListItem {
  _TierHeaderItem(this.tier);
  final RecoveryTier tier;
}

class _MilestoneItem extends _ListItem {
  _MilestoneItem({
    required this.milestone,
    required this.reached,
    required this.isLastInTier,
    required this.isLastOverall,
  });
  final RecoveryMilestone milestone;
  final bool reached;
  final bool isLastInTier;
  final bool isLastOverall;
}

// ── Tier banner ──────────────────────────────────────────────────────────────

class _TierBanner extends StatelessWidget {
  const _TierBanner({required this.tier});

  final RecoveryTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tier.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  tier.label.split(' ').first, // just the emoji
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // strip the emoji prefix from label
                    tier.label.replaceFirst(RegExp(r'^[^ ]+ '), ''),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tier.color,
                    ),
                  ),
                  Text(
                    tier.subtitle,
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

// ── Timeline item ────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.milestone,
    required this.reached,
    required this.isLastInTier,
    required this.isLastOverall,
  });

  final RecoveryMilestone milestone;
  final bool reached;
  final bool isLastInTier;
  final bool isLastOverall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = milestone.tier.color;
    final nodeColor = reached ? tierColor : theme.colorScheme.surfaceContainerHighest;
    final iconColor = reached ? Colors.white : theme.colorScheme.outline;

    // The connector is dashed / faded between tiers, solid within.
    final lineColor = reached
        ? tierColor.withValues(alpha: 0.5)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left spine: node + vertical connector
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reached
                          ? tierColor
                          : theme.colorScheme.outlineVariant,
                      width: reached ? 0 : 1.5,
                    ),
                  ),
                  child: Icon(
                    reached ? Icons.check : milestone.icon,
                    color: reached ? Colors.white : iconColor,
                    size: 22,
                  ),
                ),
                if (!isLastOverall)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.only(
                        top: 4,
                        bottom: isLastInTier ? 0 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLastOverall ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: reached ? tierColor : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final benefit in milestone.benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Icon(Icons.circle,
                                size: 5,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
