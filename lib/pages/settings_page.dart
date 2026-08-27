import 'package:flutter/material.dart';
import 'package:messenger/pages/appearance_page.dart';
import 'package:messenger/pages/blocked_contacts_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context, MaterialPageRoute(
                  builder: (context) => AppearancePage()
                )
              ),
              child: Container(
                margin: EdgeInsets.only(top: 15, right: 15, left: 15),
                padding: EdgeInsets.all(27.5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Appearance"),
                    Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface)
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context, MaterialPageRoute(
                  builder: (context) => BlockedContactsPage()
                )
              ),
              child: Container(
                margin: EdgeInsets.only(top: 15, right: 15, left: 15),
                padding: EdgeInsets.all(27.5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Blocked Contacts"),
                    Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}