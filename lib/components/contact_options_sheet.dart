import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/services/contact_service.dart';

class ContactOptionsSheet extends StatefulWidget {
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
  State<ContactOptionsSheet> createState() => _ContactOptionsSheetState();
}

class _ContactOptionsSheetState extends State<ContactOptionsSheet> {
  final contactService = ContactService();
  final _editNameController = TextEditingController();
  final _editEmailController = TextEditingController();

  @override
  void dispose() {
    _editNameController.dispose();
    _editEmailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Container(
            width: 33.5,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 5),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("Edit Contact"),
            onTap: () {
              Navigator.pop(context);
              _editNameController.text = widget.contactName;
              _editEmailController.text = widget.contactEmail;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Edit Contact"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyTextfield(
                        controller: _editNameController, 
                        obscureText: false, 
                        hintText: "Name"
                      ),
                      SizedBox(height: 10),
                      MyTextfield(
                        controller: _editEmailController, 
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
                        if (_editNameController.text.trim().isNotEmpty && _editEmailController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          final uid = await contactService.getUserUIDByEmail(_editEmailController.text);
                          if (uid == null) return;
                          await contactService.updateContact(
                            uid, 
                            _editNameController.text, 
                            _editEmailController.text,
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
                        await contactService.blockContact(widget.contactID, widget.contactName, widget.contactEmail);
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
                        await contactService.deleteContact(widget.contactID);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text("Contact Deleted", style: TextStyle(color: Colors.white)),
                            backgroundColor: Theme.of(this.context).colorScheme.primary,
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