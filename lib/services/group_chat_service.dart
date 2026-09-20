import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/models/group_message.dart';

class GroupChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createGroup(String name, Timestamp createdAt, List<String> selectedUsers) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserEmail = _auth.currentUser!.email;

    final groupRef = await _firestore.collection("Groups").add({
      "name": name,
      "createdBy": currentUserID,
      "createdAt": createdAt,
      "canMembersEditInfo": false,
    });

    await groupRef.collection("members").doc(currentUserID).set({
      "uid": currentUserID,
      "email": currentUserEmail,
      "role": "admin",
    });

    for (String userID in selectedUsers) {
      final contact = await _firestore
          .collection("Users")
          .doc(currentUserID)
          .collection("contacts")
          .doc(userID)
          .get();
      final email = contact.data()?["contactEmail"];

      await groupRef.collection("members").doc(userID).set({
        "uid": userID,
        "email": email,
        "role": "member",
      });
    }
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getGroups() {
    final currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collectionGroup("members")
        .where("uid", isEqualTo: currentUserID)
        .snapshots().asyncMap((snapshot) {
          return Future.wait(
            snapshot.docs.map((memberDoc) {
              return memberDoc.reference.parent.parent!.get();
            }).toList()
          );
        });
  }

  Future<void> sendMessage(String message, String groupID) async {
    final String currentUserID = _auth.currentUser!.uid;

    GroupMessage newMessage = GroupMessage(
      senderID: currentUserID, 
      message: message, 
      messageType: "text", 
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection("Groups")
        .doc(groupID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String groupID) {
    return _firestore
        .collection("Groups")
        .doc(groupID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<void> deleteMessage(String messageID, String groupID) async {
    await _firestore
        .collection("Groups")
        .doc(groupID)
        .collection("messages")
        .doc(messageID)
        .delete();
  }

  Future<void> updateMessage(String messageID, String newMessage, String groupID) async {
    await _firestore
        .collection("Groups")
        .doc(groupID)
        .collection("messages")
        .doc(messageID)
        .update({
          "message": newMessage
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMembers(String groupID) {
    return _firestore
        .collection("Groups")
        .doc(groupID)
        .collection("members")
        .snapshots();
  }

  Future<void> addMember(String groupID, List<String> selectedUsers) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {
      for (String userID in selectedUsers) {
        final contact = await _firestore
          .collection("Users")
          .doc(currentUserID)
          .collection("contacts")
          .doc(userID)
          .get();
        final email = contact.data()?["contactEmail"];

        await _firestore.collection("Groups").doc(groupID).collection("members").doc(userID).set({
          "uid": userID,
          "email": email,
          "role": "member",
        });
      }
    } else {
      throw Exception("Only admins can add member.");
    }
  }

  Future<void> removeMember(String groupID, String memberID) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(memberID)
          .delete();
    } else {
      throw Exception("Only admins can remove members.");
    }
  }

  Future<void> leaveGroup(String groupID) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {  
      final admins = await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .where("role", isEqualTo: "admin")
          .get();
      final members = await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .where("role", isEqualTo: "member")
          .get();
      
      if (admins.docs.length == 1) {
        if (members.docs.isNotEmpty) {
          final random = Random();
          final randomIndex = random.nextInt(members.docs.length);
          final selectedMember = members.docs[randomIndex];
          await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(selectedMember.id)
            .update({
              "role": "admin"
            });
          await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(currentUserID)
            .delete();
        } else {
          await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(currentUserID)
            .delete();
        }
      } else {
        await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(currentUserID)
            .delete();
      }
    } else {
      await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(currentUserID)
            .delete();
    }
  }

  Future<void> makeAdmin(String groupID, String memberID) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];
    final memberRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(memberID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {
      if (memberRole == "member") {
        await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(memberID)
            .update({
              "role": "admin"
            });
      } else {
        throw Exception("Only members can be promoted to admin.");
      }
    } else {
      throw Exception("Only admins can promote members to admin.");
    }
  }

  Future<void> removeAdmin(String groupID, String memberID) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];
    final memberRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(memberID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {
      if (memberRole == "admin") {
        await _firestore
            .collection("Groups")
            .doc(groupID)
            .collection("members")
            .doc(memberID)
            .update({
              "role": "member"
            });
      } else {
        throw Exception("Only admins can be demoted to member.");
      }
    } else {
      throw Exception("Only admins can remove an admin's role.");
    }
  }

  Future<void> renameGroup(String groupID, String newName) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];
    final membersCanEditInfo = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .get()
    ).data()?["canMembersEditInfo"];

    if (currentUserRole == "admin") {
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .update({
            "name": newName
          });
    } else if (membersCanEditInfo == true) {
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .update({
            "name": newName
          });
    } else {
      throw Exception("Only admins can rename the group.");
    }
  }

  Future<void> setMembersCanEditInfo(String groupID, bool value) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserRole = (
      await _firestore
          .collection("Groups")
          .doc(groupID)
          .collection("members")
          .doc(currentUserID)
          .get()
    ).data()?["role"];

    if (currentUserRole == "admin") {
      await _firestore.collection("Groups").doc(groupID).set(
        {
          "canMembersEditInfo": value
        },
        SetOptions(merge: true)
      );
    }
  }
}