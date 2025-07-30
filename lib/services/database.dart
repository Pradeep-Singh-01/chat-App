
import 'package:chatappp/services/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUser(Map<String, dynamic> userInfoMap, String id) async {
    try {
      return await FirebaseFirestore.instance
          .collection("user")
          .doc(id)
          .set(userInfoMap);
    } catch (e) {
      print("Error adding user: $e");
      rethrow;
    }
  }

  Future addMessage(
      String chatRoomId,
      String messageId,
      Map<String, dynamic> messageInfoMap,
      ) async {
    try {
      if (chatRoomId.isEmpty || messageId.isEmpty) {
        throw Exception("ChatRoomId or MessageId is empty");
      }

      return await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .collection("chats")
          .doc(messageId)
          .set(messageInfoMap);
    } catch (e) {
      print("Error adding message: $e");
      rethrow;
    }
  }

  updateLastMessageSend(
      String chatRoomId,
      Map<String, dynamic> lastMessageInfoMap,
      ) async {
    try {
      if (chatRoomId.isEmpty) {
        throw Exception("ChatRoomId is empty");
      }

      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .update(lastMessageInfoMap);
    } catch (e) {
      print("Error updating last message: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot> Search(String searchText) async {
    try {
      if (searchText.isEmpty) {
        return await FirebaseFirestore.instance
            .collection("user")
            .limit(0)
            .get();
      }

      String searchKey = searchText.toUpperCase();

      // Search by username prefix (case-insensitive)
      return await FirebaseFirestore.instance
          .collection("user")
          .where("username", isGreaterThanOrEqualTo: searchKey)
          .where("username", isLessThan: searchKey + 'z')
          .limit(10)
          .get();
    } catch (e) {
      print("Search error: $e");
      // Fallback to SearchKey method
      try {
        return await FirebaseFirestore.instance
            .collection("user")
            .where("SearchKey", isEqualTo: searchText.substring(0, 1).toUpperCase())
            .get();
      } catch (e2) {
        print("Fallback search error: $e2");
        rethrow;
      }
    }
  }

  Future<bool> createChatRoom(
      String chatRoomId,
      Map<String, dynamic> chatRoomInfoMap,
      ) async {
    try {
      if (chatRoomId.isEmpty) {
        print("Error: ChatRoomId is empty");
        return false;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .get();

      if (snapshot.exists) {
        print("Chat room already exists: $chatRoomId");
        return true;
      } else {
        // Ensure all required fields are present
        chatRoomInfoMap.putIfAbsent("lastMessage", () => "");
        chatRoomInfoMap.putIfAbsent("lastMessageSendTs", () => FieldValue.serverTimestamp());
        chatRoomInfoMap.putIfAbsent("lastMessageSendBy", () => "");
        chatRoomInfoMap.putIfAbsent("createdAt", () => FieldValue.serverTimestamp());

        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .set(chatRoomInfoMap);

        print("Chat room created: $chatRoomId");
        return true;
      }
    } catch (e) {
      print("Error creating chat room: $e");
      return false;
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(String? chatRoomId) async {
    try {
      if (chatRoomId == null || chatRoomId.isEmpty) {
        print("Error: ChatRoomId is null or empty");
        return Stream.empty();
      }

      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .collection("chats")
          .orderBy("time", descending: true)
          .snapshots();
    } catch (e) {
      print("Error getting chat room messages: $e");
      return Stream.empty();
    }
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception("Username is empty");
      }

      return await FirebaseFirestore.instance
          .collection("user")
          .where("username", isEqualTo: username.toUpperCase())
          .get();
    } catch (e) {
      print("Error getting user info: $e");
      rethrow;
    }
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    try {
      String? myUsername = await SharedpreferenceHelper().getUserName();
      if (myUsername == null || myUsername.isEmpty) {
        print("No username found in SharedPreferences");
        return Stream.empty();
      }

      print("Getting chat rooms for user: ${myUsername.toUpperCase()}");

      return FirebaseFirestore.instance
          .collection("chatrooms")
          .where("users", arrayContains: myUsername.toUpperCase())
          .orderBy("lastMessageSendTs", descending: true)
          .snapshots();
    } catch (e) {
      print("Error getting chat rooms: $e");
      return Stream.empty();
    }
  }

  Future updateUserName(String uid, String newName) async {
    try {
      if (uid.isEmpty || newName.isEmpty) {
        throw Exception("UID or newName is empty");
      }

      return await FirebaseFirestore.instance
          .collection("user")
          .doc(uid)
          .update({
        "Name": newName,
      });
    } catch (e) {
      print("Error updating user name: $e");
      rethrow;
    }
  }

  Future<bool> chatRoomExists(String chatRoomId) async {
    try {
      if (chatRoomId.isEmpty) {
        return false;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .get();
      return snapshot.exists;
    } catch (e) {
      print("Error checking chat room existence: $e");
      return false;
    }
  }

  Future<QuerySnapshot> getAllUsers() async {
    try {
      return await FirebaseFirestore.instance
          .collection("user")
          .get();
    } catch (e) {
      print("Error getting all users: $e");
      rethrow;
    }
  }
}