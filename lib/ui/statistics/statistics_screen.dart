import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:dont_drink/ui/dashboard/widgets/month_summary_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/quick_stats_row.dart';
import 'package:dont_drink/ui/statistics/widgets/distribution_pie.dart';
import 'package:dont_drink/ui/statistics/widgets/monthly_bar_chart.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final mode = vm.mode;
    final stats = vm.stats;
    const service = StatsService();
    final monthly = service.recentMonths(vm.allEntries, count: 6);
    final hasData = stats.totalLoggedDays > 0;
    final today = DateOnly.today();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(floating: true, title: Text('Stats')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  const SectionHeader('Quick Stats'),
                  QuickStatsRow(stats: stats, cleanDayLabel: mode.cleanDayLabel),
                  const SizedBox(height: 24),
                  const SectionHeader('This Month'),
                  MonthSummaryCard(
                    counts: vm.monthCounts(today),
                    levels: vm.mode.levels,
                  ),
                  const SizedBox(height: 24),
                  if (!hasData)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Log a few days to see your statistics here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SectionHeader('${mode.cleanDayLabel} Days per Month'),
                    AppCard(
                      child: SizedBox(
                        height: 220,
                        child: MonthlyBarChart(data: monthly),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader('Day Distribution'),
                    AppCard(
                      child: SizedBox(
                        height: 220,
                        child: DistributionPie(
                          counts: stats.levelCounts,
                          levels: vm.mode.levels,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader('Overview'),
                    _OverviewCard(
                      monthly: monthly,
                      longestStreak: stats.longestStreak,
                      cleanDayPercentage: stats.cleanDayPercentage,
                      totalLogged: stats.totalLoggedDays,
                      cleanDayLabel: mode.cleanDayLabel,
                    ),
                    const SizedBox(height: 24),
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.monthly,
    required this.longestStreak,
    required this.cleanDayPercentage,
    required this.totalLogged,
    required this.cleanDayLabel,
  });

  final List<MonthlyTotals> monthly;
  final int longestStreak;
  final double cleanDayPercentage;
  final int totalLogged;
  final String cleanDayLabel;

  @override
  Widget build(BuildContext context) {
    final bestMonth = monthly.isEmpty
        ? null
        : monthly.reduce((a, b) => a.cleanDays >= b.cleanDays ? a : b);

    return AppCard(
      child: Column(
        children: [
          _row(context, 'Longest streak', '$longestStreak days'),
          const Divider(height: 24),
          _row(context, '$cleanDayLabel rate',
              '${cleanDayPercentage.toStringAsFixed(0)}%'),
          const Divider(height: 24),
          _row(context, 'Total days logged', '$totalLogged'),
          if (bestMonth != null && bestMonth.cleanDays > 0) ...[
            const Divider(height: 24),
            _row(
              context,
              'Best month',
              '${_monthName(bestMonth.month.month)} (${bestMonth.cleanDays} clean)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  static String _monthName(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}
