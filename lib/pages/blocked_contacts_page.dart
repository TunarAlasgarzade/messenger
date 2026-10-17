import 'package:flutter/material.dart';
import 'package:messenger/services/contact_service.dart';

class BlockedContactsPage extends StatefulWidget {
  const BlockedContactsPage({super.key});

  @override
  State<BlockedContactsPage> createState() => _BlockedContactsPageState();
}

class _BlockedContactsPageState extends State<BlockedContactsPage> {
  final _contactService = ContactService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Blocked Contacts"),
      ),
      body: SafeArea(
        child: Center(
          child: StreamBuilder(
            stream: _contactService.getBlockedContacts(), 
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error");
              }
              if (snapshot.hasData) {
                if (snapshot.data!.docs.isEmpty) {
                  return Text("No blocked contacts");
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.block, color: Theme.of(context).colorScheme.onSurface,),
                      title: Text(snapshot.data!.docs[index].data()["contactName"]),
                      onTap: () {
                        showDialog(
                          context: context, 
                          builder: (context) => AlertDialog(
                            title: Text("Unblock Contact?"),
                            content: Text("Are you sure you want to unblock this contact?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context), 
                                child: Text("Cancel", style: TextStyle(color: Colors.green))
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _contactService.unblockContact(
                                    snapshot.data!.docs[index].data()["contactID"]
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Contact Unblocked!", 
                                        style: TextStyle(color: Colors.white)
                                      ),
                                      backgroundColor: Colors.green,
                                    )
                                  );
                                }, 
                                child: Text("Unblock", style: TextStyle(color: Colors.green))
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return Text("Loading..");
            },
          ),
        )
      ),
    );
  }
}