import 'package:flutter/material.dart';
import 'package:messenger/components/contact_options_sheet.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/components/my_tile.dart';
import 'package:messenger/pages/chat_page.dart';
import 'package:messenger/services/chat_service.dart';
import 'package:messenger/services/contact_service.dart';
import 'package:messenger/services/profile_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _chatService = ChatService();
  final _contactService = ContactService();
  final _profileService = ProfileService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String selectedContactID = "";
  String selectedContactName = "";
  String selectedContactEmail = "";
  bool isLongPressed = false;
  bool _isAddingContact = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("Chats", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: _buildContactList()
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isAddingContact ? null : showDialog(
          context: context, 
          builder: (context) => _addContactDialog(
            (isLoading) {
              if (!mounted) return;
              setState(() {
                _isAddingContact = isLoading;
              });
            },
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: _isAddingContact ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildContactList() {
    return StreamBuilder(
      stream: _contactService.getContacts(), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        return StreamBuilder(
          stream: _contactService.getBlockedContacts(), 
          builder: (context, blockedSnapshot) {
            if (blockedSnapshot.hasError) {
              return const Text("Error");
            }
            if (snapshot.hasData) {
              final blockedIDs = blockedSnapshot.hasData 
                ? blockedSnapshot.data!.docs.map((doc) => doc.id).toSet() 
                : <String>{}; 
              final contacts = snapshot.data!.docs
                .where((doc) => !blockedIDs.contains(doc.id)).toList(); 
              
              if (contacts.isEmpty) {
                return Text("No contacts added");
              }  
              return ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return StreamBuilder<String?>(
                    stream: _profileService.getOtherUserProfilePhoto(
                      contacts[index].data()["contactID"]
                    ), 
                    builder: (context, profileSnapshot) {
                      return StreamBuilder<int>(
                        stream: _chatService.getUnreadMessagesCount(contacts[index].data()["contactID"]),
                        builder: (context, unreadSnapshot) {
                          return StreamBuilder(
                            stream: _chatService.getLastMessage(contacts[index].data()["contactID"]), 
                            builder: (context, lastMessageSnapshot) {
                              String? lastMessage;
                              if (lastMessageSnapshot.hasData && lastMessageSnapshot.data!.docs.isNotEmpty) {
                                final data = lastMessageSnapshot.data!.docs.first.data();

                                if (data["messageType"] == "text") {
                                  lastMessage = data["message"];
                                } else if (data["messageType"] == "image") {
                                  lastMessage = "🖼️ Picture";
                                } else if (data["messageType"] == "audio") {
                                  lastMessage = "🎤️ Voice message";
                                }
                              }

                              return MyTile(
                                isGroup: false,
                                photo: profileSnapshot.data,
                                title: contacts[index].data()["contactName"] ?? "", 
                                lastMessage: lastMessage ?? "",
                                unreadMessagesCount: unreadSnapshot.data ?? 0,
                                onTap: () {
                                  if (isLongPressed == false) {
                                    Navigator.push(
                                      context, MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          receiverName: contacts[index].data()["contactName"],
                                          receiverID: contacts[index].data()["contactID"],
                                        )
                                      ) 
                                    );
                                  } else {
                                    setState(() {
                                      selectedContactID = "";
                                      isLongPressed = false;
                                    });
                                  }
                                }, 
                                onLongPress: () {
                                  setState(() {
                                    selectedContactID = contacts[index].id;
                                    selectedContactName = contacts[index].data()["contactName"];
                                    selectedContactEmail = contacts[index].data()["contactEmail"];
                                    isLongPressed = true;
                                  });
                                  showModalBottomSheet(
                                    context: context, 
                                    builder: (context) => ContactOptionsSheet(
                                      contactID: selectedContactID,
                                      contactEmail: selectedContactEmail,
                                      contactName: selectedContactName,
                                    ),
                                  );
                                }, 
                              );
                            },
                          );
                        }
                      );
                    },
                  );
                },
              );
            }
            return Text("Loading..");
          },
        );
      },
    );
  }

  Widget _addContactDialog(void Function(bool) onLoadingChanged) {
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
              onLoadingChanged(true);
              Navigator.pop(context);
              try {
                final uid = await _contactService.getUserUIDByEmail(_emailController.text);
                if (uid == null) {
                  onLoadingChanged(false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "User not found.", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      backgroundColor: Colors.red,
                    )
                  );
                } else {
                  await _contactService.addContact(
                    uid, 
                    _nameController.text, 
                    _emailController.text,
                  );
                  onLoadingChanged(false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Contact added successfully!", 
                        style: TextStyle(
                          color: Colors.white, 
                        ),
                      ),
                      backgroundColor: Colors.green,
                    )
                  );
                }
              } catch (e) {
                onLoadingChanged(false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Something went wrong.", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    backgroundColor: Colors.red,
                  )
                );
              }
            }
          },
          child: Text("Save", style: TextStyle(color: Colors.white))
        )
      ],
    );
  }
}