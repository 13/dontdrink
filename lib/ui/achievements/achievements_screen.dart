import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/badge_share_dialog.dart';
import 'package:dont_drink/ui/widgets/recovery_section.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                floating: true,
                title: Text(l10n.achievementsTitle),
                bottom: TabBar(
                  tabs: [
                    Tab(text: l10n.tabBadges),
                    Tab(text: l10n.tabRecovery),
                  ],
                  indicatorColor: AppColors.brand,
                  labelColor: AppColors.brand,
                  dividerColor: Colors.transparent,
                ),
              ),
            ],
            body: const TabBarView(
              children: [
                _BadgesTab(),
                _RecoveryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badges tab ───────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final statuses = vm.achievements;
    final unlockedCount = statuses.where((s) => s.unlocked).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ProgressHeader(
          unlocked: unlockedCount,
          total: statuses.length,
          totalEarns: vm.totalEarns,
        ),
        const SizedBox(height: 16),
        for (final status in statuses)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AchievementTile(status: status),
          ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.unlocked,
    required this.total,
    required this.totalEarns,
  });

  final int unlocked;
  final int total;

  /// Badges earned overall, counting every repeat.
  final int totalEarns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
        ),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.badgesUnlockedOf(unlocked, total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (totalEarns > unlocked) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.badgesEarnedTotal(totalEarns),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : unlocked / total,
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

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = status.achievement;
    final unlocked = status.unlocked;
    final l10n = AppLocalizations.of(context);
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toString());

    final card = AppCard(
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.brand.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? Text(a.emoji, style: const TextStyle(fontSize: 28))
                  : Icon(Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (a.isLegendary) ...[
                        const SizedBox(width: 6),
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                      ],
                      if (status.isRepeated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.badgeTimesChip(status.earnedCount),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.badgeDayThreshold(a.dayThreshold),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (status.firstEarnedOn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      status.isRepeated
                          ? l10n.badgeFirstAndLast(
                              dateFormat.format(status.firstEarnedOn!),
                              dateFormat.format(status.lastEarnedOn!),
                            )
                          : l10n.badgeEarnedOn(
                              dateFormat.format(status.firstEarnedOn!)),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.check_circle, color: AppColors.green),
          ],
        ),
      ),
    );

    // Only an earned badge can be shared: a card for something you have not
    // done would be a strange thing to hand someone.
    if (!unlocked) {
      return Semantics(
        label: l10n.a11yBadgeLocked(a.title),
        excludeSemantics: true,
        child: card,
      );
    }

    return Semantics(
      button: true,
      label: l10n.a11yBadgeEarned(a.title, status.earnedCount),
      excludeSemantics: true,
      child: InkWell(
      onTap: () => BadgeShareDialog.show(
        context,
        status: status,
        modeName: context.read<TrackerViewModel>().mode.name,
      ),
      borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}

// ── Recovery tab ─────────────────────────────────────────────────────────────

class _RecoveryTab extends StatelessWidget {
  const _RecoveryTab();

  @override
  Widget build(BuildContext context) {
    final hasRecovery =
        context.watch<TrackerViewModel>().mode.content.hasRecovery;

    if (!hasRecovery) {
      return const _RecoveryEmptyState();
    }

    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: RecoverySection(),
    );
  }
}

class _RecoveryEmptyState extends StatelessWidget {
  const _RecoveryEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_outlined,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).recoveryNoTimelineForMode,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
