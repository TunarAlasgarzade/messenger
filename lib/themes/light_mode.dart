import 'package:flutter/material.dart';

ThemeData lightMode(Color color) {
  return ThemeData(
    colorScheme: ColorScheme.light(
      surface: Colors.white,
      primary: color,
      secondary: Colors.grey.shade300,
      tertiary: Colors.grey,
    )
  );
}