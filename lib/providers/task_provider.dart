import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/achievement.dart' as achievement_model;
import '../models/task_item.dart';
import '../services/analytics_service.dart';
import '../services/gamification_service.dart' hide Achievement;
import '../services/firestore_service.dart' hide debugPrint;

typedef Badge = achievement_model.Badge;
typedef Achievement = achievement_model.Achievement;

class TaskProvider extends ChangeNotifier {
  static const uuid = Uuid();
  
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TaskItem> _tasks = [];
  List<Badge> _badges = [];
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
bool get isInitialized => _userId != null;
String? get userId => _userId;
  // Getters
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<TaskItem> get activeTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<TaskItem> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<Badge> get badges => List.unmodifiable(_badges);
  List<Achievement> get achievements =>
      List.unmodifiable(_achievements);
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalPoints => GamificationService.totalPoints(_tasks);
  int get currentLevel => GamificationService.levelFromPoints(totalPoints);
  int get currentStreak => GamificationService.currentStreak(_tasks);
  int get longestStreak => GamificationService.longestStreak(_tasks);
  double get completionRate => GamificationService.completionRate(_tasks);
  List<int> get weeklyCompletions =>
      GamificationService.weeklyCompletions(_tasks);
  Map<String, int> get categoryBreakdown =>
      GamificationService.categoryBreakdown(_tasks);

  // ==================== INITIALIZATION ====================

