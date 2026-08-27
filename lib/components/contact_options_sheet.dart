import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/services/chat_service.dart';

class ContactOptionsSheet extends StatelessWidget {
  final String contactID;
  final String contactEmail;
  final String contactName;
  const ContactOptionsSheet({
    super.key, 
    required this.contactID,
    required this.contactEmail,
    required this.contactName
  });

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final editNameController = TextEditingController();
    final editEmailController = TextEditingController();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("Edit Contact"),
            onTap: () {
              Navigator.pop(context);
              editNameController.text = contactName;
              editEmailController.text = contactEmail;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Edit Contact"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyTextfield(
                        controller: editNameController, 
                        obscureText: false, 
                        hintText: "Name"
                      ),
                      SizedBox(height: 10),
                      MyTextfield(
                        controller: editEmailController, 
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
                        if (editNameController.text.trim().isNotEmpty && editEmailController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          final uid = await chatService.getUserUIDByEmail(editEmailController.text);
                          if (uid == null) return;
                          await chatService.updateContact(
                            uid, 
                            editNameController.text, 
                            editEmailController.text,
                          );
                        }
                      },
                      child: Text("Save", style: TextStyle(color: Colors.white))
                    )
                  ],
                ),
              );
            }
          ),
          ListTile(
            leading: Icon(Icons.block, color: Colors.orange),
            title: Text("Block Contact", style: TextStyle(color: Colors.orange)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context, 
                builder: (context) => AlertDialog(
                  title: Text("Block contact?"),
                  content: Text("Are you sure you want to block this contact? If you block this contact, you can unblock them from Settings > Blocked Users."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await chatService.blockContact(contactID, contactName, contactEmail);
                      }, 
                      child: Text("Block", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    )
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text("Delete Contact", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context, 
                builder: (context) => AlertDialog(
                  title: Text("Delete contact?"),
                  content: Text("Are you sure you want to delete the contact?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await chatService.deleteContact(contactID);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Contact Deleted", style: TextStyle(color: Colors.white)),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          )
                        );
                      }, 
                      child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}