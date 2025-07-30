import 'package:chatappp/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chatappp/services/shared_pref.dart';
import 'package:chatappp/pages/home.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  // Check if user is currently signed in
  bool isUserSignedIn() {
    return auth.currentUser != null;
  }

  signInWithGoogle(BuildContext context) async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
      await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // User canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      UserCredential result = await firebaseAuth.signInWithCredential(credential);
      User? userDetails = result.user;

      if (userDetails == null) {
        throw Exception("Failed to get user details");
      }

      String username = userDetails.email!.replaceAll("@gmail.com", "");
      String firstletter = username.substring(0, 1).toUpperCase();

      // Save user data to SharedPreferences
      await SharedpreferenceHelper().saveUserDisplayName(userDetails.displayName ?? "No Name");
      await SharedpreferenceHelper().saveUserEmail(userDetails.email!);
      await SharedpreferenceHelper().saveUserImage(userDetails.photoURL ?? "");
      await SharedpreferenceHelper().saveUserId(userDetails.uid);
      await SharedpreferenceHelper().saveUsername(username);

      Map<String, dynamic> userInfoMap = {
        "Name": userDetails.displayName ?? "No Name",
        "Email": userDetails.email,
        "Image": userDetails.photoURL ?? "",
        "Id": userDetails.uid,
        "username": username.toUpperCase(),
        "SearchKey": firstletter,
      };

      await DatabaseMethods().addUser(userInfoMap, userDetails.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Signed in successfully!"),
        ),
      );

      // Navigation will be handled automatically by AuthWrapper
      // No need to manually navigate here

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Google Sign-In failed: $e"),
        ),
      );
    }
  }

  // Email/Password Sign Up
  signUpWithEmailPassword(BuildContext context, String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Please fill in all fields"),
          ),
        );
        return;
      }

      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? userDetails = result.user;

      if (userDetails == null) {
        throw Exception("Failed to create user");
      }

      String username = email.replaceAll("@gmail.com", "").replaceAll("@", "");
      String firstletter = username.substring(0, 1).toUpperCase();

      await SharedpreferenceHelper().saveUserDisplayName("No Name");
      await SharedpreferenceHelper().saveUserEmail(email);
      await SharedpreferenceHelper().saveUserImage("");
      await SharedpreferenceHelper().saveUserId(userDetails.uid);
      await SharedpreferenceHelper().saveUsername(username);

      Map<String, dynamic> userInfoMap = {
        "Name": "No Name",
        "Email": email,
        "Image": "",
        "Id": userDetails.uid,
        "username": username.toUpperCase(),
        "SearchKey": firstletter,
      };

      await DatabaseMethods().addUser(userInfoMap, userDetails.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Account created successfully!"),
        ),
      );

      // Navigation will be handled automatically by AuthWrapper

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Sign-Up failed: $e"),
        ),
      );
    }
  }

  // Email/Password Sign In
  signInWithEmailPassword(BuildContext context, String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Please fill in all fields"),
          ),
        );
        return;
      }

      UserCredential result = await auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      User? userDetails = result.user;

      if (userDetails != null) {
        // Load user data to SharedPreferences if it exists
        String username = email.replaceAll("@gmail.com", "").replaceAll("@", "");

        await SharedpreferenceHelper().saveUserEmail(email);
        await SharedpreferenceHelper().saveUserId(userDetails.uid);
        await SharedpreferenceHelper().saveUsername(username);

        // Try to get additional user info from Firestore
        try {
          var userDoc = await DatabaseMethods().getUserInfo(username.toUpperCase());
          if (userDoc.docs.isNotEmpty) {
            var userData = userDoc.docs[0].data() as Map<String, dynamic>;
            await SharedpreferenceHelper().saveUserDisplayName(userData['Name'] ?? "No Name");
            await SharedpreferenceHelper().saveUserImage(userData['Image'] ?? "");
          }
        } catch (e) {
          print("Error loading user data: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Signed in successfully!"),
        ),
      );

      // Navigation will be handled automatically by AuthWrapper

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Sign-In failed: $e"),
        ),
      );
    }
  }

  // Anonymous Login
  signInAnonymously(BuildContext context) async {
    try {
      UserCredential result = await auth.signInAnonymously();
      User? userDetails = result.user;

      if (userDetails != null) {
        String username = "anonymous_${userDetails.uid.substring(0, 8)}";

        await SharedpreferenceHelper().saveUserDisplayName("Anonymous User");
        await SharedpreferenceHelper().saveUserEmail("");
        await SharedpreferenceHelper().saveUserImage("");
        await SharedpreferenceHelper().saveUserId(userDetails.uid);
        await SharedpreferenceHelper().saveUsername(username);

        Map<String, dynamic> userInfoMap = {
          "Name": "Anonymous User",
          "Email": "",
          "Image": "",
          "Id": userDetails.uid,
          "username": username.toUpperCase(),
          "SearchKey": "A",
        };

        await DatabaseMethods().addUser(userInfoMap, userDetails.uid);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Signed in anonymously!"),
        ),
      );

      // Navigation will be handled automatically by AuthWrapper

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Anonymous Sign-In failed: $e"),
        ),
      );
    }
  }

  Future SignOut() async {
    try {
      // Clear SharedPreferences
      await SharedpreferenceHelper().clearAllData();

      // Sign out from Firebase
      await auth.signOut();

      // Sign out from Google if signed in with Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future deleteuser() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        // Clear SharedPreferences
        await SharedpreferenceHelper().clearAllData();

        // Delete user account
        await user.delete();
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }
}