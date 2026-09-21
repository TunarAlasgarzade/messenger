import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger/models/message.dart';
import 'package:path_provider/path_provider.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _sendNotification(String message, String receiverID) async {
    final receiverDocument = await _firestore.collection("Users").doc(receiverID).collection("profile").doc("data").get();
    bool? isReceiverOnline = receiverDocument.data()?["isOnline"];
    final idToken = await _auth.currentUser!.getIdToken();

    if (isReceiverOnline != true) {
      final url = Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/");
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken"
        }, 
        body: jsonEncode(
          {
            "action": "sendNotification",
            "recipientUid": receiverID,
            "message": message
          } 
        )
      );
    }
  }

  Future<Map<String, dynamic>> _uploadFile(String filePath, String action, String resourceType) async {
    final idToken = await _auth.currentUser!.getIdToken();

    final response = await http.post(
      Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken"
      },
      body: jsonEncode({
        "action": action
      }),
    );
    
    final data = jsonDecode(response.body);

    final signature = data["signature"];
    final timestamp = data["timestamp"];
    final folder = data["folder"];

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://api.cloudinary.com/v1_1/txdi4bc7/$resourceType/upload")
    );
    request.fields["api_key"] = "882198962458982";
    request.fields["timestamp"] = timestamp.toString();
    request.fields["signature"] = signature;
    request.fields["folder"] = folder;
    request.files.add(
      await http.MultipartFile.fromPath("file", filePath)
    );
    final uploadResponse = await request.send();
    final responseData = await http.Response.fromStream(uploadResponse);
    final uploadData = jsonDecode(responseData.body);
    final secureUrl = uploadData["secure_url"];
    final publicID = uploadData["public_id"];

    return {
      "secureUrl": secureUrl,
      "publicID": publicID
    };
  }

  Future<void> sendTextMessage(String message, String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;

    Message newMessage = Message(
      senderId: currentUserID, 
      receiverId: receiverID, 
      message: message,
      messageType: "text",
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

    _sendNotification(message, receiverID);
  }

  Future<void> sendVoiceMessage(String audioPath, String receiverID) async {
    final currentUserID = _auth.currentUser!.uid;
    
    final uploadData = await _uploadFile(audioPath, "getAudioUploadSignature", "video");

    Message newMessage = Message(
      senderId: currentUserID, 
      receiverId: receiverID, 
      message: uploadData["secureUrl"], 
      messageType: "audio",
      publicID: uploadData["publicID"], 
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
        .add(newMessage.toMap());

    File(audioPath).delete();

    _sendNotification("🎤️ New Voice Message", receiverID);
  }

  Future<void> sendImageMessage(XFile image, String receiverID) async {
    final String currentUserID = _auth.currentUser!.uid;
    
    final uploadData = await _uploadFile(image.path, "getChatImageUploadSignature", "image");

    Message newMessage = Message(
      senderId: currentUserID, 
      receiverId: receiverID, 
      message: uploadData["secureUrl"],
      messageType: "image", 
      publicID: uploadData["publicID"],
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
        .add(newMessage.toMap());

    _sendNotification("🖼️ New Picture", receiverID);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String currentUserID, String receiverID) {
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(String receiverID) {
    final String currentUserID = _auth.currentUser!.uid;

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots();
  }

  Future<void> deleteMessage(String currentUserID, String receiverID, String documentID) async {
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    final message = await _firestore
        .collection("Chat_Rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(documentID)
        .get();
    final messageType = message.data()!["messageType"];
    
    if (messageType == "image") {
      final idToken = await _auth.currentUser!.getIdToken();
      await http.post(
        Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken"
        },
        body: jsonEncode({
          "action": "deleteChatImage",
          "receiverUid": receiverID,
          "messageId": documentID
        }) 
      );
    } else if (messageType == "audio") {
      final idToken = await _auth.currentUser!.getIdToken();
      await http.post(
        Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken"
        },
        body: jsonEncode({
          "action": "deleteChatAudio",
          "receiverUid": receiverID,
          "messageId": documentID
        }) 
      );
    } else {
      await _firestore
          .collection("Chat_Rooms")
          .doc(chatRoomID)
          .collection("messages")
          .doc(documentID)
          .delete();
    }
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
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({
        "action": "getUidByEmail",
        "email": email.trim()
      })
    );
    
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);

    return data["uid"];
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

  Future<void> saveImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final imageBytes = response.bodyBytes;
      final directory = await getApplicationCacheDirectory();
      final imagePath = "${directory.path}/image_${DateTime.now()}.png";
      await File(imagePath).writeAsBytes(imageBytes);
      final permission = await Gal.requestAccess();
      if (permission == true) {
        await Gal.putImage(imagePath, album: "Messenger Images");
      } else {
        print("permission denied");
      }
    } else {
      print("STATUS CODE: ${response.statusCode}");
    }
  }
}