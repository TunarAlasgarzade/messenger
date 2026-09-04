import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/my_button.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/pages/home_page.dart';
import 'package:messenger/pages/login_page.dart';
import 'package:messenger/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isRegistering = false;

  Future<void> register() async {
    if (_emailController.text.trim().isNotEmpty && _passwordController.text.trim().isNotEmpty && _confirmPasswordController.text.trim().isNotEmpty) {
      if (_passwordController.text == _confirmPasswordController.text) {
        try {
          setState(() {
            isRegistering = true;
          });
          await _authService.signUpWithEmailAndPassword(
            _emailController.text, 
            _passwordController.text,
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context, MaterialPageRoute(
              builder: (context) => HomePage()
            )
          );
        } on FirebaseAuthException catch (e) {
          setState(() {
            isRegistering = false;
          });
          if (e.code == "email-already-in-use") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("This email is already registered."),
                backgroundColor: Color(0xFFBD4444),
              )
            );
          } else if (e.code == "invalid-email") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please enter a valid email."),
                backgroundColor: Color(0xFFBD4444),
              )
            );
          } else if (e.code == "weak-password") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Password is too weak."),
                backgroundColor: Color(0xFFBD4444),
              )
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Something went wrong."),
                backgroundColor: Color(0xFFBD4444),
              )
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Passwords don't match!", 
              style: TextStyle(color: Colors.white)
            ), 
            backgroundColor: Colors.red,
          )
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields."),
          backgroundColor: Color(0xFFBD4444),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, color: Theme.of(context).colorScheme.primary, size: 70),
              const SizedBox(height: 25),
              Text(
                "Welcome, let's create an account for you!", 
                style: TextStyle(color: Theme.of(context).colorScheme.primary)
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: MyTextfield(
                  controller: _emailController, 
                  hintText: "Email",
                  obscureText: false,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: MyTextfield(
                  controller: _passwordController, 
                  hintText: "Password", 
                  obscureText: true
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: MyTextfield(
                  controller: _confirmPasswordController, 
                  hintText: "Confirm password", 
                  obscureText: true
                ),
              ),
              const SizedBox(height: 15),
              isRegistering ? CircularProgressIndicator() : MyButton(onPressed: register, text: "Register"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(
                        builder: (context) => LoginPage()
                      )
                    ), 
                    child: Text(
                      "Login now!", 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)
                    )
                  )
                ],
              ),
              const SizedBox(height: 25),
            ],
          ),
        )
      ),
    );
  }
}