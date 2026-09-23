import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/group_message_bubble.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/pages/group_info_page.dart';
import 'package:messenger/services/group_chat_service.dart';

class GroupChatPage extends StatefulWidget {
  final String groupName;
  final String groupID;
  const GroupChatPage({
    super.key,
    required this.groupName,
    required this.groupID
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _messageController = TextEditingController();
  final _editMessageController = TextEditingController();
  final _groupChatService = GroupChatService();
  final userID = FirebaseAuth.instance.currentUser!.uid;
  String selectedDocumentID = "";
  String selectedMessage = "";
  bool isLongPressed = false;
  Map<String, String> contactNames = {};
  Map<String, String> memberEmails = {};

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

  bool isSameDay(Timestamp first, Timestamp second) {
    final firstDate = first.toDate();
    final secondDate = second.toDate();

    return firstDate.year == secondDate.year && 
    firstDate.month == secondDate.month && 
    firstDate.day == secondDate.day;
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return "Yesterday";
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadEmails();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _editMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: GestureDetector(
          child: Text(
            widget.groupName, 
            style: TextStyle(color: Colors.white)
          ),
          onTap: () => Navigator.push(
            context, MaterialPageRoute(
              builder: (context) => GroupInfoPage(
                groupName: widget.groupName,
                groupID: widget.groupID,
              )
            )
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white
        ),
        actions: isLongPressed ? [
          IconButton(
            onPressed: () {
              _editMessageController.text = selectedMessage;
              showDialog(
                context: context, 
                builder: (context) => AlertDialog(
                  title: Text("Edit Message"),
                  content: MyTextfield(
                    controller: _editMessageController, 
                    obscureText: false, 
                    hintText: "New Message"
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (_editMessageController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _groupChatService.updateMessage(
                            selectedDocumentID, 
                            _editMessageController.text, 
                            widget.groupID
                          );
                          _editMessageController.clear();
                          setState(() {
                            isLongPressed = false;
                            selectedDocumentID = "";
                            selectedMessage = "";
                          });
                        }
                      },
                      child: Text("Save", style: TextStyle(color: Colors.white))
                    )
                  ],
                ),
              );
            }, 
            icon: Icon(Icons.edit)
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context, 
                builder: (context) => AlertDialog(
                  title: Text("Delete Message?"),
                  content: Text("Are you sure you want to delete this message?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _groupChatService.deleteMessage(selectedDocumentID, widget.groupID);
                        setState(() {
                          isLongPressed = false;
                          selectedDocumentID = "";
                        });
                      },
                      child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                    )
                  ],
                ),
              );
            }, 
            icon: Icon(Icons.delete)
          )
        ] : [],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildMessageList(),
            _buildUserInput()
          ],
        )
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _groupChatService.getMessages(
        widget.groupID
      ), 
      builder: (context, snapshot) {
        return Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: snapshot.hasData ? snapshot.data!.docs.length : 0,
            itemBuilder: (context, index) {
              final currentDoc = snapshot.data!.docs[index];
              final currentTimestamp = currentDoc["timestamp"] as Timestamp;
              final bool hasOlderMessage = index + 1 < snapshot.data!.docs.length;
              Timestamp? olderTimestamp;
              if (hasOlderMessage) {
                olderTimestamp = snapshot.data!.docs[index + 1]["timestamp"] as Timestamp;
              }
              final bool showDateSeparator = 
                index == snapshot.data!.docs.length - 1 ||
                (olderTimestamp == null ? true 
                : !isSameDay(currentTimestamp, olderTimestamp));
              return Column(
                children: [
                  if (showDateSeparator)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formatDate(currentTimestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        )
                      ),
                    ),
                  _buildMessageItem(snapshot.data!.docs[index]),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final senderID = data["senderID"];
    final timestamp = data["timestamp"] as Timestamp;
    return GroupMessageBubble(
      message: data["message"], 
      messageType: "text", 
      timestamp: timestamp, 
      isCurrentUser: senderID == userID, 
      isSelected: selectedDocumentID == doc.id,
      senderName: contactNames[senderID] ?? memberEmails[senderID] ?? "",
      onLongPress: () {
        if (senderID == userID) {
          setState(() {
            isLongPressed = true;
            selectedDocumentID = doc.id;
            selectedMessage = data["message"];
          });
        }
      },
      onTap: () {
        if (senderID == userID) {
          setState(() {
            isLongPressed = false;
            selectedDocumentID = "";
            selectedMessage = "";
          });
        }
      },
    );
  }

  Widget _buildUserInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 5, bottom: 10),
            child: MyTextfield(
              controller: _messageController, 
              obscureText: false,
              maxLines: 5,
              hintText: "Type a message"
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 10, bottom: 10),
          child: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(30)
            ),
            child: IconButton(
              onPressed: () async {
                if (_messageController.text.trim().isNotEmpty) {
                  await _groupChatService.sendMessage(
                    _messageController.text, 
                    widget.groupID
                  );
                  _messageController.text = "";
                }
              }, 
              icon: Icon(Icons.arrow_upward, color: Colors.white)
            ),
          ),
        )
      ],
    );
  }
}