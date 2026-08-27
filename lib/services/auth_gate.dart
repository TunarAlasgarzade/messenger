import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/pages/home_page.dart';
import 'package:messenger/pages/login_page.dart';
import 'package:messenger/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _auth = AuthService();
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _auth.setStatus(true);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _auth.setStatus(true);
    } else {
      _auth.setStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return HomePage();
    } else {
      return LoginPage();
    }
  }
}