import 'package:uuid/uuid.dart';
import '../models/achievement.dart';
import '../models/app_user.dart';
import '../models/task_item.dart';

class GamificationService {
  static const uuid = Uuid();

  // ==================== POINTS CALCULATION ====================

  /// Calculate points for completing a task based on priority and other factors
  static int calculateTaskPoints(
    TaskItem task, {
    bool onStreak = false,
  }) {
    int basePoints = task.priority.points;
    
    // Bonus for completing on the due date
    if (task.isDueToday && !task.isOverdue) {
      basePoints = (basePoints * 1.25).toInt();
    }
    
    // Bonus for streak
    if (onStreak) {
      basePoints = (basePoints * 1.1).toInt();
    }

    return basePoints;
  }

  /// Calculate total points from all completed tasks
  static int totalPoints(List<TaskItem> tasks) {
    return tasks
        .where((task) => task.isCompleted)
        .fold<int>(0, (sum, task) => sum + task.pointsAwarded);
  }

  // ==================== LEVEL SYSTEM ====================

  /// Calculate level from total points
  static int levelFromPoints(int points) {
    if (points < 1000) return 1;
    if (points < 3000) return 2;
    if (points < 6000) return 3;
    if (points < 10000) return 4;
    if (points < 15000) return 5;
    if (points < 21000) return 6;
    if (points < 28000) return 7;
    if (points < 36000) return 8;
    if (points < 45000) return 9;
    return 10;
  }

  /// Get points for next level
  static int pointsForNextLevel(int currentLevel) {
    return (currentLevel + 1) * 1000;
  }

  /// Get progress towards next level
  static double getLevelProgress(int currentPoints) {
    final currentLevel = levelFromPoints(currentPoints);
    final nextLevelThreshold = pointsForNextLevel(currentLevel);
    final currentLevelThreshold = currentLevel * 1000;
    
    final progress = (currentPoints - currentLevelThreshold) /
        (nextLevelThreshold - currentLevelThreshold);
    return progress.clamp(0.0, 1.0);
  }

  // ==================== STREAK CALCULATION ====================

