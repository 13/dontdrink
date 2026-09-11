import 'package:dont_drink/ui/achievements/achievements_screen.dart';
import 'package:dont_drink/ui/dashboard/dashboard_screen.dart';
import 'package:dont_drink/ui/settings/settings_screen.dart';
import 'package:dont_drink/ui/statistics/statistics_screen.dart';
import 'package:flutter/material.dart';

/// Lets a descendant jump to one of the shell's tabs — used by the mode
/// switcher's "Manage modes…" row.
class HomeShellController {
  HomeShellController._();
  static final instance = HomeShellController._();

  void Function(int index)? _select;

  /// Index 3 is the Settings tab.
  static const int settingsTab = 3;

  void selectTab(int index) => _select?.call(index);
}

/// Root scaffold hosting the primary tabs via a [NavigationBar].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    HomeShellController.instance._select =
        (i) => setState(() => _index = i);
  }

  @override
  void dispose() {
    HomeShellController.instance._select = null;
    super.dispose();
  }

  static const _tabs = <Widget>[
    DashboardScreen(),
    AchievementsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Awards',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
