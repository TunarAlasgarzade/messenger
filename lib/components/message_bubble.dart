import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final String messageType;
  final bool isRead;
  final bool isCurrentUser;
  final bool isSelected;
  final Timestamp timestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const MessageBubble({
    super.key,
    required this.isCurrentUser,
    required this.isRead,
    required this.isSelected,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;
  bool hasStarted = false;

  Future<void> playAudio() async {
    hasStarted = true;
    await _player.play(UrlSource(widget.message));
  }

  Future<void> loadAudio() async {
    await _player.setSourceUrl(widget.message);
    final newDuration = await _player.getDuration();

    if (newDuration != null) {
      setState(() {
        duration = newDuration;
      });
    }
  }

  Future<void> pauseAudio() async {
    await _player.pause();
  }

  String formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;

    return "$minutes:${remainingSeconds.toString().padLeft(2, "0")}";
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = (state == PlayerState.playing);
      });
    });
    _player.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });
    _player.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
    loadAudio();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { 
    return Align(
      alignment: widget.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              width: widget.messageType == "image" ? 280 : widget.messageType == "audio" ? 300 : null,
              height: widget.messageType == "image" ? 280 : widget.messageType == "audio" ? 100 : null,
              margin: EdgeInsets.all(4),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isCurrentUser ? widget.isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6) 
                  : Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.isCurrentUser ? [
                  Flexible(
                    child: widget.messageType == "text" ? Text(
                      widget.message,
                      style: TextStyle(color: Colors.white),
                    ) : widget.messageType ==  "audio" ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: isPlaying == false ? playAudio : pauseAudio, 
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white)
                            ),
                            Slider(
                              value: position.inMilliseconds.toDouble(), 
                              onChanged: (value) {
                                _player.seek(
                                  Duration(milliseconds: value.toInt())
                                );
                              }, 
                              max: duration.inMilliseconds.toDouble(),
                              inactiveColor: Colors.grey.shade400,
                              activeColor: Colors.white
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            formatDuration(hasStarted ? position : duration),
                            style: TextStyle(color: Colors.white)
                          ),
                        )
                      ],
                    )
                    : GestureDetector(
                      child: Image.network(
                        widget.message,
                        width: 248,
                        height: 248,
                        fit: BoxFit.cover,
                      ),
                      onTap: () => showDialog(
                        context: context, 
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(widget.message)
                          ),
                        ),
                      ),
                    )
                  ),
                  SizedBox(width: 6),
                  Icon(
                    widget.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary == Colors.blue 
                    ? widget.isRead ? Colors.white70 : Colors.grey.shade400 
                    : widget.isRead ? Colors.blue : Colors.white70,
                  )
                ] : [
                  Flexible(
                    child: widget.messageType == "text" ? Text(
                      widget.message,
                      style: TextStyle(color: Colors.white),
                    ) : widget.messageType ==  "audio" ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: isPlaying == false ? playAudio : pauseAudio, 
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white)
                            ),
                            Slider(
                              value: position.inMilliseconds.toDouble(), 
                              onChanged: (value) {
                                _player.seek(
                                  Duration(milliseconds: value.toInt())
                                );
                              },
                              max: duration.inMilliseconds.toDouble(), 
                              inactiveColor: Theme.of(context).colorScheme.secondary,
                              activeColor: Colors.white
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Text(
                            formatDuration(hasStarted ? position : duration),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                    : GestureDetector(
                      child: Image.network(
                        widget.message,
                        width: 248,
                        height: 248,
                        fit: BoxFit.cover,
                      ),
                      onTap: () => showDialog(
                        context: context, 
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(widget.message)
                          ),
                        )
                      ),
                    )
                  ),
                ],
              ),
            ),
            Padding(
              padding: widget.isCurrentUser ? const EdgeInsets.only(right: 10) : const EdgeInsets.only(left: 10),
              child: Text(
                "${widget.timestamp.toDate().hour.toString().padLeft(2, '0')}:${widget.timestamp.toDate().minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}