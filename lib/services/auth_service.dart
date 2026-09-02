import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/services/profile_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _profileService = ProfileService();

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    
    await OneSignal.login(uid);
    await _firestore.collection("Users").doc(uid).set(
      {
        "email": email,
        "uid": uid
      }
    );
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    await OneSignal.login(uid);
    await _firestore.collection("Users").doc(uid).set(
      {
        "email": email,
        "uid": uid
      }
    );
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _profileService.setStatus(false);
    await OneSignal.logout();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final currentUserID = _auth.currentUser!.uid;

    await OneSignal.logout();
    await _firestore.collection("Users").doc(currentUserID).delete();
    await _auth.currentUser!.delete();
  }
}