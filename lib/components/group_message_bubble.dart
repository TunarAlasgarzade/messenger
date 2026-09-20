import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupMessageBubble extends StatelessWidget {
  final String message;
  final String messageType;
  final String senderName;
  final bool isCurrentUser;
  final bool isSelected;
  final Timestamp timestamp;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.isCurrentUser,
    required this.isSelected,
    required this.senderName,
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
                color: isCurrentUser 
                    ? isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6) 
                      : Theme.of(context).colorScheme.primary 
                    : isSelected 
                      ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6) 
                      : Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [ 
                  if (isCurrentUser == false)
                    Text(
                      senderName, style: TextStyle(
                        color: Color.lerp(
                          Theme.of(context).colorScheme.primary, 
                          Colors.black, 
                          0.15
                        )
                      )
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}