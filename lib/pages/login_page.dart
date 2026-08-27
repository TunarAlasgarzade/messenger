import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger/components/my_button.dart';
import 'package:messenger/components/my_textfield.dart';
import 'package:messenger/pages/home_page.dart';
import 'package:messenger/pages/register_page.dart';
import 'package:messenger/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text, 
        _passwordController.text, 
      );
      if(!mounted) return;
      Navigator.pushReplacement(
        context, MaterialPageRoute(
          builder: (context) => HomePage()
        )
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-credential") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Wrong password or email"),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Something went wrong."),
            backgroundColor: Color(0xFFBD4444),
          )
        );
      }
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
              Icon(Icons.chat, color: Colors.green, size: 70),
              const SizedBox(height: 25),
              Text("Welcome back, you've been missed!", style: TextStyle(color: Colors.green)),
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
              MyButton(onPressed: login, text: "Login"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(
                        builder: (context) => RegisterPage()
                      )
                    ), 
                    child: Text(
                      "Register now!", 
                      style: TextStyle(color: Colors.green)
                    )
                  )
                ],
              ),
              const SizedBox(height: 25)
            ],
          ),
        )
      ),
    );
  }
}