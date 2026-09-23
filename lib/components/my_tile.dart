import 'package:flutter/material.dart';

class MyTile extends StatelessWidget {
  final String title;
  final String? photo;
  final String lastMessage;
  final int? unreadMessagesCount;
  final bool isGroup;
  final void Function()? onTap;
  final void Function()? onLongPress;
  const MyTile({
    super.key,
    required this.title,
    required this.lastMessage,
    required this.isGroup,
    required this.onTap,
    this.onLongPress,
    this.photo,
    this.unreadMessagesCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          if (photo != null) {
            showDialog(
              context: context, 
              builder: (context) => Dialog(
                child: InteractiveViewer(child: Image.network(photo!)),
              )
            );
          }
        },
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          backgroundImage: photo != null ? NetworkImage(photo!) : null,
          child: photo == null
          ? Icon(!isGroup ? Icons.person : Icons.group, color: Theme.of(context).colorScheme.onSurface) : null,
        ),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: unreadMessagesCount != 0 
          ? FontWeight.bold 
          : FontWeight.normal
        )
      ),
      subtitle: Text(
        lastMessage, 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadMessagesCount != 0 
          ? FontWeight.bold 
          : FontWeight.normal
        )
      ),
      trailing: unreadMessagesCount != null && unreadMessagesCount != 0 ? CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        radius: 12,
        child: Text(
          unreadMessagesCount.toString(),
          style: TextStyle(
            color: Colors.white, 
            fontSize: 12,
          ),
        ),
      ) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}