import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    
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
    await setStatus(false);
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final currentUserID = _auth.currentUser!.uid;

    await _auth.currentUser!.delete();
    await _firestore.collection("Users").doc(currentUserID).delete();
  }

  Future<void> setStatus(bool isOnline) async {
    final currentUserID = _auth.currentUser!.uid;

    await _firestore.collection("Users").doc(currentUserID).set(
      {
        "isOnline": isOnline
      },
      SetOptions(merge: true),
    );
  }
}