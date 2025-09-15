import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _storageKey = 'main_chat_messages';

  /// Loads chat messages from local storage
  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_storageKey);
      
      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        return decoded.map(
          (msg) => ChatMessage(
            text: msg['text'],
            isUser: msg['isUser'],
            timestamp: DateTime.parse(msg['timestamp']),
          ),
        ).toList();
      }
      
      return [];
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  /// Saves chat messages to local storage
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messagesJson = jsonEncode(
        messages.map(
          (msg) => {
            'text': msg.text,
            'isUser': msg.isUser,
            'timestamp': msg.timestamp.toIso8601String(),
          },
        ).toList(),
      );
      await prefs.setString(_storageKey, messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  /// Clears all chat messages from local storage
  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing messages: $e');
    }
  }

  /// Gets the current storage size (for debugging purposes)
  static Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_storageKey);
      return messagesJson?.length ?? 0;
    } catch (e) {
      print('Error getting storage size: $e');
      return 0;
    }
  }
}