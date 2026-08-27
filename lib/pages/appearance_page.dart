import 'package:flutter/material.dart';
import 'package:messenger/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Appearance"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 15, right: 15, left: 15),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Dark Mode"),
                    Switch(
                      value: Provider.of<ThemeProvider>(context).isDarkMode, 
                      onChanged: (value) {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                      },
                    )
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15, right: 15, left: 15),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Accent Color"),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.green);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.green ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.red);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.red ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.blue);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.blue ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.cyan);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.cyan ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.yellow.shade800);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.yellow.shade800,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.yellow.shade800 ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.pink);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.pink,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.pink ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).changeAccentColor(Colors.purple);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.purple,
                            radius: 20,
                            child: themeProvider.accentColor == Colors.purple ? Icon(Icons.done, color: Colors.white) : null,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}