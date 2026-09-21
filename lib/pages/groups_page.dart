import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/components/my_tile.dart';
import 'package:messenger/pages/group_chat_page.dart';
import 'package:messenger/services/chat_service.dart';
import 'package:messenger/services/group_chat_service.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _createGroupController = TextEditingController();
  final _groupChatService = GroupChatService();
  final _chatService = ChatService();
  List<String> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("Groups", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: _buildGroupList()
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context, 
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text("Create Group"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextfield(
                    controller: _createGroupController, 
                    obscureText: false, 
                    hintText: "Group Name"
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 12),
                      Text(
                        "Select Members", style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Flexible(
                    child: StreamBuilder(
                      stream: _chatService.getContacts(), 
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return SizedBox(
                            width: 300,
                            height: 206,
                            child: ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final contacts = snapshot.data!.docs[index];
                                return ListTile(
                                  leading: Checkbox(
                                    value: selectedUsers.contains(contacts["contactID"]), 
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedUsers.add(contacts["contactID"]);
                                        } else {
                                          selectedUsers.remove(contacts["contactID"]);
                                        }
                                      });
                                    },
                                  ),
                                  title: Text(contacts["contactName"]),
                                );
                              },
                            ),
                          );
                        } else {
                          return Text("Loading..");
                        }
                      },
                    ),
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
                    if (_createGroupController.text.trim().isNotEmpty && selectedUsers.isNotEmpty) {
                      Navigator.pop(context);
                      _groupChatService.createGroup(
                        _createGroupController.text, 
                        Timestamp.now(),
                        selectedUsers
                      );
                      _createGroupController.clear();
                      selectedUsers = [];
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white))
                )
              ],
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder(
      stream: _groupChatService.getGroups(), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Text("You have no groups yet");
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final groups = snapshot.data![index];
              return MyTile(
                isGroup: true,
                title: groups["name"], 
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(
                    builder: (context) => GroupChatPage(
                      groupName: groups["name"],
                      groupID: groups.id,
                    )
                  )
                ),
              );
            },
          );
        } else {
          return Text("Loading..");
        }
      },
    );
  }
}