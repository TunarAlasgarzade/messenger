import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ContactService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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
}