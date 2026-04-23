import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement.dart' as achievement_models;
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/achievement_preview_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/task_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, TaskProvider, SettingsProvider>(
      builder: (context, auth, tasks, settings, _) {
        final focusGoals = settings.settings.focusGoals;
        final recentTasks = tasks.tasks.take(3).toList();
        // All achievements in the list are unlocked (they only exist if awarded)
        final unlockedAchievements = tasks.achievements.cast<achievement_models.Achievement>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi ${auth.user?.name ?? 'there'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep building momentum with meaningful goals, visible progress, and simple daily wins.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: focusGoals
                          .map(
                            (goal) => Chip(
                              backgroundColor: const Color.fromARGB(255, 5, 49, 71).withValues(alpha: 0.16),
                              label: Text(goal, style: const TextStyle(color: Colors.white)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Points',
                      value: tasks.totalPoints.toString(),
                      icon: Icons.stars_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Level',
                      value: tasks.currentLevel.toString(),
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Streak',
                      value: '${tasks.currentStreak}d',
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Completion',
                      value: '${(tasks.completionRate * 100).round()}%',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Todays focus',
                child: Column(
                  children: recentTasks.isEmpty
                      ? [
                          const Text('No tasks yet. Add one to start building momentum.'),
                        ]
                      : recentTasks.map((task) => TaskTile(task: task)).toList(),
                ),
              ),
              const SizedBox(height: 18),
              AchievementPreviewCard(
                achievements: unlockedAchievements,
              ),
            ],
          ),
        );
      },
    );
  }
}
