import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/ui/calendar/calendar_screen.dart';
import 'package:dont_drink/ui/calendar/widgets/month_grid.dart';
import 'package:dont_drink/ui/dashboard/widgets/next_achievement_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/streak_hero.dart';
import 'package:dont_drink/ui/shell/home_shell.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/ui/widgets/mode_switcher.dart';
import 'package:dont_drink/ui/widgets/month_label_button.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The day being lived, which before 04:00 is still yesterday — logging a
    // night out at 01:00 means the night that just happened.
    final today = DateOnly.trackingDay();
    final todayEntry = vm.entryFor(today);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: ModeSwitcher(
                onManageModes: () =>
                    HomeShellController.instance.openSettings(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  if (vm.allEntries.isEmpty) ...[
                    const _WelcomeCard(),
                    const SizedBox(height: 16),
                  ],
                  StreakHero(
                    currentStreak: vm.stats.currentStreak,
                    longestStreak: vm.stats.longestStreak,
                    cleanDayLabel: vm.mode.cleanDayLabel,
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
                    SectionHeader(
                        AppLocalizations.of(context).dashboardNextAchievement),
                    NextAchievementCard(
                      achievement: vm.nextAchievement!,
                      currentStreak: vm.stats.currentStreak,
                      earnedCount: vm.achievements
                          .firstWhere(
                              (s) => s.achievement.id == vm.nextAchievement!.id)
                          .earnedCount,
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
                  AppLocalizations.of(context).dashboardLogToday,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  AppLocalizations.of(context).dashboardHowDidTodayGo,
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
              child: MonthLabelButton(
                month: month,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              onPressed: isCurrentMonth ? null : vm.nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
            // The dashboard shows the month; the calendar screen shows the
            // same month with its legend and totals. Rather than grow this
            // section into a second calendar, point at the one that exists.
            IconButton(
              tooltip: AppLocalizations.of(context).openCalendar,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CalendarScreen(),
                ),
              ),
              icon: const Icon(Icons.open_in_full, size: 18),
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

/// Shown on the dashboard until the first day is logged.
///
/// It disappears on its own the moment there is any history, so there is no
/// "seen" flag to persist, nothing to dismiss, and no state that can strand
/// someone with a welcome card they cannot get rid of.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcomeTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.welcomeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.welcomePrivacy,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
