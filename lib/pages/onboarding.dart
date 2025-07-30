import 'package:chatappp/services/auth.dart';
import 'package:flutter/material.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Added to avoid overflow
        child: Column(
          children: [
            Image.asset("images/onboard.png", height: 400),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Enjoy the new experience of chatting with global friends",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                AuthMethods().signInWithGoogle(context);
              },
              child: buildButton("Sign in with Google", "images/search.png"),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(hintText: "Email"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: "Password"),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                AuthMethods().signUpWithEmailPassword(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: buildButton("Sign Up with Email", null),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                AuthMethods().signInWithEmailPassword(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: buildButton("Sign In with Email", null),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                AuthMethods().signInAnonymously(context);
              },
              child: buildButton("Sign In Anonymously", null),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, String? iconPath) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      child: Material(
        elevation: 3.0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Color(0xff703eff),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconPath != null) ...[
                Image.asset(iconPath, height: 40, width: 40),
                SizedBox(width: 10),
              ],
              Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

