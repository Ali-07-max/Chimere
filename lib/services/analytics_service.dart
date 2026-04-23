import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/analytics_event.dart';
import 'local_storage_service.dart';

class AnalyticsService {
  static final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  static final uuid = Uuid();

  // ==================== EVENT LOGGING ====================

  /// Log an event both locally and to Firebase
  static Future<void> logEvent(
    String name, {
    Map<String, dynamic> payload = const {},
    String? userId,
  }) async {
    try {
      // Log to Firebase Analytics
      await _firebaseAnalytics.logEvent(
        name: name.replaceAll('-', '_'), // Firebase requires underscores
        parameters: {
          ...payload,
          if (userId != null) 'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Log locally for offline support
      await _logLocalEvent(name, payload, userId);
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// Log local event to SharedPreferences
  static Future<void> _logLocalEvent(
    String name,
    Map<String, dynamic> payload,
    String? userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LocalStorageService.analyticsKey);
      final existing = <AnalyticsEvent>[];

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        existing.addAll(
          decoded
              .map((item) =>
                  AnalyticsEvent.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList(),
        );
      }

      existing.insert(
        0,
        AnalyticsEvent(
          id: uuid.v4(),
          userId: userId ?? 'anonymous',
          name: name,
          timestamp: DateTime.now(),
          payload: payload,
        ),
      );

      // Keep only last 100 events
      final trimmed = existing.take(100).map((e) => e.toMap()).toList();
      await prefs.setString(LocalStorageService.analyticsKey, jsonEncode(trimmed));
    } catch (e) {
      debugPrint('Error logging local analytics event: $e');
    }
  }

  // ==================== TASK EVENTS ====================

  /// Log task creation
  static Future<void> logTaskCreated(String userId, String taskId, String category) async {
    await logEvent(
      'task_created',
      payload: {
        'task_id': taskId,
        'category': category,
      },
      userId: userId,
    );
  }

  /// Log task completed
  static Future<void> logTaskCompleted(
    String userId,
    String taskId,
    int pointsAwarded,
    String category,
  ) async {
    await logEvent(
      'task_completed',
      payload: {
        'task_id': taskId,
        'points_awarded': pointsAwarded,
        'category': category,
      },
      userId: userId,
    );
  }

  /// Log task deleted
  static Future<void> logTaskDeleted(String userId, String taskId) async {
    await logEvent(
      'task_deleted',
      payload: {'task_id': taskId},
      userId: userId,
    );
  }

  // ==================== GAMIFICATION EVENTS ====================

  /// Log badge earned
  static Future<void> logBadgeEarned(String userId, String badgeName) async {
    await logEvent(
      'badge_earned',
      payload: {'badge_name': badgeName},
      userId: userId,
    );
  }

  /// Log achievement unlocked
  static Future<void> logAchievementUnlocked(
    String userId,
    String achievementName,
  ) async {
    await logEvent(
      'achievement_unlocked',
      payload: {'achievement_name': achievementName},
      userId: userId,
    );
  }

  /// Log level up
  static Future<void> logLevelUp(String userId, int newLevel, int totalPoints) async {
    await logEvent(
      'level_up',
      payload: {
        'new_level': newLevel,
        'total_points': totalPoints,
      },
      userId: userId,
    );
  }

  /// Log streak milestone
  static Future<void> logStreakMilestone(String userId, int streakDays) async {
    await logEvent(
      'streak_milestone',
      payload: {'streak_days': streakDays},
      userId: userId,
    );
  }

  // ==================== USER EVENTS ====================

  /// Log user sign in
  static Future<void> logSignIn(String userId, String email) async {
    await logEvent(
      'user_sign_in',
      payload: {'email': email},
      userId: userId,
    );

    // Set user ID in Firebase Analytics
    await _firebaseAnalytics.setUserId(id: userId);
  }

  /// Log user sign out
  static Future<void> logSignOut(String userId) async {
    await logEvent('user_sign_out', userId: userId);
    await _firebaseAnalytics.setUserId(id: null);
  }

  /// Log onboarding completion
  static Future<void> logOnboardingCompleted(String userId) async {
    await logEvent('onboarding_completed', userId: userId);
  }

  // ==================== SCREEN EVENTS ====================

  /// Log screen view
  static Future<void> logScreenView(String screenName, String userId) async {
    await _firebaseAnalytics.logScreenView(
      screenName: screenName,
    );

    await logEvent(
      'screen_view',
      payload: {'screen_name': screenName},
      userId: userId,
    );
  }

  // ==================== SESSION EVENTS ====================

  /// Log app session start
  static Future<void> logSessionStart(String userId) async {
    await logEvent(
      'app_session_start',
      payload: {'session_start': DateTime.now().toIso8601String()},
      userId: userId,
    );
  }

  /// Log app session end
  static Future<void> logSessionEnd(String userId, int durationSeconds) async {
    await logEvent(
      'app_session_end',
      payload: {'duration_seconds': durationSeconds},
      userId: userId,
    );
  }

  // ==================== DATA RETRIEVAL ====================

  /// Get all logged events
  static Future<List<AnalyticsEvent>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LocalStorageService.analyticsKey);
      if (raw == null || raw.isEmpty) return [];
      
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((item) =>
              AnalyticsEvent.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error retrieving analytics events: $e');
      return [];
    }
  }

  /// Get events for a specific user
  static Future<List<AnalyticsEvent>> getUserEvents(String userId) async {
    final events = await getEvents();
    return events.where((event) => event.userId == userId).toList();
  }

  /// Get events for a date range
  static Future<List<AnalyticsEvent>> getEventsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final events = await getEvents();
    return events
        .where((event) =>
            event.timestamp.isAfter(startDate) &&
            event.timestamp.isBefore(endDate))
        .toList();
  }

  /// Get events of a specific type
  static Future<List<AnalyticsEvent>> getEventsByName(String eventName) async {
    final events = await getEvents();
    return events.where((event) => event.name == eventName).toList();
  }

  // ==================== USER PROPERTIES ====================

  /// Set user property
  static Future<void> setUserProperty(String name, String value) async {
    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  /// Set user level
  static Future<void> setUserLevel(int level) async {
    await setUserProperty('user_level', level.toString());
  }

  /// Set user points
  static Future<void> setUserPoints(int points) async {
    await setUserProperty('total_points', points.toString());
  }

  /// Set user streak
  static Future<void> setUserStreak(int streak) async {
    await setUserProperty('current_streak', streak.toString());
  }

  // ==================== UTILITY ====================

  /// Clear all local analytics
  static Future<void> clearLocalAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LocalStorageService.analyticsKey);
    } catch (e) {
      debugPrint('Error clearing local analytics: $e');
    }
  }
}