  /// Initialize task provider with user ID
Future<void> initialize(String userId) async {
  _userId = userId;
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    await loadTasks();
    await loadBadges();
    await loadAchievements();
  } catch (e) {
    _errorMessage = 'Failed to initialize tasks: $e';
    debugPrint(_errorMessage);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  // ==================== TASK OPERATIONS ====================

  /// Load all tasks for the user
  Future<void> loadTasks() async {
    if (_userId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _firestoreService.getUserTasks(_userId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new task
Future<bool> addTask({
  required String title,
  required String description,
  required TaskCategory category,
  required TaskPriority priority,
  DateTime? dueDate,
  List<String> tags = const [],
}) async {
  if (_userId == null) {
    _errorMessage = 'User not initialized';
    notifyListeners();
    return false;
  }

  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var task = TaskItem(
      id: uuid.v4(),
      userId: _userId!,
      title: title,
      description: description,
      category: category,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      pointsAwarded: priority.points,
      tags: tags,
    );

    final taskId = await _firestoreService.createTask(task);
    task = task.copyWith(id: taskId);
    _tasks.insert(0, task);

    await AnalyticsService.logTaskCreated(_userId!, taskId, category.label);

    _errorMessage = null;
    return true;
  } catch (e) {
    _errorMessage = 'Failed to create task: $e';
    debugPrint(_errorMessage);
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  /// Update an existing task
  Future<bool> updateTask(TaskItem updatedTask) async {
    if (_userId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.updateTask(updatedTask);
      _tasks = _tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    if (_userId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);

      // Log analytics
      await AnalyticsService.logTaskDeleted(_userId!, taskId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// Complete a task
  Future<bool> completeTask(TaskItem task, AppUser user) async {
    if (_userId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final completedTask = task.copyWith(
        isCompleted: true,
        completedAt: now,
      );

      await updateTask(completedTask);

      // Calculate points
      final streakBonus = _isOnStreak(task.completedAt);
      final pointsAwarded =
          GamificationService.calculateTaskPoints(task, onStreak: streakBonus);

      // Update user stats
      final newStreak = GamificationService.currentStreak(_tasks);
      await _firestoreService.updateUserStats(
        userId: _userId!,
        pointsToAdd: pointsAwarded,
        streakDays: newStreak,
        completedTasks: completedTask.isCompleted ? 1 : 0,
      );

      // Log analytics
      await AnalyticsService.logTaskCompleted(
        _userId!,
        task.id,
        pointsAwarded,
        task.category.label,
      );

      // Check for badges
      await _checkAndAwardBadges(user);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete task: $e';
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// Toggle a task completion status by ID
Future<bool> toggleTask(String taskId) async {
  if (_userId == null) {
    _errorMessage = 'User not initialized';
    notifyListeners();
    return false;
  }

  try {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      _errorMessage = 'Task not found';
      notifyListeners();
      return false;
    }

    final oldTask = _tasks[taskIndex];
    final wasCompleted = oldTask.isCompleted;

    final toggledTask = oldTask.copyWith(
      isCompleted: !oldTask.isCompleted,
      completedAt: !oldTask.isCompleted ? DateTime.now() : null,
    );

    final updated = await updateTask(toggledTask);
    if (!updated) return false;

    if (!wasCompleted && toggledTask.isCompleted) {
      final pointsAwarded = GamificationService.calculateTaskPoints(
        toggledTask,
        onStreak: _isOnStreak(oldTask.completedAt),
      );

      final newStreak = GamificationService.currentStreak(_tasks);

      await _firestoreService.updateUserStats(
        userId: _userId!,
        pointsToAdd: pointsAwarded,
        streakDays: newStreak,
        completedTasks: 1,
      );

      await AnalyticsService.logTaskCompleted(
        _userId!,
        toggledTask.id,
        pointsAwarded,
        toggledTask.category.label,
      );

      final freshUser = await _firestoreService.getUser(_userId!);
      if (freshUser != null) {
        await _checkAndAwardBadges(freshUser);
        await _checkAndAwardAchievements(freshUser);
      }

      await loadBadges();
      await loadAchievements();
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = 'Failed to toggle task: $e';
    debugPrint(_errorMessage);
    notifyListeners();
    return false;
  }
}
Future<void> _checkAndAwardAchievements(AppUser user) async {
  if (_userId == null) return;

  final existingTitles = _achievements.map((e) => e.title).toSet();
  final completedCount = _tasks.where((t) => t.isCompleted).length;
  final streak = GamificationService.currentStreak(_tasks);
  final points = GamificationService.totalPoints(_tasks);

  final List<Map<String, String>> pending = [];

  if (completedCount >= 1 && !existingTitles.contains('First Task Complete')) {
    pending.add({
      'title': 'First Task Complete',
      'description': 'You completed your very first task.',
      'emoji': '🌟',
    });
  }

  if (completedCount >= 5 && !existingTitles.contains('Momentum Builder')) {
    pending.add({
      'title': 'Momentum Builder',
      'description': 'You completed 5 tasks.',
      'emoji': '⚡',
    });
  }

  if (streak >= 3 && !existingTitles.contains('3 Day Streak')) {
    pending.add({
      'title': '3 Day Streak',
      'description': 'You stayed consistent for 3 days in a row.',
      'emoji': '🔥',
    });
  }

  if (points >= 1000 && !existingTitles.contains('Point Collector')) {
    pending.add({
      'title': 'Point Collector',
      'description': 'You earned 1000 total points.',
      'emoji': '💎',
    });
  }

  for (final item in pending) {
    await awardAchievement(
      item['title']!,
      item['description']!,
      emoji: item['emoji']!,
    );
  }
}
  /// Check if user is on a streak
  bool _isOnStreak(DateTime? lastCompletionDate) {
    if (lastCompletionDate == null) return false;

    final today = DateTime.now();
    final normalizedToday =
        DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    final normalizedLast =
        DateTime(lastCompletionDate.year, lastCompletionDate.month, lastCompletionDate.day);

    return normalizedLast == yesterday || normalizedLast == normalizedToday;
  }

  // ==================== BADGE OPERATIONS ====================

  /// Load user badges
  Future<void> loadBadges() async {
    if (_userId == null) return;

    try {
      _badges = await _firestoreService.getUserBadges(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }
  }

  /// Check and award badges
  Future<void> _checkAndAwardBadges(AppUser user) async {
    if (_userId == null) return;

    try {
      final badgesToAward =
          GamificationService.checkBadgesForCompletion(user, _tasks);

      for (final badgeType in badgesToAward) {
        final badge = Badge(
          id: uuid.v4(),
          userId: _userId!,
          type: badgeType,
          unlockedAt: DateTime.now(),
        );

        // Check if already earned
        final alreadyEarned =
            _badges.any((b) => b.type == badgeType);

        if (!alreadyEarned) {
          await _firestoreService.awardBadge(badge);
          _badges.add(badge);

          // Log analytics
          await AnalyticsService.logBadgeEarned(
            _userId!,
            badgeType.label,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error checking badges: $e');
    }
  }

  // ==================== ACHIEVEMENT OPERATIONS ====================

  /// Load user achievements
  Future<void> loadAchievements() async {
    if (_userId == null) return;

    try {
      _achievements =
          await _firestoreService.getUserAchievements(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  /// Award an achievement
  Future<void> awardAchievement(
    String title,
    String description, {
    String emoji = '🏅',
  }) async {
    if (_userId == null) return;

    try {
      final achievement = Achievement(
        id: uuid.v4(),
        userId: _userId!,
        title: title,
        description: description,
        unlockedAt: DateTime.now(),
        iconEmoji: emoji,
      );

      await _firestoreService.awardAchievement(achievement);
      _achievements.add(achievement);

      // Log analytics
      await AnalyticsService.logAchievementUnlocked(_userId!, title);

      notifyListeners();
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
    }
  }

  // ==================== UTILITY ====================

  /// Get tasks for a specific category
  List<TaskItem> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  /// Search tasks
  List<TaskItem> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return _tasks
        .where((task) =>
            task.title.toLowerCase().contains(lowerQuery) ||
            task.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get tasks due today
  List<TaskItem> getTasksDueToday() {
    final today = DateTime.now();
    return _tasks
        .where((task) =>
            task.dueDate != null &&
            task.dueDate!.year == today.year &&
            task.dueDate!.month == today.month &&
            task.dueDate!.day == today.day &&
            !task.isCompleted)
        .toList();
  }

  /// Get overdue tasks
  List<TaskItem> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks
        .where((task) =>
            task.dueDate != null &&
            task.dueDate!.isBefore(now) &&
            !task.isCompleted)
        .toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all tasks and achievements
  Future<void> reset() async {
    try {
      if (_userId == null) {
        _errorMessage = 'User not initialized';
        notifyListeners();
        return;
      }

      // Clear local data
      _tasks = [];
      _badges = [];
      _achievements = [];
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reset: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
