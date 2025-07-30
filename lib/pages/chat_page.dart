

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chatappp/services/database.dart';
import 'package:chatappp/services/shared_pref.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';

class ChatPage extends StatefulWidget {
  String name, profileurl, username;
  ChatPage({
    required this.name,
    required this.profileurl,
    required this.username,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream? messageStream;
  String? myUsername, myName, myEmail, mypicture, chatRoomId, messageId;
  TextEditingController messagecontroller = TextEditingController();
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;

  getthesahredpref() async {
    try {
      myUsername = await SharedpreferenceHelper().getUserName();
      myName = await SharedpreferenceHelper().getUserDisplayName();
      myEmail = await SharedpreferenceHelper().getUserEmail();
      mypicture = await SharedpreferenceHelper().getUserImage();

      print("=== Chat Page User Data ===");
      print("myUsername: $myUsername");
      print("target username: ${widget.username}");
      print("target name: ${widget.name}");

      if (myUsername == null || myUsername!.isEmpty) {
        throw Exception("User not logged in properly");
      }

      if (widget.username.isEmpty) {
        throw Exception("Target username is empty");
      }

      chatRoomId = getChatRoomIdbyUsername(widget.username, myUsername!);
      print("Generated chatRoomId: $chatRoomId");

      if (chatRoomId == null || chatRoomId!.isEmpty) {
        throw Exception("Failed to generate chat room ID");
      }

      setState(() {});
    } catch (e) {
      print("Error in getthesahredpref: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error loading user data: $e"),
        ),
      );
    }
  }

