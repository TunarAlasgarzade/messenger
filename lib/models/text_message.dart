import 'package:cloud_firestore/cloud_firestore.dart';

class TextMessage {
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final Timestamp timestamp;

  TextMessage({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "messageType": "text",
      "isRead": isRead,
      "timestamp": timestamp,
    };
  }
}