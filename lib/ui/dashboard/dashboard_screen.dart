import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/ui/calendar/widgets/month_grid.dart';
import 'package:dont_drink/ui/dashboard/widgets/next_achievement_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/streak_hero.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = DateOnly.today();
    final todayEntry = vm.entryFor(today);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: Text("Don't Drink"),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  StreakHero(
                    currentStreak: vm.stats.currentStreak,
                    longestStreak: vm.stats.longestStreak,
                  ),
                  if (todayEntry == null) ...[
                    const SizedBox(height: 16),
                    _TodayCard(
                      onTap: () => DayEntrySheet.show(context, today),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _MonthCalendarSection(),
                  if (vm.nextAchievement != null) ...[
                    const SizedBox(height: 24),
                    const SectionHeader('Next Achievement'),
                    NextAchievementCard(
                      achievement: vm.nextAchievement!,
                      longestStreak: vm.stats.longestStreak,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      color: AppColors.brand.withValues(alpha: 0.12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log today',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'How did today go?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── Month calendar section ────────────────────────────────────────────────────

class _MonthCalendarSection extends StatelessWidget {
  const _MonthCalendarSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final theme = Theme.of(context);
    final month = vm.visibleMonth;
    final entries = vm.entriesForMonth(month);
    final isCurrentMonth = DateOnly.isSameDay(
      DateOnly.firstOfMonth(month),
      DateOnly.firstOfMonth(DateTime.now()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: vm.previousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM y').format(month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              onPressed: isCurrentMonth ? null : vm.nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          child: MonthGrid(
            month: month,
            entries: entries,
            onDayTap: (date) => DayEntrySheet.show(context, date),
          ),
        ),
      ],
    );
  }
}
