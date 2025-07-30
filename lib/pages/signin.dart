// import 'package:chatappp/pages/signup.dart';
// import 'package:chatappp/pages/home.dart';
// import 'package:chatappp/services/database.dart';
// import 'package:chatappp/services/shared_pref.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class SignIn extends StatefulWidget {
//   const SignIn({super.key});
//
//   @override
//   State<SignIn> createState() => _SignInState();
// }
//
// class _SignInState extends State<SignIn> {
//   String email = "", password = "";
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//
//   // Email/Password Sign In
//   Future<void> userLogin() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);
//
//       if (userCredential.user != null) {
//         // Get user data from Firestore
//         var userDoc = await DatabaseMethods().getUserInfo(userCredential.user!.email!.split('@')[0].toUpperCase());
//
//         if (userDoc.docs.isNotEmpty) {
//           var userData = userDoc.docs[0].data() as Map<String, dynamic>;
//
//           // Save to SharedPreferences
//           await SharedpreferenceHelper().saveUserId(userCredential.user!.uid);
//           await SharedpreferenceHelper().saveUserName(userData["username"] ?? "");
//           await SharedpreferenceHelper().saveUserEmail(userData["Email"] ?? "");
//           await SharedpreferenceHelper().saveUserDisplayName(userData["Name"] ?? "");
//           await SharedpreferenceHelper().saveUserImage(userData["Image"] ?? "");
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: Colors.green,
//               content: Text("Login Successful!"),
//             ),
//           );
//
//           // Navigate to home - AuthWrapper will handle this automatically
//           // No need to manually navigate as AuthWrapper listens to auth state
//         } else {
//           throw Exception("User data not found. Please sign up first.");
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "Login failed";
//
//       switch (e.code) {
//         case 'user-not-found':
//           errorMessage = "No user found with this email";
//           break;
//         case 'wrong-password':
//           errorMessage = "Wrong password provided";
//           break;
//         case 'invalid-email':
//           errorMessage = "Invalid email address";
//           break;
//         case 'user-disabled':
//           errorMessage = "This account has been disabled";
//           break;
//         case 'too-many-requests':
//           errorMessage = "Too many failed attempts. Try again later";
//           break;
//         default:
//           errorMessage = e.message ?? "Login failed";
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text(errorMessage),
//           duration: Duration(seconds: 4),
//         ),
//       );
//     } catch (e) {
//       print("Login error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text("Login failed: ${e.toString()}"),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Google Sign In
//   Future<void> signInWithGoogle() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//
//       if (googleUser == null) {
//         setState(() {
//           _isLoading = false;
//         });
//         return; // User cancelled the sign-in
//       }
//
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//
//       if (userCredential.user != null) {
//         User user = userCredential.user!;
//
//         // Check if user exists in Firestore
//         String username = user.email!.split('@')[0].toUpperCase();
//         var existingUser = await DatabaseMethods().getUserInfo(username);
//
//         Map<String, dynamic> userInfoMap = {
//           "Name": user.displayName ?? "User",
//           "Email": user.email ?? "",
//           "username": username,
//           "Image": user.photoURL ?? "",
//           "Id": user.uid,
//           "SearchKey": username.substring(0, 1),
//         };
//
//         if (existingUser.docs.isEmpty) {
//           // New user - create account
//           await DatabaseMethods().addUser(userInfoMap, user.uid);
//         }
//
//         // Save to SharedPreferences
//         await SharedpreferenceHelper().saveUserId(user.uid);
//         await SharedpreferenceHelper().saveUserName(username);
//         await SharedpreferenceHelper().saveUserEmail(user.email ?? "");
//         await SharedpreferenceHelper().saveUserDisplayName(user.displayName ?? "User");
//         await SharedpreferenceHelper().saveUserImage(user.photoURL ?? "");
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.green,
//             content: Text("Google Sign In Successful!"),
//           ),
//         );
//
//         // AuthWrapper will handle navigation automatically
//       }
//     } catch (e) {
//       print("Google Sign In error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text("Google Sign In failed: ${e.toString()}"),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 60),
//
//                 // Header
//                 Center(
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Color(0xff703eff).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Icon(
//                           Icons.chat_bubble_outline,
//                           size: 60,
//                           color: Color(0xff703eff),
//                         ),
//                       ),
//                       SizedBox(height: 24),
//                       Text(
//                         "Welcome Back!",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         "Sign in to continue to ChatUp",
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 50),
//
//                 // Sign In Form
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Email",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       TextFormField(
//                         controller: emailController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                         onChanged: (value) {
//                           email = value;
//                         },
//                         decoration: InputDecoration(
//                           hintText: "Enter your email",
//                           prefixIcon: Icon(Icons.email_outlined, color: Color(0xff703eff)),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Color(0xff703eff), width: 2),
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[50],
//                         ),
//                       ),
//
//                       SizedBox(height: 20),
//
//                       Text(
//                         "Password",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       TextFormField(
//                         controller: passwordController,
//                         obscureText: _obscurePassword,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your password';
//                           }
//                           if (value.length < 6) {
//                             return 'Password must be at least 6 characters';
//                           }
//                           return null;
//                         },
//                         onChanged: (value) {
//                           password = value;
//                         },
//                         decoration: InputDecoration(
//                           hintText: "Enter your password",
//                           prefixIcon: Icon(Icons.lock_outline, color: Color(0xff703eff)),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                               color: Colors.grey[600],
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _obscurePassword = !_obscurePassword;
//                               });
//                             },
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Color(0xff703eff), width: 2),
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[50],
//                         ),
//                       ),
//
//                       SizedBox(height: 12),
//
//                       // Forgot Password
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: () {
//                             _showForgotPasswordDialog();
//                           },
//                           child: Text(
//                             "Forgot Password?",
//                             style: TextStyle(
//                               color: Color(0xff703eff),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // Sign In Button
//                       Container(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : userLogin,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xff703eff),
//                             foregroundColor: Colors.white,
//                             padding: EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 2,
//                           ),
//                           child: _isLoading
//                               ? Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                               SizedBox(width: 12),
//                               Text(
//                                 "Signing In...",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           )
//                               : Text(
//                             "Sign In",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // Divider
//                       Row(
//                         children: [
//                           Expanded(child: Divider(color: Colors.grey[300])),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 16),
//                             child: Text(
//                               "OR",
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           Expanded(child: Divider(color: Colors.grey[300])),
//                         ],
//                       ),
//
//                       SizedBox(height: 30),
//
//                       // Google Sign In Button
//                       Container(
//                         width: double.infinity,
//                         child: OutlinedButton(
//                           onPressed: _isLoading ? null : signInWithGoogle,
//                           style: OutlinedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             side: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.asset(
//                                 'assets/google_logo.png', // You'll need to add this asset
//                                 height: 20,
//                                 width: 20,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Icon(Icons.g_mobiledata, size: 24, color: Colors.red);
//                                 },
//                               ),
//                               SizedBox(width: 12),
//                               Text(
//                                 "Continue with Google",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 40),
//
//                       // Sign Up Link
//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               "Don't have an account? ",
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 16,
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (context) => SignUp()),
//                                 );
//                               },
//                               child: Text(
//                                 "Sign Up",
//                                 style: TextStyle(
//                                   color: Color(0xff703eff),
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       SizedBox(height: 30),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showForgotPasswordDialog() {
//     TextEditingController resetEmailController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Reset Password"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Enter your email address to receive a password reset link."),
//             SizedBox(height: 16),
//             TextField(
//               controller: resetEmailController,
//               decoration: InputDecoration(
//                 hintText: "Enter your email",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (resetEmailController.text.isNotEmpty) {
//                 try {
//                   await FirebaseAuth.instance.sendPasswordResetEmail(
//                     email: resetEmailController.text.trim(),
//                   );
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       backgroundColor: Colors.green,
//                       content: Text("Password reset email sent!"),
//                     ),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       backgroundColor: Colors.red,
//                       content: Text("Error: ${e.toString()}"),
//                     ),
//                   );
//                 }
//               }
//             },
//             child: Text("Send Reset Email"),
//           ),
//         ],
//       ),
//     );
//   }
// }
