import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/pages/home_page.dart';
import 'package:messenger/pages/login_page.dart';
import 'package:messenger/services/profile_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _profileService = ProfileService();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (FirebaseAuth.instance.currentUser != null) {
      _profileService.setStatus(true);
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
      if (FirebaseAuth.instance.currentUser != null) {
        if (state == AppLifecycleState.resumed) {
        _profileService.setStatus(true);
      } else {
        _profileService.setStatus(false);
      }
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