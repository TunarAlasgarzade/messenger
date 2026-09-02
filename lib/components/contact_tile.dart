import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  final String contactName;
  final String? profilePhoto;
  final int unreadMessagesCount;
  final void Function()? onTap;
  final void Function()? onLongPress;
  const ContactTile({
    super.key,
    required this.contactName,
    required this.profilePhoto,
    required this.onTap,
    required this.onLongPress,
    required this.unreadMessagesCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
        padding: EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (profilePhoto != null) {
                  showDialog(
                    context: context, 
                    builder: (context) => Dialog(
                      child: InteractiveViewer(child: Image.network(profilePhoto!)),
                    )
                  );
                }
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                backgroundImage: profilePhoto != null ? NetworkImage(profilePhoto!) : null,
                child: profilePhoto == null 
                ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface) : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(contactName),
            const Spacer(),
            if (unreadMessagesCount > 0)
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 12,
                child: Text(
                  unreadMessagesCount.toString(),
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 12,
                  ),
                ),
              )
          ],
        )
      ),
    ); 
  }
}