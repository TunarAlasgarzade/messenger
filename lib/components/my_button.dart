import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  const MyButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: Text(text, style: TextStyle(color: Colors.white))
    );
  }
}