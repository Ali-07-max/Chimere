import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio = '',
    this.level = 1,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastTaskCompletionDate,
    this.preferences = const {},
    this.createdAt,
    this.updatedAt,
    this.completedTasksCount = 0,
    this.totalTasksCreated = 0,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String bio;
  final int level;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastTaskCompletionDate;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int completedTasksCount;
  final int totalTasksCreated;

  int get pointsForNextLevel => level * 1000;
  int get pointsProgress => totalPoints % pointsForNextLevel;

  double get levelProgressPercentage =>
      (pointsProgress / pointsForNextLevel).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'bio': bio,
        'level': level,
        'totalPoints': totalPoints,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastTaskCompletionDate': lastTaskCompletionDate?.toIso8601String(),
        'preferences': preferences,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedTasksCount': completedTasksCount,
        'totalTasksCreated': totalTasksCreated,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String? ?? '',
      level: map['level'] as int? ?? 1,
      totalPoints: map['totalPoints'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastTaskCompletionDate: map['lastTaskCompletionDate'] != null
          ? DateTime.parse(map['lastTaskCompletionDate'] as String)
          : null,
      preferences: Map<String, dynamic>.from(
        (map['preferences'] as Map?) ?? const {},
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      completedTasksCount: map['completedTasksCount'] as int? ?? 0,
      totalTasksCreated: map['totalTasksCreated'] as int? ?? 0,
    );
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return AppUser.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    int? level,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastTaskCompletionDate,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? completedTasksCount,
    int? totalTasksCreated,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastTaskCompletionDate:
          lastTaskCompletionDate ?? this.lastTaskCompletionDate,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      totalTasksCreated: totalTasksCreated ?? this.totalTasksCreated,
    );
  }
}