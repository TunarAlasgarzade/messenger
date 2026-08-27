import 'package:flutter/material.dart';
import 'package:messenger/themes/dark_mode.dart';
import 'package:messenger/themes/light_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier{
  bool isDarkMode = false;
  Color _accentColor = Colors.green;

  ThemeData get themeData => isDarkMode ? darkMode(_accentColor) : lightMode(_accentColor);
  Color get accentColor => _accentColor; 

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", isDarkMode);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getBool("isDarkMode");

    if (savedTheme != null) {
      isDarkMode = savedTheme;
    }
  }

  Future<void> changeAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("accentColor", color.toARGB32());
    notifyListeners();
  }

  Future<void> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt("accentColor");

    if (savedColor != null) {
      _accentColor = Color(savedColor);
    }
  }
}