import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger/components/message_bubble.dart';
import 'package:messenger/components/message_options.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/services/chat_service.dart';
import 'package:messenger/services/profile_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final userID = FirebaseAuth.instance.currentUser!.uid;
  final _messageController = TextEditingController();
  final _editMessageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _profileService = ProfileService();
  final player = AudioPlayer();
  StreamSubscription? _messageSubscription;
  String selectedMessageType = "";
  String selectedDocumentID = "";
  XFile? _selectedImage;
  Timer? timer;
  bool isLongPressed = false;
  bool isSendingImage = false;
  bool isFirstLoad = false;
  bool isRecording = false;
  int seconds = 0;

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> recordAudio() async {
    final hasPermission = await _recorder.hasPermission(request: true);

    if (hasPermission) {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/audioMessage_${DateTime.now()}.opus";
      final config = RecordConfig(
        encoder: AudioEncoder.opus,
        sampleRate: 44100,
        numChannels: 1,
      );
      await _recorder.start(config, path: path);
      setState(() {
        isRecording = true;
      });
      timer = Timer.periodic(
        const Duration(seconds: 1), 
        (timer) {
          setState(() {
            seconds++;
          });
        }
      );
    } else {
      await _recorder.hasPermission(request: true);
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      isRecording = false;
    });
    timer!.cancel();
    seconds = 0;
    return path;
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    setState(() {
      isRecording = false;
    });
    timer!.cancel();
    seconds = 0;
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return "$minutes:${remainingSeconds.toString().padLeft(2, "0")}";
  }

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
        title: Row(
          children: [
            StreamBuilder<String?>(
              stream: _profileService.getReceiverProfilePhoto(widget.receiverID),
              builder: (context, snapshot) {
                return GestureDetector(
                  onTap: () {
                    if (snapshot.data != null) {
                      showDialog(
                        context: context, 
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(snapshot.data!)
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 18.5,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    backgroundImage: snapshot.data != null ? NetworkImage(snapshot.data!) : null,
                    child: snapshot.data == null 
                    ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface) : null,
                  ),
                );
              },
            ),
            SizedBox(width: 15),
            Column(
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
                      stream: FirebaseFirestore.instance.collection("Users").doc(widget.receiverID).collection("profile").doc("data").snapshots(), 
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!.data()?["isOnline"] == true ? "Online" : "Offline",
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          );
                        }
                        return Text("", style: TextStyle(fontSize: 13));
                      },
                    );
                  }, 
                )
              ],
            ),
          ],
        ),
        actions: isLongPressed == true ? [
          Visibility(
            visible: selectedMessageType == "text",
            child: IconButton(
              onPressed: () {
                final messageID = selectedDocumentID;
                MessageOptions(
                  () {}, 
                  () async {
                    setState(() {
                      isLongPressed = false;
                      selectedDocumentID = "";
                    });
                    if (_editMessageController.text.trim().isNotEmpty) {
                      await _chatService.updateMessage(
                        _editMessageController.text, 
                        widget.receiverID, 
                        messageID
                      );
                      _editMessageController.clear();
                    }
                  }, 
                  _editMessageController
                ).showEditMessageDialog(context);
              },
              icon: Icon(Icons.edit),
            ),
          ),
          IconButton(
            onPressed: () async {
              await MessageOptions(
                () {
                  setState(() {
                    isLongPressed = false;
                  });
                  _chatService.deleteMessage(
                    userID, 
                    widget.receiverID, 
                    selectedDocumentID
                  );
                }, 
                () {}, 
                _editMessageController
              ).showDeleteMessageDialog(context);
            }, 
            icon: Icon(Icons.delete)
          ),
        ] : [],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildMessageList(),
            _buildUserInput()
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        userID, widget.receiverID
      ), 
      builder: (context, snapshot) {
        return Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
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
      messageType: data["messageType"],
      timestamp: timestamp,
      onTap: () => setState(() {
        isLongPressed = false;
        selectedDocumentID = "";
        selectedMessageType = "";
      }),
      onLongPress: () {
        if (senderID == userID) {
          setState(() {
            selectedDocumentID = doc.id;
            _editMessageController.text = data["message"];
            selectedMessageType = data["messageType"];
            isLongPressed = true;
          });
        }
      },
    );
  }

  Widget _buildUserInput() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 5),
          child: IconButton(
            onPressed: () {
              if (!isRecording) {
                pickImage();
              } else {
                cancelRecording();
              }
            }, 
            icon: Icon(!isRecording ? Icons.image : Icons.delete)
          ),
        ),
        !isRecording && _selectedImage == null ? Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 5, bottom: 10, top: 5),
            child: MyTextfield(
              controller: _messageController, 
              obscureText: false, 
              maxLines: 5,
              hintText: "Type a message",
              onChanged: (value) {
                setState(() {});
                _chatService.setTypingStatus(widget.receiverID, value.trim().isNotEmpty);
              },
            ),
          ),
        ) : !isRecording && _selectedImage != null ? Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 5, bottom: 10, top: 5),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  child: Image.file(File(_selectedImage!.path)),
                  onTap: () => showDialog(
                    context: context, 
                    builder: (context) => Dialog(
                      child: InteractiveViewer(
                        child: Image.file(File(_selectedImage!.path))
                      ),
                    )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10),
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 20,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: Icon(Icons.cancel, color: Colors.white)
                    ),
                  ),
                ),
              ]
            ),
          )
        ) : Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text("Recording..    ${formatDuration(seconds)}")
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
              onPressed: isSendingImage ? null : () async {
                if (_messageController.text.trim().isNotEmpty && _selectedImage == null) {
                  await _chatService.sendTextMessage(
                    _messageController.text, widget.receiverID
                  );
                } else if (_selectedImage != null) {
                  setState(() {
                    isSendingImage = true;
                  });
                  await _chatService.sendImageMessage(
                    _selectedImage!, widget.receiverID
                  );
                  setState(() {
                    isSendingImage = false;
                  });
                } else if (isRecording == true) {
                  final path = await stopRecording();
                  _chatService.sendVoiceMessage(path.toString(), widget.receiverID);
                }
                _messageController.text = "";
                setState(() {
                  _selectedImage = null;
                });
                _chatService.setTypingStatus(widget.receiverID, false);
              }, 
              onLongPress: () => recordAudio(),
              icon: isSendingImage 
              ? CircularProgressIndicator(color: Colors.white) 
              : Icon(
                isRecording || _messageController.text.trim().isNotEmpty ? Icons.arrow_upward : Icons.mic, 
                color: Colors.white
              )
            ),
          ),
        ),
      ],
    );
  }
}