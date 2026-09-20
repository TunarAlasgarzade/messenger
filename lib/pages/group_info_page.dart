import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/pages/home_page.dart';
import 'package:messenger/services/chat_service.dart';
import 'package:messenger/services/group_chat_service.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupName;
  final String groupID;
  const GroupInfoPage({
    super.key, 
    required this.groupName,
    required this.groupID,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final _groupChatService = GroupChatService();
  final _chatService = ChatService();
  final _renameGroupController = TextEditingController();
  final userID = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> contactNames = {};
  Map<String, String> memberEmails = {};
  String? groupName;
  bool isAdmin = false;
  bool membersCanEditInfo = false;

  Future<void> _addMember() async {
    List<String> selectedUsers = [];
    final groupMemberSnapshot = await _firestore
        .collection("Groups")
        .doc(widget.groupID)
        .collection("members")
        .get();
    final groupMembersIds = groupMemberSnapshot.docs
        .map((doc) => doc["uid"] as String)
        .toSet();

    if(!mounted) return;
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Add Member"),
          content:  StreamBuilder(
            stream: _chatService.getContacts(), 
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final contacts = snapshot.data!.docs
                    .where((contact) => !groupMembersIds.contains(contact["contactID"]))
                    .toList();

                if (contacts.isEmpty) {
                  return Text("No users to add.");
                }

                return SizedBox(
                  width: 300,
                  height: 206,
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: Checkbox(
                          value: selectedUsers.contains(contact["contactID"]), 
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedUsers.add(contact["contactID"]);
                              } else {
                                selectedUsers.remove(contact["contactID"]);
                              }
                            });
                          },
                        ),
                        title: Text(contact["contactName"]),
                      );
                    },
                  ),
                );
              } else {
                return Text("Loading..");
              }
            },
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
                if (selectedUsers.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _groupChatService.addMember(widget.groupID, selectedUsers);
                    selectedUsers = [];
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Members added successfully!",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.green,
                      )
                    );
                  } catch (e) {
                    selectedUsers = [];
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll("Exception: ", ""),
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text("Save", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadContacts() async {
    final snapshot = await FirebaseFirestore
      .instance
      .collection("Users")
      .doc(userID)
      .collection("contacts")
      .get();

    for (final contact in snapshot.docs) {
      contactNames[contact["contactID"]] = contact["contactName"];
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadEmails() async {
    final snapshot = await FirebaseFirestore
      .instance
      .collection("Groups")
      .doc(widget.groupID)
      .collection("members")
      .get();

    for (final member in snapshot.docs) {
      memberEmails[member["uid"]] = member["email"];
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _checkAdmin() async {
    final memberDoc = await _firestore
        .collection("Groups")
        .doc(widget.groupID)
        .collection("members")
        .doc(userID)
        .get();
    
    if (!mounted) return;
    setState(() {
      isAdmin = memberDoc.data()?["role"] == "admin";
    });
  }

  Future<void> _loadGroupSettings() async {
    final bool canMembersEditInfo = (
      await _firestore.collection("Groups").doc(widget.groupID).get()
    ).data()?["canMembersEditInfo"] ?? false;

    if (!mounted) return;
    setState(() {
      membersCanEditInfo = canMembersEditInfo;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadEmails();
    _checkAdmin();
    _loadGroupSettings();
    groupName = widget.groupName;
  }

  @override
  void dispose() {
    _renameGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName ?? ""),
        actions: isAdmin || membersCanEditInfo ? [
          IconButton(
            onPressed: () {
              _renameGroupController.text = groupName ?? "";
              showDialog(
                context: context, 
                builder: (context) =>  AlertDialog(
                  title: Text("Rename Group"),
                  content: MyTextfield(
                    controller: _renameGroupController, 
                    obscureText: false, 
                    hintText: "New Name"
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
                        if (_renameGroupController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          try {
                            await _groupChatService.renameGroup(
                              widget.groupID, _renameGroupController.text
                            );
                            setState(() {
                              groupName = _renameGroupController.text;
                            });
                            _renameGroupController.text = "";
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Group name updated successfully!",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.green,
                              )
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll("Exception: ", ""),
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text("Save", style: TextStyle(color: Colors.white))
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.edit)
          )
        ] : [],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: isAdmin,
                child: SwitchListTile(
                  title: Text("Members can edit group info"),
                  subtitle: Text("Allow all members to edit group name"),
                  value: membersCanEditInfo, 
                  onChanged: (value) async {
                    _groupChatService.setMembersCanEditInfo(widget.groupID, value);
                    setState(() {
                      membersCanEditInfo = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 12),
                  Text(
                    "Members", style: TextStyle(
                      color: Theme.of(context).colorScheme.primary, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _groupChatService.getMembers(widget.groupID), 
                  builder: (context, snapshot) {
                    return ListView.builder(
                      itemCount: snapshot.hasData ? snapshot.data!.docs.length : 0,
                      itemBuilder: (context, index) {
                        final members = snapshot.data!.docs[index].data();
                        final String memberName;
                        if (members["uid"] == userID) {
                          memberName = "You";
                        } else {
                          memberName = contactNames[members["uid"]] ?? memberEmails[members["uid"]] ?? "";
                        }
                        final memberRole = members["role"];
                        return ListTile(
                          title: Text(memberName),
                          subtitle: Text(memberRole),
                          trailing: isAdmin && members["uid"] != userID ? PopupMenuButton(
                            icon: Icon(Icons.more_vert), 
                            onSelected: (value) async {
                              if (value == "remove") {
                                showDialog(
                                  context: context, 
                                  builder: (context) => AlertDialog(
                                    title: Text("Remove member?"),
                                    content: Text("Are you sure you want to remove this member from the group?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context), 
                                        child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          try {
                                            await _groupChatService.removeMember(
                                              widget.groupID, members["uid"]
                                            );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Member removed successfully!",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  e.toString().replaceAll("Exception: ", ""),
                                                  style: TextStyle(
                                                    color: Colors.white, 
                                                    fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }, 
                                        child: Text("Remove", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (value == "make admin") {
                                try {
                                  await _groupChatService.makeAdmin(
                                    widget.groupID, members["uid"]
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Member promoted to admin successfully!",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                    )
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll("Exception: ", ""),
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                              if (value == "remove admin") {
                                try {
                                  await _groupChatService.removeAdmin(
                                    widget.groupID, members["uid"]
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Admin role removed successfully!",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                    )
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll("Exception: ", ""),
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => members["role"] == "member" ? [
                              PopupMenuItem(
                                value: "make admin",
                                child: Text("Make group admin")
                              ),
                              PopupMenuItem(
                                value: "remove",
                                child: Text("Remove from group", style: TextStyle(color: Colors.red))
                              ),
                            ] : [
                              PopupMenuItem(
                                value: "remove admin",
                                child: Text("Dismiss as admin")
                              ),
                              PopupMenuItem(
                                value: "remove",
                                child: Text("Remove from group", style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ) : null
                        );
                      },
                    );
                  },
                ),
              ),
              Visibility(
                visible: isAdmin,
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text("Add Member"),
                  onTap: () async {
                    await _addMember();
                  },
                )
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  "Exit group",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                ),
                onTap: () => showDialog(
                  context: context, 
                  builder: (context) => AlertDialog(
                    title: Text("Exit group?"),
                    content: Text("Are you sure you want to exit the group?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text(
                          "Cancel", style: TextStyle(
                            color: Theme.of(context).colorScheme.primary
                          ),
                        )
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _groupChatService.leaveGroup(widget.groupID);
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            this.context, MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                            (route) => false
                          );
                        }, 
                        child: Text(
                          "Exit", style: TextStyle(
                            color: Theme.of(context).colorScheme.primary
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}