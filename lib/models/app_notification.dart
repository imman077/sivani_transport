import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // trip_added, driver_updated, etc.
  final String? targetUserId; // null for admins, specific ID for drivers
  final bool isRead;
  final String role; // Admin or Driver

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.targetUserId,
    this.isRead = false,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'targetUserId': targetUserId,
      'isRead': isRead,
      'role': role,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      targetUserId: map['targetUserId'],
      isRead: map['isRead'] ?? false,
      role: map['role'] ?? 'Admin',
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    String? targetUserId,
    bool? isRead,
    String? role,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      isRead: isRead ?? this.isRead,
      role: role ?? this.role,
    );
  }
}
