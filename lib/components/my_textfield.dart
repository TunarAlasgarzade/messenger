import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool obscureText;
  final int? minLines;
  final int? maxLines;
  const MyTextfield({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.hintText,
    this.onChanged,
    this.minLines,
    this.maxLines
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines ?? 1,
      minLines: minLines ?? 1,
      onChanged: onChanged,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2
          )
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2
          ),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey
        )
      ),
    );
  }
}