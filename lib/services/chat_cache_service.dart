// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ChatCacheService {
//   static final ChatCacheService _instance = ChatCacheService._internal();
//   factory ChatCacheService() => _instance;
//   ChatCacheService._internal();
//
//   static ChatCacheService get instance => _instance;
//
//   SharedPreferences? _prefs;
//
//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();
//   }
//
//   // Cache keys
//   static const String _chatListKey = 'cached_chat_list';
//   static const String _lastSyncKey = 'last_sync_timestamp';
//   static const String _userDataKey = 'cached_user_data';
//
//   // Cache chat list
//   Future<void> cacheChatList(List<Map<String, dynamic>> chatList) async {
//     try {
//       final String jsonString = jsonEncode(chatList);
//       await _prefs?.setString(_chatListKey, jsonString);
//       await _prefs?.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
//       print("Chat list cached successfully: ${chatList.length} items");
//     } catch (e) {
//       print("Error caching chat list: $e");
//     }
//   }
//
//   // Get cached chat list
//   List<Map<String, dynamic>> getCachedChatList() {
//     try {
//       final String? jsonString = _prefs?.getString(_chatListKey);
//       if (jsonString != null) {
//         final List<dynamic> jsonList = jsonDecode(jsonString);
//         return jsonList.cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       print("Error getting cached chat list: $e");
//     }
//     return [];
//   }
//
//   // Cache user data for quick access
//   Future<void> cacheUserData(String userId, Map<String, dynamic> userData) async {
//     try {
//       final String key = '${_userDataKey}_$userId';
//       final String jsonString = jsonEncode(userData);
//       await _prefs?.setString(key, jsonString);
//     } catch (e) {
//       print("Error caching user data: $e");
//     }
//   }
//
//   // Get cached user data
//   Map<String, dynamic>? getCachedUserData(String userId) {
//     try {
//       final String key = '${_userDataKey}_$userId';
//       final String? jsonString = _prefs?.getString(key);
//       if (jsonString != null) {
//         return jsonDecode(jsonString).cast<String, dynamic>();
//       }
//     } catch (e) {
//       print("Error getting cached user data: $e");
//     }
//     return null;
//   }
//
//   // Check if cache needs sync (older than 5 minutes)
//   bool needsSync() {
//     final int? lastSync = _prefs?.getInt(_lastSyncKey);
//     if (lastSync == null) return true;
//
//     final int now = DateTime.now().millisecondsSinceEpoch;
//     final int fiveMinutes = 5 * 60 * 1000; // 5 minutes in milliseconds
//
//     return (now - lastSync) > fiveMinutes;
//   }
//
//   // Clear all cache
//   Future<void> clearCache() async {
//     try {
//       await _prefs?.remove(_chatListKey);
//       await _prefs?.remove(_lastSyncKey);
//
//       // Clear all user data cache
//       final keys = _prefs?.getKeys() ?? {};
//       for (String key in keys) {
//         if (key.startsWith(_userDataKey)) {
//           await _prefs?.remove(key);
//         }
//       }
//
//       print("Cache cleared successfully");
//     } catch (e) {
//       print("Error clearing cache: $e");
//     }
//   }
//
//   // Update single chat in cache
//   Future<void> updateChatInCache(String chatRoomId, Map<String, dynamic> chatData) async {
//     try {
//       List<Map<String, dynamic>> cachedList = getCachedChatList();
//
//       // Find and update existing chat or add new one
//       int existingIndex = cachedList.indexWhere((chat) => chat['chatRoomId'] == chatRoomId);
//
//       if (existingIndex != -1) {
//         cachedList[existingIndex] = chatData;
//       } else {
//         cachedList.insert(0, chatData); // Add new chat at the beginning
//       }
//
//       // Sort by last message timestamp
//       cachedList.sort((a, b) {
//         final aTime = a['lastMessageSendTs'] as int? ?? 0;
//         final bTime = b['lastMessageSendTs'] as int? ?? 0;
//         return bTime.compareTo(aTime);
//       });
//
//       await cacheChatList(cachedList);
//     } catch (e) {
//       print("Error updating chat in cache: $e");
//     }
//   }
// }
