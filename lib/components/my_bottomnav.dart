import 'package:flutter/material.dart';

class MyBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const MyBottomNav({
    super.key,
    required this.onTap,
    required this.currentIndex
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.message, color: Theme.of(context).colorScheme.onSurface), 
          label: "Chats"
        ),
        NavigationDestination(
          icon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface), 
          label: "Profile"
        ),
        NavigationDestination(
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface), 
          label: "Settings"
        )
      ]
    );
  }
}