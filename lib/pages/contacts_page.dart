import 'package:flutter/material.dart';
import 'package:messenger/components/add_contact_dialog.dart';
import 'package:messenger/components/contact_options_sheet.dart';
import 'package:messenger/components/contact_tile.dart';
import 'package:messenger/pages/chat_page.dart';
import 'package:messenger/services/chat_service.dart';
import 'package:messenger/services/profile_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _chatService = ChatService();
  final _profileService = ProfileService();
  String selectedContactID = "";
  String selectedContactName = "";
  String selectedContactEmail = "";
  bool isLongPressed = false;
  bool _isAddingContact = false;

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
          builder: (context) => AddContactDialog(
            onLoadingChanged: (isLoading) {
              setState(() {
                _isAddingContact = isLoading;
              });
            },
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: _isAddingContact ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactList() {
    return StreamBuilder(
      stream: _chatService.getContacts(), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        return StreamBuilder(
          stream: _chatService.getBlockedContacts(), 
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
                          return ContactTile(
                            profilePhoto: profileSnapshot.data,
                            contactName: contacts[index].data()["contactName"] ?? "", 
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
}