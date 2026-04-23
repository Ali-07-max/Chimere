import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_item.dart';
import '../models/app_user.dart';
import '../models/achievement.dart';
import '../models/analytics_event.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String badgesCollection = 'badges';
  static const String achievementsCollection = 'achievements';
  static const String analyticsCollection = 'analytics_events';

  // ==================== USER OPERATIONS ====================

  /// Create or update user profile
  Future<void> createOrUpdateUser(AppUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  /// Stream user data for real-time updates
  Stream<AppUser?> streamUser(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// Update user gamification stats
  Future<void> updateUserStats({
    required String userId,
    required int pointsToAdd,
    required int streakDays,
    required int completedTasks,
  }) async {
    try {
      final userRef = _firestore.collection(usersCollection).doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final user = AppUser.fromFirestore(userDoc);
      int newLevel = user.level;
      int newTotalPoints = user.totalPoints + pointsToAdd;

      // Check for level up
      while (newTotalPoints >= newLevel * 1000) {
        newLevel++;
      }

      await userRef.update({
        'totalPoints': newTotalPoints,
        'currentStreak': streakDays,
        'level': newLevel,
        'completedTasksCount': user.completedTasksCount + 1,
        'lastTaskCompletionDate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user stats: $e');
      rethrow;
    }
  }

  // ==================== TASK OPERATIONS ====================

  /// Create a new task
  Future<String> createTask(TaskItem task) async {
    try {
      final docRef =
          await _firestore.collection(tasksCollection).add(task.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  /// Update an existing task
  Future<void> updateTask(TaskItem task) async {
    try {
      await _firestore
          .collection(tasksCollection)
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(tasksCollection).doc(taskId).delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  /// Get all tasks for a user
  Future<List<TaskItem>> getUserTasks(String userId) async {
    try {
      final query = await _firestore
          .collection(tasksCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => TaskItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user tasks: $e');
      rethrow;
    }
  }

  /// Stream user tasks for real-time updates
  Stream<List<TaskItem>> streamUserTasks(String userId) {
    return _firestore
        .collection(tasksCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) =>
            query.docs.map((doc) => TaskItem.fromFirestore(doc)).toList());
  }

  /// Get completed tasks for a user
  Future<List<TaskItem>> getCompletedTasks(String userId) async {
    try {
      final query = await _firestore
          .collection(tasksCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => TaskItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting completed tasks: $e');
      rethrow;
    }
  }

  /// Get pending tasks for a user
  Future<List<TaskItem>> getPendingTasks(String userId) async {
    try {
      final query = await _firestore
          .collection(tasksCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate', descending: false)
          .get();

      return query.docs
          .map((doc) => TaskItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending tasks: $e');
      rethrow;
    }
  }

  // ==================== BADGE OPERATIONS ====================

  /// Award a badge to a user
  Future<void> awardBadge(Badge badge) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(badge.userId)
          .collection(badgesCollection)
          .doc(badge.id)
          .set(badge.toMap());
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      rethrow;
    }
  }

  /// Get user badges
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final query = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(badgesCollection)
          .get();

      return query.docs.map((doc) => Badge.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user badges: $e');
      rethrow;
    }
  }

  /// Stream user badges
  Stream<List<Badge>> streamUserBadges(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(badgesCollection)
        .snapshots()
        .map((query) =>
            query.docs.map((doc) => Badge.fromFirestore(doc)).toList());
  }

  // ==================== ACHIEVEMENT OPERATIONS ====================

  /// Award an achievement
  Future<void> awardAchievement(Achievement achievement) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(achievement.userId)
          .collection(achievementsCollection)
          .doc(achievement.id)
          .set(achievement.toMap());
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
      rethrow;
    }
  }

  /// Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final query = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(achievementsCollection)
          .get();

      return query.docs
          .map((doc) => Achievement.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Log an analytics event
  Future<void> logAnalyticsEvent(AnalyticsEvent event) async {
    try {
      await _firestore.collection(analyticsCollection).add(event.toMap());
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
      rethrow;
    }
  }

  /// Get user analytics for a time period
  Future<List<AnalyticsEvent>> getUserAnalytics(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _firestore
          .collection(analyticsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      return query.docs
          .map((doc) => AnalyticsEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      rethrow;
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Delete user account and all associated data
  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete user document
      batch.delete(_firestore.collection(usersCollection).doc(userId));

      // Delete all user tasks
      final tasks = await _firestore
          .collection(tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in tasks.docs) {
        batch.delete(doc.reference);
      }

      // Delete all user analytics
      final analytics = await _firestore
          .collection(analyticsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in analytics.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Get user statistics for dashboard
  Future<Map<String, dynamic>> getUserDashboardStats(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return {};

      final completedTasks = await getCompletedTasks(userId);
      final pendingTasks = await getPendingTasks(userId);
      final badges = await getUserBadges(userId);

      return {
        'level': user.level,
        'totalPoints': user.totalPoints,
        'currentStreak': user.currentStreak,
        'longestStreak': user.longestStreak,
        'completedTasksCount': completedTasks.length,
        'pendingTasksCount': pendingTasks.length,
        'badgesCount': badges.length,
        'levelProgress': user.levelProgressPercentage,
      };
    } catch (e) {
      debugPrint('Error getting user dashboard stats: $e');
      return {};
    }
  }
}

void debugPrint(String message) {
  print(message);
}
