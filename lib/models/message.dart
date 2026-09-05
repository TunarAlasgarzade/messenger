import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final String? publicID;
  final bool isRead;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.isRead,
    required this.timestamp,
    this.publicID,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "messageType": messageType,
      "publicID": publicID,
      "isRead": isRead,
      "timestamp": timestamp,
    };
  }
}