import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeType {
  starter,
  speedRunner,
  streakMaster,
  pointCollector,
  categoryExpert,
  levelFive,
  levelTen,
  socialButterfly,
  helper,
  perfectWeek,
}

extension BadgeTypeX on BadgeType {
  String get label {
    switch (this) {
      case BadgeType.starter:
        return 'Starter';
      case BadgeType.speedRunner:
        return 'Speed Runner';
      case BadgeType.streakMaster:
        return 'Streak Master';
      case BadgeType.pointCollector:
        return 'Point Collector';
      case BadgeType.categoryExpert:
        return 'Category Expert';
      case BadgeType.levelFive:
        return 'Level 5';
      case BadgeType.levelTen:
        return 'Level 10';
      case BadgeType.socialButterfly:
        return 'Social Butterfly';
      case BadgeType.helper:
        return 'Helper';
      case BadgeType.perfectWeek:
        return 'Perfect Week';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.starter:
        return 'Complete your first task';
      case BadgeType.speedRunner:
        return 'Complete 10 tasks';
      case BadgeType.streakMaster:
        return 'Maintain a 7-day streak';
      case BadgeType.pointCollector:
        return 'Earn 1,000 points';
      case BadgeType.categoryExpert:
        return 'Complete 20 tasks in one category';
      case BadgeType.levelFive:
        return 'Reach level 5';
      case BadgeType.levelTen:
        return 'Reach level 10';
      case BadgeType.socialButterfly:
        return 'Unlock all social features';
      case BadgeType.helper:
        return 'Help others in community';
      case BadgeType.perfectWeek:
        return 'Complete all planned tasks for a week';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeType.starter:
        return '🌟';
      case BadgeType.speedRunner:
        return '⚡';
      case BadgeType.streakMaster:
        return '🔥';
      case BadgeType.pointCollector:
        return '💎';
      case BadgeType.categoryExpert:
        return '🏆';
      case BadgeType.levelFive:
        return '⭐⭐⭐⭐⭐';
      case BadgeType.levelTen:
        return '👑';
      case BadgeType.socialButterfly:
        return '🦋';
      case BadgeType.helper:
        return '🤝';
      case BadgeType.perfectWeek:
        return '✨';
    }
  }
}

class Badge {
  Badge({
    required this.id,
    required this.userId,
    required this.type,
    required this.unlockedAt,
  });

  final String id;
  final String userId;
  final BadgeType type;
  final DateTime unlockedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'unlockedAt': unlockedAt.toIso8601String(),
      };

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      type: BadgeType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => BadgeType.starter,
      ),
      unlockedAt: DateTime.tryParse(map['unlockedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory Badge.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Badge.fromMap({...data, 'id': snapshot.id});
  }

  Badge copyWith({
    String? id,
    String? userId,
    BadgeType? type,
    DateTime? unlockedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class Achievement {
  Achievement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.unlockedAt,
    this.iconEmoji = '🏅',
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime unlockedAt;
  final String iconEmoji;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'unlockedAt': unlockedAt.toIso8601String(),
        'iconEmoji': iconEmoji,
      };

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      unlockedAt: DateTime.tryParse(map['unlockedAt'] as String? ?? '') ??
          DateTime.now(),
      iconEmoji: map['iconEmoji'] as String? ?? '🏅',
    );
  }

  factory Achievement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return Achievement.fromMap({...data, 'id': snapshot.id});
  }

  Achievement copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? unlockedAt,
    String? iconEmoji,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }
}

