import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessage {
  final String senderID;
  final String message;
  final String messageType;
  final Timestamp timestamp;

  GroupMessage({
    required this.senderID,
    required this.message,
    required this.messageType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "senderID": senderID,
      "message": message,
      "messageType": messageType,
      "timestamp": timestamp,
    };
  }
}