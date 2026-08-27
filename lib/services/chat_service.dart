import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/models/message.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> sendMessage(String message, String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;

    Message newMessage = Message(
      senderId: currentUserID, 
      receiverId: receiverID, 
      message: message,
      isRead: false,
      timestamp: Timestamp.now()
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(
          newMessage.toMap()
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String currentUserID, String receiverID) {
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots();
  }

  Future<void> deleteMessage(String currentUserID, String receiverID, String documentID) async {
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');
    
    await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(documentID)
        .delete();
  }

  Future<void> updateMessage(String message, String receiverID, String messageID) async {
    final String currentUserID = _auth.currentUser!.uid;

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(
          messageID
        )
        .update(
          {
            "message": message
          }
        );
  }

  Future<void> addContact(String contactUID, String contactName, String contactEmail) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("contacts")
        .doc(contactUID)
        .set(
          {
            "contactName": contactName,
            "contactEmail": contactEmail,
            "contactID": contactUID,
          }
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getContacts() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("contacts")
        .snapshots();
  }

  Future<void> deleteContact(String contactID) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore.
        collection("Users")
        .doc(currentUserID)
        .collection("contacts")
        .doc(contactID)
        .delete();
  }

  Future<void> updateContact(String contactUID, String contactName, String contactEmail) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("contacts")
        .doc(contactUID)
        .update(
          {
            "contactName": contactName,
            "contactEmail": contactEmail,
            "contactID": contactUID,
          }
        );
  }

  Future<void> blockContact(String contactID, String contactName, String contactEmail) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("blocked_contacts")
        .doc(contactID)
        .set(
          {
            "contactName": contactName,
            "contactEmail": contactEmail,
            "contactID": contactID,
          }
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBlockedContacts() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("blocked_contacts")
        .snapshots();
  }

  Future<void> unblockContact(String contactID) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("blocked_contacts")
        .doc(contactID)
        .delete();
  }
  
  Future<String?> getUserUIDByEmail(String email) async {
    final snapshot = await _firestore
        .collection("Users")
        .where("email", isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data()["uid"];
  }

  Future<void> markAsRead(String receiverID, String messageID) async {
    final String currentUserID = _auth.currentUser!.uid;

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(
          messageID
        )
        .update(
          {
            "isRead": true
          }
        );
  }

  Future<void> markUnreadMessagesAsRead(String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    final messages = await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where("receiverId", isEqualTo: currentUserID)
        .where("isRead", isEqualTo: false)
        .get();

    for(var message in messages.docs) {
      await message.reference.update(
        {
          "isRead": true
        }
      );
    }
  }

  Future<void> setTypingStatus(String receiverID, bool isTyping) async {
    final String currentUserID = _auth.currentUser!.uid;

    await _firestore
        .collection("Users")
        .doc(receiverID)
        .collection("contacts")
        .doc(currentUserID)
        .set(
          {
            "isTyping": isTyping
          },
          SetOptions(merge: true),
        );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getTypingStatus(String receiverID) {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection("Users")
        .doc(currentUserID)
        .collection("contacts")
        .doc(receiverID)
        .snapshots();
  }

  Stream<int> getUnreadMessagesCount(String receiverID) {
    final String currentUserID = _auth.currentUser!.uid;
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where("receiverId", isEqualTo: currentUserID)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}