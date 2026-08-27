import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/services/chat_service.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _chatService = ChatService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add contact"),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyTextfield(
            controller: _nameController, 
            obscureText: false, 
            hintText: "Name"
          ),
          SizedBox(height: 10),
          MyTextfield(
            controller: _emailController, 
            obscureText: false, 
            hintText: "Email"
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
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty && _emailController.text.trim().isNotEmpty) {
              Navigator.pop(context);
              final uid = await _chatService.getUserUIDByEmail(_emailController.text);
              if (uid == null) return;
              await _chatService.addContact(
                uid, 
                _nameController.text, 
                _emailController.text,
              );
            }
          },
          child: Text("Save", style: TextStyle(color: Colors.white))
        )
      ],
    );
  }
}