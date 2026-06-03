import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/ui/facts/facts_screen.dart';
import 'package:dont_drink/ui/motivation/motivation_screen.dart';
import 'package:dont_drink/ui/recovery/recovery_screen.dart';
import 'package:dont_drink/ui/settings/settings_screen.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Hub for the secondary screens that don't warrant a primary tab.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.timeline,
        color: AppColors.brand,
        title: 'Recovery Timeline',
        subtitle: 'What your body gains over time',
        builder: (_) => const RecoveryScreen(),
      ),
      _MoreItem(
        icon: Icons.lightbulb_outline,
        color: AppColors.orange,
        title: 'Facts',
        subtitle: 'Harms of alcohol & benefits of quitting',
        builder: (_) => const FactsScreen(),
      ),
      _MoreItem(
        icon: Icons.favorite_outline,
        color: AppColors.red,
        title: 'Motivation',
        subtitle: 'A boost when you need it',
        builder: (_) => const MotivationScreen(),
      ),
      _MoreItem(
        icon: Icons.settings_outlined,
        color: AppColors.green,
        title: 'Settings',
        subtitle: 'Theme, reminders & privacy',
        builder: (_) => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(floating: true, title: Text('More')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: item.builder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    item.subtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}
