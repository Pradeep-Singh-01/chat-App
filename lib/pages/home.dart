
import 'package:chatappp/pages/profile.dart';
import 'package:chatappp/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatappp/services/shared_pref.dart';
import 'chat_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? myUsername, myName, myEmail, mypicture;
  Stream? chatRoomStream;
  bool _isLoadingChats = true;
  bool _hasChats = false;

  getthesahredpref() async {
    try {
      myUsername = await SharedpreferenceHelper().getUserName();
      myName = await SharedpreferenceHelper().getUserDisplayName();
      myEmail = await SharedpreferenceHelper().getUserEmail();
      mypicture = await SharedpreferenceHelper().getUserImage();

      print("User data loaded:");
      print("myUsername: $myUsername");
      print("myName: $myName");

      setState(() {});
    } catch (e) {
      print("Error loading shared preferences: $e");
    }
  }

  ontheload() async {
    await getthesahredpref();
    if (myUsername != null && myUsername!.isNotEmpty) {
      try {
        chatRoomStream = await DatabaseMethods().getChatRooms();
        setState(() {});
      } catch (e) {
        print("Error loading chat rooms: $e");
        setState(() {
          _isLoadingChats = false;
        });
      }
    } else {
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  Widget chatRoomList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xff703eff)),
                SizedBox(height: 16),
                Text(
                  "Loading your chats...",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print("Error in chatRoomList: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  "Error loading chats",
                  style: TextStyle(fontSize: 18, color: Colors.red[600]),
                ),
                SizedBox(height: 8),
                Text(
                  "Please try again later",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Check if we have data and if there are any chat rooms
        if (!snapshot.hasData || snapshot.data?.docs?.length == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasChats = false;
                _isLoadingChats = false;
              });
            }
          });

          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xff703eff).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Color(0xff703eff),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "No conversations yet",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Search your friend/relative/others to start a chat",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xff703eff).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Color(0xff703eff).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          color: Color(0xff703eff),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Use the search bar above",
                          style: TextStyle(
                            color: Color(0xff703eff),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // We have chat rooms, update state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasChats = true;
              _isLoadingChats = false;
            });
          }
        });

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            return ChatRoomListTile(
              chatRoomId: ds.id ?? "",
              lastMessage: ds["lastMessage"] ?? "",
              myUsername: myUsername ?? "",
              time: _formatTimestamp(ds["lastMessageSendTs"]),
              lastMessageSendBy: ds["lastMessageSendBy"] ?? "",
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        return timestamp;
      } else {
        return "";
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      print("Error formatting timestamp: $e");
      return "";
    }
  }

  TextEditingController searchcontroller = TextEditingController();
  bool search = false;
  var queryResultSet = [];
  var tempSearchStore = [];
  bool _isSearching = false;

  String getChatRoomIdbyUsername(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) {
      print("Error: Cannot generate chatRoomId with null/empty usernames: a=$a, b=$b");
      return "";
    }

    String userA = a.toUpperCase().trim();
    String userB = b.toUpperCase().trim();

    if (userA.compareTo(userB) > 0) {
      return "${userB}_${userA}";
    } else {
      return "${userA}_${userB}";
    }
  }

  initiateSearch(String value) async {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      search = true;
      _isSearching = true;
    });

    try {
      QuerySnapshot docs = await DatabaseMethods().Search(value);

      queryResultSet.clear();
      tempSearchStore.clear();

      for (int i = 0; i < docs.docs.length; i++) {
        try {
          Map<String, dynamic>? userData = docs.docs[i].data() as Map<String, dynamic>?;

          if (userData != null) {
            userData.putIfAbsent('username', () => '');
            userData.putIfAbsent('Name', () => 'Unknown');
            userData.putIfAbsent('Image', () => '');
            userData.putIfAbsent('Id', () => '');

            String searchUsername = userData['username']?.toString().toUpperCase() ?? '';
            String currentUsername = myUsername?.toUpperCase() ?? '';

            if (searchUsername.isNotEmpty && searchUsername != currentUsername) {
              queryResultSet.add(userData);
            }
          }
        } catch (e) {
          print("Error processing search result $i: $e");
        }
      }

      String searchText = value.toUpperCase();
      tempSearchStore = queryResultSet.where((element) {
        try {
          String username = element['username']?.toString().toUpperCase() ?? '';
          String name = element['Name']?.toString().toUpperCase() ?? '';
          return username.startsWith(searchText) || name.contains(searchText);
        } catch (e) {
          print("Error filtering search result: $e");
          return false;
        }
      }).toList();

      setState(() {
        _isSearching = false;
      });

    } catch (e) {
      print("Search error: $e");
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        _isSearching = false;
      });
    }
  }

  // Fixed: Create chat room and navigate to chat
  Future<void> _createChatAndNavigate(Map<String, dynamic> userData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xff703eff)),
                SizedBox(height: 16),
                Text("Opening chat..."),
              ],
            ),
          ),
        ),
      );

      String username = userData['username']?.toString() ?? '';
      String name = userData['Name']?.toString() ?? 'Unknown';
      String image = userData['Image']?.toString() ?? '';

      print("=== Creating chat ===");
      print("Current user: $myUsername");
      print("Target user: $username");

      if (myUsername == null || myUsername!.isEmpty) {
        throw Exception("User not logged in properly");
      }

      if (username.isEmpty) {
        throw Exception("Invalid user selected");
      }

      // Generate consistent chatRoomId
      String chatRoomId = getChatRoomIdbyUsername(myUsername, username);
      print("Generated chatRoomId: $chatRoomId");

      if (chatRoomId.isEmpty) {
        throw Exception("Failed to generate chat room ID");
      }

      // Create chat room with proper user array
      Map<String, dynamic> chatInfoMap = {
        "users": [myUsername!.toUpperCase(), username.toUpperCase()],
        "lastMessage": "",
        "lastMessageSendTs": FieldValue.serverTimestamp(),
        "lastMessageSendBy": "",
        "createdAt": FieldValue.serverTimestamp(),
      };

      print("Creating chat room with data: $chatInfoMap");

      // Create chat room
      bool success = await DatabaseMethods().createChatRoom(chatRoomId, chatInfoMap);

      // Close loading dialog
      Navigator.pop(context);

      if (!success) {
        throw Exception("Failed to create chat room");
      }

      print("Chat room created/verified successfully");

      // Clear search state
      setState(() {
        search = false;
        searchcontroller.clear();
        queryResultSet.clear();
        tempSearchStore.clear();
      });

      // Navigate to chat page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            name: name.isNotEmpty ? name : 'Unknown',
            profileurl: image,
            username: username,
          ),
        ),
      );

    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error in _createChatAndNavigate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to open chat: ${e.toString()}"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello,",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            myName ?? "Guest",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Profile()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(right: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Color(0xff703eff),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to",
                      style: TextStyle(
                        color: Color.fromARGB(197, 255, 255, 255),
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "ChatUp",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 25),
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
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchcontroller,
                          onChanged: (value) {
                            initiateSearch(value);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xff703eff),
                            ),
                            hintText: "Search username...",
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            suffixIcon: search
                                ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                searchcontroller.clear();
                                initiateSearch("");
                              },
                            )
                                : null,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Content Area
                      Expanded(
                        child: search
                            ? _buildSearchResults()
                            : chatRoomList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xff703eff)),
            SizedBox(height: 16),
            Text(
              "Searching...",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (tempSearchStore.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "No users found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try searching with a different username",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tempSearchStore.length,
      itemBuilder: (context, index) {
        return buildResultCard(tempSearchStore[index]);
      },
    );
  }

  Widget buildResultCard(Map<String, dynamic>? data) {
    if (data == null) {
      return Container();
    }

    String username = data['username']?.toString() ?? '';
    String name = data['Name']?.toString() ?? 'Unknown';
    String image = data['Image']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _createChatAndNavigate(data),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: image.isNotEmpty
                      ? Image.network(
                    image,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Color(0xff703eff).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 24,
                          color: Color(0xff703eff),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff703eff),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Color(0xff703eff).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: Color(0xff703eff),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "@${username.toLowerCase()}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff703eff).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xff703eff),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String lastMessage, chatRoomId, myUsername, time, lastMessageSendBy;
  ChatRoomListTile({
    required this.chatRoomId,
    required this.lastMessage,
    required this.myUsername,
    required this.time,
    required this.lastMessageSendBy,
  });

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";
  bool isLoading = true;

  getthisUserInfo() async {
    try {
      if (widget.chatRoomId.isEmpty || widget.myUsername.isEmpty) {
        print("Error: Empty chatRoomId or myUsername");
        setState(() {
          isLoading = false;
          name = "Unknown User";
        });
        return;
      }

      List<String> users = widget.chatRoomId.split('_');
      String otherUsername = "";

      for (String user in users) {
        if (user.toUpperCase() != widget.myUsername.toUpperCase()) {
          otherUsername = user;
          break;
        }
      }

      if (otherUsername.isEmpty) {
        print("Could not find other user in chatRoomId: ${widget.chatRoomId}");
        setState(() {
          isLoading = false;
          name = "Unknown User";
        });
        return;
      }

      QuerySnapshot querySnapshot = await DatabaseMethods().getUserInfo(otherUsername);

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs[0].data() as Map<String, dynamic>?;
        if (userData != null) {
          name = userData["Name"]?.toString() ?? "Unknown";
          profilePicUrl = userData["Image"]?.toString() ?? "";
          id = userData["Id"]?.toString() ?? "";
          username = userData["username"]?.toString() ?? "";
        }
      } else {
        print("No user found for username: $otherUsername");
        name = "Unknown User";
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error getting user info: $e");
      setState(() {
        isLoading = false;
        name = "Unknown User";
      });
    }
  }

  @override
  void initState() {
    getthisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff703eff),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (name.isNotEmpty && username.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                name: name,
                profileurl: profilePicUrl,
                username: username,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: profilePicUrl.isNotEmpty
                      ? Image.network(
                    profilePicUrl,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Color(0xff703eff).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 24,
                          color: Color(0xff703eff),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Color(0xff703eff).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: Color(0xff703eff),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.lastMessageSendBy == widget.myUsername) ...[
                            Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              widget.lastMessage.isEmpty
                                  ? "Tap to start chatting"
                                  : widget.lastMessage,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: widget.lastMessage.isEmpty
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                fontStyle: widget.lastMessage.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.time.isNotEmpty)
                      Text(
                        widget.time,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}