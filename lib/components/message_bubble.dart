import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
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
    required this.timestamp,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) { 
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.all(4),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentUser ? isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6) 
                  : Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: isCurrentUser ? [
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary == Colors.blue 
                    ? isRead ? Colors.white70 : Colors.grey.shade400 
                    : isRead ? Colors.blue : Colors.white70,
                  )
                ] : [
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: isCurrentUser ? const EdgeInsets.only(right: 10) : const EdgeInsets.only(left: 10),
              child: Text(
                "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }
}