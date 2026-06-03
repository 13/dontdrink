import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/static/motivation_data.dart';
import 'package:dont_drink/ui/dashboard/widgets/month_summary_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/next_achievement_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/streak_hero.dart';
import 'package:dont_drink/ui/dashboard/widgets/quick_stats_row.dart';
import 'package:dont_drink/ui/settings/settings_screen.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
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

    final today = DateOnly.today();
    final todayEntry = vm.entryFor(today);
    // Motivation line rotates daily based on day-of-year.
    final motivation = kMotivations[
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
            kMotivations.length];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text("Don't Drink"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  StreakHero(
                    currentStreak: vm.stats.currentStreak,
                    longestStreak: vm.stats.longestStreak,
                  ),
                  const SizedBox(height: 16),
                  _TodayCard(
                    todayLevel: todayEntry?.level,
                    onTap: () => DayEntrySheet.show(context, today),
                  ),
                  const SizedBox(height: 16),
                  _MotivationBanner(text: motivation),
                  const SizedBox(height: 24),
                  const SectionHeader('Quick Stats'),
                  QuickStatsRow(stats: vm.stats),
                  const SizedBox(height: 24),
                  const SectionHeader('This Month'),
                  MonthSummaryCard(counts: vm.monthCounts(today)),
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

/// Prominent call-to-action: today's logged status, or a prompt to log it.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todayLevel, required this.onTap});

  final DrinkLevel? todayLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logged = todayLevel != null;
    return AppCard(
      onTap: onTap,
      color: logged
          ? todayLevel!.color.withValues(alpha: 0.14)
          : AppColors.brand.withValues(alpha: 0.12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: logged ? todayLevel!.color : AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              logged ? Icons.check : Icons.add,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logged ? 'Today logged' : 'Log today',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  logged ? todayLevel!.label : 'How did today go?',
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

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
