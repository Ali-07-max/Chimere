import 'package:flutter/material.dart';

import '../achievements/achievements_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';
import 'dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TasksScreen(),
    ProgressScreen(),
    AchievementsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_rtl), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Awards'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
