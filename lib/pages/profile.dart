
import 'package:chatappp/pages/onboarding.dart';
import 'package:chatappp/services/auth.dart';
import 'package:flutter/material.dart';
import '../services/shared_pref.dart';
import '../services/database.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? myUsername, myName, myEmail, mypicture;

  getthesahredpref() async {
    myUsername = await SharedpreferenceHelper().getUserName();
    myName = await SharedpreferenceHelper().getUserDisplayName();
    myEmail = await SharedpreferenceHelper().getUserEmail();
    mypicture = await SharedpreferenceHelper().getUserImage();
    setState(() {});
  }

  @override
  void initState() {
    getthesahredpref();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: myEmail == null
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xff406fd9),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Profile",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 50), // Balance the back button
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: mypicture == null || mypicture!.isEmpty
                            ? Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                        )
                            : Image.network(
                          mypicture!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Name Section
                    Container(
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Color(0xff406fd9),
                                size: 35,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Name",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            myName ?? "No Name",
                                            style: TextStyle(
                                              color: Colors.black45,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                TextEditingController nameController =
                                                TextEditingController(text: myName);
                                                return AlertDialog(
                                                  title: Text("Edit Name"),
                                                  content: TextField(
                                                    controller: nameController,
                                                    decoration: InputDecoration(
                                                      hintText: "Enter new name",
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Cancel"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        String newName = nameController.text.trim();
                                                        if (newName.isNotEmpty) {
                                                          String? uid = await SharedpreferenceHelper().getUserId();
                                                          if (uid != null) {
                                                            await DatabaseMethods().updateUserName(uid, newName);
                                                            await SharedpreferenceHelper().saveUserDisplayName(newName);
                                                            setState(() {
                                                              myName = newName;
                                                            });
                                                          }
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child: Text("Save"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.edit,
                                            color: Color(0xff406fd9),
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Email Section
                    Container(
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: Color(0xff406fd9),
                                size: 35,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Email",
                                      style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      myEmail ?? "No Email",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Logout Button
                    GestureDetector(
                      onTap: () async {
                        // Show confirmation dialog
                        bool? shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Logout"),
                            content: Text("Are you sure you want to logout?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Logout"),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await AuthMethods().SignOut();
                          // Navigation will be handled automatically by AuthWrapper
                        }
                      },
                      child: Container(
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Color(0xff406fd9),
                                  size: 35,
                                ),
                                SizedBox(width: 30),
                                Text(
                                  "LogOut",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xff406fd9),
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Delete Account Button
                    GestureDetector(
                      onTap: () async {
                        // Show confirmation dialog
                        bool? shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Account"),
                            content: Text("Are you sure you want to delete your account? This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          try {
                            await AuthMethods().deleteuser();
                            // Navigation will be handled automatically by AuthWrapper
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text("Failed to delete account: $e"),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 35,
                                ),
                                SizedBox(width: 30),
                                Text(
                                  "Delete Account",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