  /// Calculate current streak from completion dates
  static int currentStreak(List<TaskItem> tasks) {
    final completionDates = tasks
        .where((task) => task.completedAt != null)
        .map((task) => DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completionDates.isEmpty) return 0;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));

    if (completionDates.first != normalizedToday &&
        completionDates.first != yesterday) {
      return 0;
    }

    var streak = 1;
    for (var i = 1; i < completionDates.length; i++) {
      final previous = completionDates[i - 1];
      final current = completionDates[i];
      if (previous.difference(current).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get longest streak
  static int longestStreak(List<TaskItem> tasks) {
    final completionDates = tasks
        .where((task) => task.completedAt != null)
        .map((task) => DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completionDates.isEmpty) return 0;

    var longestStreak = 1;
    var currentStreak = 1;

    for (var i = 1; i < completionDates.length; i++) {
      final previous = completionDates[i - 1];
      final current = completionDates[i];
      if (previous.difference(current).inDays == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  // ==================== COMPLETION METRICS ====================

  /// Calculate completion rate
  static double completionRate(List<TaskItem> tasks) {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  /// Get category breakdown
  static Map<String, int> categoryBreakdown(List<TaskItem> tasks) {
    final breakdown = <String, int>{};
    for (final task in tasks.where((task) => task.isCompleted)) {
      breakdown.update(task.category.label, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return breakdown;
  }

  /// Get weekly completion breakdown
  static List<int> weeklyCompletions(List<TaskItem> tasks) {
    final now = DateTime.now();
    final results = List<int>.filled(7, 0);

    for (final task in tasks.where((task) => task.completedAt != null)) {
      final completed = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      for (var i = 6; i >= 0; i--) {
        final day =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        if (completed == day) {
          results[6 - i] = results[6 - i] + 1;
          break;
        }
      }
    }

    return results;
  }

  // ==================== BADGE LOGIC ====================

  /// Check which badges should be awarded
  static List<BadgeType> checkBadgesForCompletion(
    AppUser user,
    List<TaskItem> allTasks,
  ) {
    final badgesToAward = <BadgeType>[];

    // Starter badge: Complete first task
    if (user.completedTasksCount == 1) {
      badgesToAward.add(BadgeType.starter);
    }

    // Speed runner: Complete 10 tasks
    if (user.completedTasksCount >= 10) {
      badgesToAward.add(BadgeType.speedRunner);
    }

    // Streak master: 7-day streak
    if (user.currentStreak >= 7) {
      badgesToAward.add(BadgeType.streakMaster);
    }

    // Point collector: 1000 points
    if (user.totalPoints >= 1000) {
      badgesToAward.add(BadgeType.pointCollector);
    }

    // Category expert: 20 tasks in one category
    final catBreakdown = GamificationService.categoryBreakdown(allTasks);
    if (catBreakdown.values.any((count) => count >= 20)) {
      badgesToAward.add(BadgeType.categoryExpert);
    }

    // Level milestones
    if (user.level >= 5) {
      badgesToAward.add(BadgeType.levelFive);
    }
    if (user.level >= 10) {
      badgesToAward.add(BadgeType.levelTen);
    }

    // Perfect week: All planned tasks completed for a week
    final weeklyCompletion = GamificationService.weeklyCompletions(allTasks);
    if (weeklyCompletion.where((c) => c > 0).length == 7) {
      badgesToAward.add(BadgeType.perfectWeek);
    }

    return badgesToAward;
  }

  /// Check if a badge should be removed (for streak breaks, etc.)
  static bool shouldRemoveBadge(BadgeType badge, AppUser user) {
    switch (badge) {
      case BadgeType.streakMaster:
        return user.currentStreak < 7;
      default:
        return false;
    }
  }

  // ==================== MOTIVATIONAL MESSAGES ====================

  /// Get motivational message based on user stats
  static String getMotivationalMessage(AppUser user, int todayTasksCompleted) {
    if (todayTasksCompleted == 0) {
      return 'Time to get started! Complete your first task today.';
    } else if (todayTasksCompleted == 1) {
      return 'Great start! Keep the momentum going. 🚀';
    } else if (todayTasksCompleted >= 3) {
      return "You're on fire! 🔥 Amazing productivity today!";
    } else if (user.currentStreak >= 7) {
      return "Wow! ${user.currentStreak} day streak! You're unstoppable! 💪";
    } else if (user.level >= 10) {
      return 'Legend! You\'ve reached Level ${user.level}! 👑';
    } else if (user.totalPoints >= 5000) {
      return 'Awesome! ${user.totalPoints} points collected! 💎';
    }
    return 'Keep up the great work! 💪';
  }

  /// Get streak encouragement
  static String getStreakMessage(int streak) {
    switch (streak) {
      case 0:
        return 'Start a new streak today!';
      case 1:
        return 'Day 1 of your streak! Keep it going. 🔥';
      case 3:
        return '3-day streak! You\'re building momentum! 🚀';
      case 7:
        return '🔥 Week-long streak! Incredible consistency!';
      case 14:
        return '🔥 2-week streak! You\'re unstoppable!';
      case 30:
        return '🔥 Month-long streak! LEGENDARY! 👑';
      default:
        if (streak > 30) {
          return '🔥 $streak days! ABSOLUTELY LEGENDARY! 👑';
        }
        return '🔥 $streak day streak! Keep going!';
    }
  }

  // ==================== RECOMMENDATIONS ====================

  /// Get personalized recommendations
  static List<String> getRecommendations(
    AppUser user,
    List<TaskItem> allTasks,
  ) {
    final recommendations = <String>[];

    final catBreakdown = GamificationService.categoryBreakdown(allTasks);

    // Balance categories
    if (catBreakdown.isEmpty) {
      recommendations.add('Try creating tasks in different categories!');
    } else {
      final minCategory = catBreakdown.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;
      recommendations.add('You\'re doing great! Maybe try more $minCategory tasks?');
    }

    // Streak encouragement
    if (user.currentStreak >= 5 && user.currentStreak < 7) {
      recommendations.add('Almost at a week-long streak! Keep going! 🔥');
    }

    // Level up encouragement
    final levelProgress = getLevelProgress(user.totalPoints);
    if (levelProgress > 0.7) {
      recommendations.add('You\'re close to the next level! Keep completing tasks! 📈');
    }

    // Complete pending tasks
    final pendingTasks =
        allTasks.where((task) => !task.isCompleted).length;
    if (pendingTasks > 5) {
      recommendations.add(
          'You have $pendingTasks pending tasks. Complete one to boost your momentum!');
    }

    return recommendations;
  }
}
