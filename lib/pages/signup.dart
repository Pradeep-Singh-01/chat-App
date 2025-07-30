// import 'package:chatappp/pages/signin.dart';
// import 'package:chatappp/services/database.dart';
// import 'package:chatappp/services/shared_pref.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:random_string/random_string.dart';
//
// class SignUp extends StatefulWidget {
//   const SignUp({super.key});
//
//   @override
//   State<SignUp> createState() => _SignUpState();
// }
//
// class _SignUpState extends State<SignUp> {
//   String name = "", email = "", password = "", confirmPassword = "";
//   TextEditingController nameController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   TextEditingController confirmPasswordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//
//   Future<void> registration() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (password != confirmPassword) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text("Passwords do not match"),
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);
//
//       String id = RandomString.getRandomString(10);
//       String username = email.split('@')[0].toUpperCase();
//
//       Map<String, dynamic> userInfoMap = {
//         "Name": name,
//         "Email": email,
//         "username": username,
//         "Image": "",
//         "Id": userCredential.user!.uid,
//         "SearchKey": username.substring(0, 1),
//       };
//
//       await DatabaseMethods().addUser(userInfoMap, userCredential.user!.uid);
//
//       // Save to SharedPreferences
//       await SharedpreferenceHelper().saveUserId(userCredential.user!.uid);
//       await SharedpreferenceHelper().saveUserName(username);
//       await SharedpreferenceHelper().saveUserEmail(email);
//       await SharedpreferenceHelper().saveUserDisplayName(name);
//       await SharedpreferenceHelper().saveUserImage("");
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.green,
//           content: Text("Account created successfully!"),
//         ),
//       );
//
//       // AuthWrapper will handle navigation automatically
//
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = "Registration failed";
//
//       switch (e.code) {
//         case 'weak-password':
//           errorMessage = "The password provided is too weak";
//           break;
//         case 'email-already-in-use':
//           errorMessage = "An account already exists for this email";
//           break;
//         case 'invalid-email':
//           errorMessage = "Invalid email address";
//           break;
//         default:
//           errorMessage = e.message ?? "Registration failed";
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
//       print("Registration error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text("Registration failed: ${e.toString()}"),
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
//                 SizedBox(height: 40),
//
//                 // Back Button
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       Icons.arrow_back_ios_new,
//                       size: 20,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 30),
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
//                           Icons.person_add_outlined,
//                           size: 60,
//                           color: Color(0xff703eff),
//                         ),
//                       ),
//                       SizedBox(height: 24),
//                       Text(
//                         "Create Account",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         "Sign up to get started with ChatUp",
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 40),
//
//                 // Sign Up Form
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Full Name",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       TextFormField(
//                         controller: nameController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your name';
//                           }
//                           if (value.length < 2) {
//                             return 'Name must be at least 2 characters';
//                           }
//                           return null;
//                         },
//                         onChanged: (value) {
//                           name = value;
//                         },
//                         decoration: InputDecoration(
//                           hintText: "Enter your full name",
//                           prefixIcon: Icon(Icons.person_outline, color: Color(0xff703eff)),
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
//                             return 'Please enter a password';
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
//                       SizedBox(height: 20),
//
//                       Text(
//                         "Confirm Password",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       TextFormField(
//                         controller: confirmPasswordController,
//                         obscureText: _obscureConfirmPassword,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please confirm your password';
//                           }
//                           if (value != password) {
//                             return 'Passwords do not match';
//                           }
//                           return null;
//                         },
//                         onChanged: (value) {
//                           confirmPassword = value;
//                         },
//                         decoration: InputDecoration(
//                           hintText: "Confirm your password",
//                           prefixIcon: Icon(Icons.lock_outline, color: Color(0xff703eff)),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                               color: Colors.grey[600],
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _obscureConfirmPassword = !_obscureConfirmPassword;
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
//                       SizedBox(height: 40),
//
//                       // Sign Up Button
//                       Container(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : registration,
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
//                                 "Creating Account...",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           )
//                               : Text(
//                             "Create Account",
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
//                       // Sign In Link
//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               "Already have an account? ",
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 16,
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () {
//                                 Navigator.pop(context);
//                               },
//                               child: Text(
//                                 "Sign In",
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
// }
