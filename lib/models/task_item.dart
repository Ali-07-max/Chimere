import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskCategory { work, study, health, personal }

enum TaskPriority { low, medium, high, urgent }

extension TaskCategoryX on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.personal:
        return 'Personal';
    }
  }

  String get emoji {
    switch (this) {
      case TaskCategory.work:
        return '💼';
      case TaskCategory.study:
        return '📚';
      case TaskCategory.health:
        return '💪';
      case TaskCategory.personal:
        return '⭐';
    }
  }
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  int get points {
    switch (this) {
      case TaskPriority.low:
        return 10;
      case TaskPriority.medium:
        return 25;
      case TaskPriority.high:
        return 50;
      case TaskPriority.urgent:
        return 100;
    }
  }
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.pointsAwarded = 10,
    this.tags = const [],
    this.subtasks = const [],
    this.reminders = const [],
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final int pointsAwarded;
  final List<String> tags;
  final List<Subtask> subtasks;
  final List<DateTime> reminders;

  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get isDueToday =>
      !isCompleted &&
      dueDate != null &&
      dueDate!.year == DateTime.now().year &&
      dueDate!.month == DateTime.now().month &&
      dueDate!.day == DateTime.now().day;

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;

  double get subtaskCompletionPercentage =>
      subtasks.isEmpty ? 0 : completedSubtasks / subtasks.length;

  TaskItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    int? pointsAwarded,
    List<String>? tags,
    List<Subtask>? subtasks,
    List<DateTime>? reminders,
  }) {
    return TaskItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'pointsAwarded': pointsAwarded,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'reminders': reminders.map((r) => r.toIso8601String()).toList(),
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: TaskCategory.values.firstWhere(
        (item) => item.name == map['category'],
        orElse: () => TaskCategory.personal,
      ),
      priority: TaskPriority.values.firstWhere(
        (item) => item.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      dueDate: map['dueDate'] == null ? null : DateTime.tryParse(map['dueDate'] as String),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.tryParse(map['completedAt'] as String),
      pointsAwarded: map['pointsAwarded'] as int? ?? 10,
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      subtasks: (map['subtasks'] as List<dynamic>? ?? [])
          .map((s) => Subtask.fromMap(s as Map<String, dynamic>))
          .toList(),
      reminders: (map['reminders'] as List<dynamic>? ?? [])
          .map((r) => DateTime.parse(r as String))
          .toList(),
    );
  }

  factory TaskItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return TaskItem.fromMap({...data, 'id': snapshot.id});
  }
}

class Subtask {
  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.tryParse(map['completedAt'] as String),
    );
  }
}