  bool _isRecording = false;
  String? _filePath;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Future<void> _initialize() async {
    try {
      await _recorder.openRecorder();
      await _requestPermission();
      var tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/audio.aac';
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> _requestPermission() async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        await Permission.microphone.request();
      }
    } catch (e) {
      print("Error requesting microphone permission: $e");
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecorder(toFile: _filePath);
      setState(() {
        _isRecording = true;
        Navigator.pop(context);
        openRecording();
      });
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        Navigator.pop(context);
        openRecording();
      });
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  ontheload() async {
    try {
      await getthesahredpref();
      await getandSetMessages();
      setState(() {
        _isLoading = false;
      });

      // Auto-scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print("Error in ontheload: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error loading chat: $e"),
        ),
      );
    }
  }

  @override
  void initState() {
    ontheload();
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    messagecontroller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("No audio file to upload"),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Your Audio is Uploading Please Wait...",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );

    File file = File(_filePath!);
    try {
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('uploads.audio.aac')
          .putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat("h:mma").format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Audio",
        "message": downloadUrl,
        "sendBy": myUsername ?? "",
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture ?? "",
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Audio",
          "lastMessageSendTs": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername ?? "",
          "users": [myUsername?.toUpperCase() ?? "", widget.username.toUpperCase()],
        };
        DatabaseMethods().updateLastMessageSend(
          chatRoomId!,
          lastMessageInfoMap,
        );
        _scrollToBottom();
      });
    } catch (e) {
      print("Error uploading to Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to upload audio"),
        ),
      );
    }
  }

  Widget chatMessageTile(String message, bool sendByMe, String Data) {
    return Row(
      mainAxisAlignment:
      sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomRight:
                sendByMe ? Radius.circular(0) : Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: sendByMe ? Radius.circular(30) : Radius.circular(0),
              ),
              color: sendByMe ? Colors.black45 : Colors.blue,
            ),
            child: Data == "Image"
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                message,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: 200,
                    child: Center(
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  );
                },
              ),
            )
                : Data == "Audio"
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Text(
                  "Audio",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )
                : Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("No image selected"),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Your Image is uploading please Wait...",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
    try {
      String addId = randomAlphaNumeric(10);

      Reference firebaseStrorageRef = FirebaseStorage.instance
          .ref()
          .child("blogImage")
          .child(addId);
      final UploadTask task = firebaseStrorageRef.putFile(selectedImage!);
      var downloadurl1 = await (await task).ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat("h:mma").format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Image",
        "message": downloadurl1,
        "sendBy": myUsername ?? "",
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture ?? "",
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Image",
          "lastMessageSendTs": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername ?? "",
          "users": [myUsername?.toUpperCase() ?? "", widget.username.toUpperCase()],
        };
        DatabaseMethods().updateLastMessageSend(
          chatRoomId!,
          lastMessageInfoMap,
        );
        _scrollToBottom();
      });
    } catch (e) {
      print('Error uploading to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to upload image"),
        ),
      );
    }
  }

  getandSetMessages() async {
    try {
      if (chatRoomId != null && chatRoomId!.isNotEmpty) {
        messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
        setState(() {});
      }
    } catch (e) {
      print("Error getting messages: $e");
    }
  }

  Future getImage() async {
    try {
      var image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage = File(image.path);
        _uploadImage();
        setState(() {});
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to pick image"),
        ),
      );
    }
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            print("Error in chat messages: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Error loading messages"),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data?.docs?.length == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No messages yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    "Start the conversation!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Auto-scroll when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return ListView.builder(
              controller: _scrollController,
              itemCount: snapshot.data.docs.length,
              reverse: true,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                return chatMessageTile(
                  ds["message"]?.toString() ?? "",
                  myUsername == ds["sendBy"],
                  ds["Data"]?.toString() ?? "Message",
                );
              });
        });
  }

  // Fixed: Null-safe chatRoomId generation
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

  Future<void> addMessage(bool sendClicked) async {
    if (messagecontroller.text.trim().isEmpty || _isSending) return;

    if (chatRoomId == null || chatRoomId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: Chat room not initialized"),
        ),
      );
      return;
    }

    String message = messagecontroller.text.trim();
    messagecontroller.clear();

    setState(() {
      _isSending = true;
    });

    try {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat("hh:mm a").format(now);

      Map<String, dynamic> messageInfoMap = {
        "Data": "Message",
        "message": message,
        "sendBy": myUsername ?? "",
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture ?? "",
      };

      messageId = randomAlphaNumeric(10);

      // Add message to chat
      await DatabaseMethods().addMessage(chatRoomId!, messageId!, messageInfoMap);

      // Update chat room with last message info
      Map<String, dynamic> lastMessageInfoMap = {
        "lastMessage": message,
        "lastMessageSendTs": FieldValue.serverTimestamp(),
        "lastMessageSendBy": myUsername ?? "",
        "users": [myUsername?.toUpperCase() ?? "", widget.username.toUpperCase()],
      };

      await DatabaseMethods().updateLastMessageSend(chatRoomId!, lastMessageInfoMap);

      print("Message sent successfully");

    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to send message: $e"),
        ),
      );

      // Restore message if sending failed
      messagecontroller.text = message;
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xff703eff),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Loading chat...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: widget.profileurl.isNotEmpty
                        ? Image.network(
                      widget.profileurl,
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(Icons.person, color: Color(0xff703eff)),
                        );
                      },
                    )
                        : Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(Icons.person, color: Color(0xff703eff)),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name.isNotEmpty ? widget.name : "Unknown",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "@${widget.username.toLowerCase()}",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 10, right: 10, top: 20),
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
                    Expanded(
                      child: chatMessage(),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              openRecording();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xff703eff),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                Icons.mic,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFFececf8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: messagecontroller,
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (value) {
                                  addMessage(true);
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Type a message...",
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      getImage();
                                    },
                                    child: Icon(Icons.attach_file),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: _isSending ? null : () {
                              addMessage(true);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isSending ? Colors.grey : Color(0xff703eff),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: _isSending
                                  ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Icon(
                                Icons.send,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

  Future openRecording() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Text(
                "Add Voice Note",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                },
                child: Text(
                  _isRecording ? 'Stop Recording' : 'Start Recording',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (_isRecording) {
                    null;
                  } else {
                    _uploadFile();
                  }
                },
                child: Text(
                  'Upload Audio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    ),
  );
}