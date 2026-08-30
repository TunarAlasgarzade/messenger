import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/pages/login_page.dart';
import 'package:messenger/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final userEmail = FirebaseAuth.instance.currentUser!.email;
  final _authService = AuthService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("Profile", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text("Email"),
                subtitle: SelectableText(userEmail ?? "No email"),
              ),
              ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text("Reset Password"),
                onTap: () => showDialog(
                  context: context, 
                  builder: (context) => AlertDialog(
                    title: Text("Reset Password"),
                    content: Text("A password reset link will be sent to your email address $userEmail. Are you sure?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text("Cancel", style: TextStyle(color: Colors.green))
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _authService.resetPassword(userEmail.toString());
                        }, 
                        child: Text("Send", style: TextStyle(color: Colors.green))
                      )
                    ],
                  )
                )
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (context) => AlertDialog(
                      title: Text("Logout?"),
                      content: Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _authService.logout();
                            Navigator.pushReplacement(
                              context, MaterialPageRoute(
                                builder: (context) => LoginPage()
                              )
                            );
                          }, 
                          child: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.primary))
                        )
                      ],
                    )
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (context) => AlertDialog(
                      title: Text("Delete Account?"),
                      content: Text("Are you sure? This action cannot be undone."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: Text("Cancel", style: TextStyle(color: Colors.green))
                        ),
                        TextButton(
                          onPressed: () async {
                            await _authService.deleteAccount();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            }
                          }, 
                          child: Text("Delete Account", style: TextStyle(color: Colors.red))
                        )
                      ],
                    )
                  );
                }
              ),
            ],
          ),
        )
      ),
    );
  }
}