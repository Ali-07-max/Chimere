import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsEvent {
  AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.name,
    required this.timestamp,
    this.payload = const {},
  });

  final String id;
  final String userId;
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
      };

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return AnalyticsEvent(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
    );
  }

  factory AnalyticsEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return AnalyticsEvent.fromMap({...data, 'id': snapshot.id});
  }

  AnalyticsEvent copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
  }) {
    return AnalyticsEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
    );
  }
}

