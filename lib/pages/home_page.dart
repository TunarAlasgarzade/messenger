import 'package:flutter/material.dart';
import 'package:messenger/components/my_bottomnav.dart';
import 'package:messenger/pages/contacts_page.dart';
import 'package:messenger/pages/profile_page.dart';
import 'package:messenger/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedContactName = "";
  String selectedContactEmail = "";
  bool isLongPressed = false;
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: MyBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: _selectedIndex == 0 
        ? ContactsPage() 
        : _selectedIndex == 1 
        ? ProfilePage() 
        : SettingsPage(),
    );
  }
}