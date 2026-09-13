import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:dont_drink/ui/dashboard/widgets/month_summary_card.dart';
import 'package:dont_drink/ui/dashboard/widgets/quick_stats_row.dart';
import 'package:dont_drink/ui/statistics/widgets/distribution_pie.dart';
import 'package:dont_drink/ui/statistics/widgets/monthly_bar_chart.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackerViewModel>();
    final mode = vm.mode;
    final l10n = AppLocalizations.of(context);
    final stats = vm.stats;
    const service = StatsService();
    final monthly = service.recentMonths(vm.allEntries, count: 6);
    final hasData = stats.totalLoggedDays > 0;
    final today = DateOnly.today();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(floating: true, title: Text(l10n.statsTitle)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  SectionHeader(l10n.statsQuickStats),
                  QuickStatsRow(stats: stats, cleanDayLabel: mode.cleanDayLabel),
                  const SizedBox(height: 24),
                  // The month the dashboard and calendar are showing, not
                  // whatever month it is today: stepping back to August and
                  // finding September's numbers here was simply wrong.
                  SectionHeader(
                    DateOnly.isSameDay(
                      DateOnly.firstOfMonth(vm.visibleMonth),
                      DateOnly.firstOfMonth(today),
                    )
                        ? l10n.statsThisMonth
                        : l10n.statsMonthOf(
                            DateFormat.yMMMM(
                                    Localizations.localeOf(context).toString())
                                .format(vm.visibleMonth),
                          ),
                  ),
                  MonthSummaryCard(
                    counts: vm.monthCounts(vm.visibleMonth),
                    levels: vm.mode.levels,
                  ),
                  const SizedBox(height: 24),
                  if (!hasData)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            l10n.statsEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SectionHeader(l10n.statsDaysPerMonth(mode.cleanDayLabel)),
                    AppCard(
                      child: SizedBox(
                        height: 220,
                        child: MonthlyBarChart(data: monthly),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(l10n.statsDayDistribution),
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
                    SectionHeader(l10n.statsOverview),
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
    final l10n = AppLocalizations.of(context);
    final bestMonth = monthly.isEmpty
        ? null
        : monthly.reduce((a, b) => a.cleanDays >= b.cleanDays ? a : b);

    return AppCard(
      child: Column(
        children: [
          _row(context, l10n.statLongestStreak,
              l10n.statsDaysValue(longestStreak)),
          const Divider(height: 24),
          _row(context, l10n.statsRateOf(cleanDayLabel),
              '${cleanDayPercentage.toStringAsFixed(0)}%'),
          const Divider(height: 24),
          _row(context, l10n.statsTotalDaysLogged, '$totalLogged'),
          if (bestMonth != null && bestMonth.cleanDays > 0) ...[
            const Divider(height: 24),
            _row(
              context,
              l10n.statsBestMonth,
              l10n.statsBestMonthValue(
                _monthName(context, bestMonth.month),
                bestMonth.cleanDays,
              ),
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

  /// Short month name in the active language.
  static String _monthName(BuildContext context, DateTime month) =>
      DateFormat.MMM(Localizations.localeOf(context).toString())
          .format(month);
}
