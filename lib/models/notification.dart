import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBody {
  final String body;
  final bool isRead;
  final Timestamp timestamp;
  final String title;
  final String userId;

  NotificationBody({
    required this.body,
    required this.isRead,
    required this.timestamp,
    required this.title,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'body': body,
      'isRead': isRead,
      'timestamp': timestamp,
      'title': title,
      'userId': userId,
    };
  }
} 