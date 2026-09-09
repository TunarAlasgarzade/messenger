import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';

class MessageOptions {
  final VoidCallback onDeleteButtonPressed;
  final VoidCallback onEditButtonPressed;
  final TextEditingController _editMessageController;
  MessageOptions(
    this.onDeleteButtonPressed,
    this.onEditButtonPressed,
    this._editMessageController, 
  );

  Future<void> showEditMessageDialog(BuildContext context) async {
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("Edit Message"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyTextfield(
              controller: _editMessageController, 
              obscureText: false, 
              hintText: "Message"
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary
            ),
            onPressed: () {
              Navigator.pop(context);
              onEditButtonPressed();
            },
            child: Text("Save", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }

  Future<void> showDeleteMessageDialog(BuildContext context) async {
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("Delete  Message?"),
        content: Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteButtonPressed();
            },
            child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.primary))
          )
        ],
      )
    );
  }
}