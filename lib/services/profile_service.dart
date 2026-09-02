import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUploadSignature() async {
    final idToken = await _auth.currentUser!.getIdToken();
    final response = await http.post(
      Uri.parse("https://messenger-notifications.t-alasgarzade.workers.dev/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken"
      },
      body: jsonEncode({
        "action": "getUploadSignature"
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  }

  Future<void> uploadProfilePhoto(XFile image, String signature, int timestamp, String folder) async {
    final request = http.MultipartRequest(
      "POST", 
      Uri.parse("https://api.cloudinary.com/v1_1/txdi4bc7/image/upload"),
    );
    request.fields["api_key"] = "882198962458982";
    request.fields["timestamp"] = timestamp.toString();
    request.fields["signature"] = signature;
    request.fields["folder"] = folder;
    request.files.add(
      await http.MultipartFile.fromPath("file", image.path)
    );
    final response = await request.send();

    if (response.statusCode == 200) {
      final data = await http.Response.fromStream(response);
      final uploadData = jsonDecode(data.body);
      await _firestore.collection("Users").doc(_auth.currentUser!.uid).collection("profile").doc("data").set(
        {
        "profilePhoto": uploadData["secure_url"],
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<String?> getProfilePhoto() async {
    final doc = await _firestore.collection("Users").doc(_auth.currentUser!.uid).collection("profile").doc("data").get();
    return doc.data()?["profilePhoto"];
  }

  Stream<String?> getOtherUserProfilePhoto(String otherUserID) {
    return _firestore
        .collection("Users")
        .doc(otherUserID)
        .collection("profile")
        .doc("data")
        .snapshots()
        .map((doc) => doc.data()?["profilePhoto"] as String);
  }

  Stream<String?> getReceiverProfilePhoto(String receiverID) {
    return _firestore
        .collection("Users")
        .doc(receiverID)
        .collection("profile")
        .doc("data")
        .snapshots()
        .map((doc) => doc.data()?["profilePhoto"] as String);
  }

  Future<void> setStatus(bool isOnline) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore.collection("Users").doc(currentUserID).collection("profile").doc("data").set(
      {
        "isOnline": isOnline
      },
      SetOptions(merge: true),
    );
  }
}