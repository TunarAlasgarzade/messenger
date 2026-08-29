import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/message_bubble.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  final String receiverID;
  const ChatPage({
    super.key,
    required this.receiverName,
    required this.receiverID
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final userID = FirebaseAuth.instance.currentUser!.uid;
  final _messageController = TextEditingController();
  final _editMessageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final player = AudioPlayer();
  StreamSubscription? _messageSubscription;
  String selectedDocumentID = "";
  bool isLongPressed = false;
  bool isFirstLoad = false;

  @override
  void initState() {
    super.initState();
    isFirstLoad = true;
    _messageSubscription = _chatService.getMessages(
      userID, 
      widget.receiverID
    ).listen(
      (snapshot) {
        if (isFirstLoad == true) {
          isFirstLoad = false;
        } else {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              if (change.doc.data()?["senderId"] != userID) {
                player.play(AssetSource("music/message.mp3"));
                _chatService.markAsRead(widget.receiverID, change.doc.id);
              }
            }
          }
        }
      }
    );
    _chatService.markUnreadMessagesAsRead(widget.receiverID);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _editMessageController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(
          color: Colors.white
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: TextStyle(color: Colors.white)),
            StreamBuilder(
              stream: _chatService.getTypingStatus(widget.receiverID), 
              builder: (context, typingSnapshot) {
                if (typingSnapshot.hasData && typingSnapshot.data!.data()?["isTyping"] == true) {
                  return Text(
                    "${widget.receiverName} is typing",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  );
                }
                return StreamBuilder(
                  stream: FirebaseFirestore.instance.collection("Users").doc(widget.receiverID).snapshots(), 
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!.data()!["isOnline"] == true ? "Online" : "Offline",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      );
                    }
                    return Text("");
                  },
                );
              }, 
            )
          ],
        ),
        actions: isLongPressed == true ? [
          IconButton(
            onPressed: () {
              final messageID = selectedDocumentID;
              showDialog(
                context: context, builder: (context) => AlertDialog(
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
                      onPressed: () async {
                        if (_editMessageController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          await _chatService.updateMessage(
                            _editMessageController.text, 
                            widget.receiverID, 
                            messageID
                          );
                          _editMessageController.clear();
                        }
                      },
                      child: Text("Save", style: TextStyle(color: Colors.white))
                    )
                  ],
                ),
              );
              setState(() {
                isLongPressed = false;
                selectedDocumentID = "";
              });
            },
            icon: Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isLongPressed = false;
                _chatService.deleteMessage(
                  userID, 
                  widget.receiverID, 
                  selectedDocumentID
                );
              });
            }, 
            icon: Icon(Icons.delete)
          ),
        ] : [],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMessageList(),
          _buildUserInput()
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        userID, widget.receiverID
      ), 
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent, 
            duration: Duration(milliseconds: 300), 
            curve: Curves.easeOut
          );
        });
        return Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: snapshot.hasData ? snapshot.data?.docs.length : 0,
            itemBuilder: (context, index) {
              return _buildMessageItem(snapshot.data!.docs[index]);
            }
          )
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isRead = data["isRead"] as bool? ?? false;
    final senderID = data["senderId"];
    final timestamp = data["timestamp"] as Timestamp;
    return MessageBubble( 
      isCurrentUser: senderID == userID, 
      isRead: isRead, 
      isSelected: selectedDocumentID == doc.id, 
      message: data["message"],
      timestamp: timestamp,
      onTap: () => setState(() {
        isLongPressed = false;
        selectedDocumentID = "";
      }),
      onLongPress: () {
        if (senderID == userID) {
          setState(() {
            selectedDocumentID = doc.id;
            _editMessageController.text = data["message"];
            isLongPressed = true;
          });
        }
      },
    );
  }

  Widget _buildUserInput() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 5, bottom: 10, top: 5),
            child: MyTextfield(
              controller: _messageController, 
              obscureText: false, 
              hintText: "Type a message",
              onChanged: (value) {
                _chatService.setTypingStatus(widget.receiverID, value.trim().isNotEmpty);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 10, bottom: 10, top: 5),
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
                  await _chatService.sendMessage(
                    _messageController.text, widget.receiverID, widget.receiverName
                  );
                }
                _messageController.text = "";
                _chatService.setTypingStatus(widget.receiverID, false);
              }, 
              icon: Icon(Icons.arrow_upward, color: Colors.white)
            ),
          ),
        ),
      ],
    );
  }
}