import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class StorageService {
  static const String _conversationsKey = 'conversations_v2';
  static const String _storageKey =
      'main_chat_messages';

  static Future<void> saveConversations(
    List<Conversation> conversations,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> conversationsJson = conversations.map((
        conversation,
      ) {
        return {
          'id': conversation.id,
          'title': conversation.title,
          'messages': conversation.messages
              .map(
                (message) => {
                  'text': message.text,
                  'isUser': message.isUser,
                  'timestamp': message.timestamp.toIso8601String(),
                },
              )
              .toList(),
          'createdAt': conversation.createdAt.toIso8601String(),
          'updatedAt': conversation.updatedAt.toIso8601String(),
        };
      }).toList();

      final String conversationsString = jsonEncode(conversationsJson);
      await prefs.setString(_conversationsKey, conversationsString);
    } catch (e) {
      print('Error saving conversations: $e');
      throw Exception('Failed to save conversations: $e');
    }
  }

  static Future<List<Conversation>> loadConversations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? conversationsString = prefs.getString(_conversationsKey);

      if (conversationsString != null && conversationsString.isNotEmpty) {
        final List<dynamic> conversationsJson = jsonDecode(conversationsString);
        return conversationsJson.map((json) {
          final List<ChatMessage> messages = (json['messages'] as List<dynamic>)
              .map((msgJson) {
                return ChatMessage(
                  text: msgJson['text'] as String,
                  isUser: msgJson['isUser'] as bool,
                  timestamp: DateTime.parse(msgJson['timestamp'] as String),
                );
              })
              .toList();

          return Conversation(
            id: json['id'] as String,
            title: json['title'] as String,
            messages: messages,
            createdAt: DateTime.parse(json['createdAt'] as String),
            updatedAt: DateTime.parse(json['updatedAt'] as String),
          );
        }).toList();
      } else {
        final List<ChatMessage> oldMessages = await loadMessages();
        if (oldMessages.isNotEmpty) {
          final migratedConversation = Conversation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: oldMessages.first.text.length > 30
                ? '${oldMessages.first.text.substring(0, 30)}...'
                : oldMessages.first.text,
            messages: oldMessages,
            createdAt: oldMessages.first.timestamp,
            updatedAt: oldMessages.first.timestamp,
          );
          await saveConversations([migratedConversation]);
          await clearMessages();
          return [migratedConversation];
        }
        return [];
      }
    } catch (e) {
      print('Error loading conversations: $e');
      try {
        final List<ChatMessage> oldMessages = await loadMessages();
        if (oldMessages.isNotEmpty) {
          return [
            Conversation(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Migrated Chat',
              messages: oldMessages,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];
        }
      } catch (migrationError) {
        print('Error during migration: $migrationError');
      }
      return [];
    }
  }

  static Future<void> clearConversations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationsKey);
    } catch (e) {
      print('Error clearing conversations: $e');
    }
  }

  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_storageKey);
      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        return decoded
            .map(
              (msg) => ChatMessage(
                text: msg['text'],
                isUser: msg['isUser'],
                timestamp: DateTime.parse(msg['timestamp']),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String messagesJson = jsonEncode(
        messages
            .map(
              (msg) => {
                'text': msg.text,
                'isUser': msg.isUser,
                'timestamp': msg.timestamp.toIso8601String(),
              },
            )
            .toList(),
      );
      await prefs.setString(_storageKey, messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing messages: $e');
    }
  }

  static Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_storageKey);
      final String? conversationsJson = prefs.getString(_conversationsKey);
      return (messagesJson?.length ?? 0) + (conversationsJson?.length ?? 0);
    } catch (e) {
      print('Error getting storage size: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_storageKey);
      final String? conversationsJson = prefs.getString(_conversationsKey);

      return {
        'messagesSize': messagesJson?.length ?? 0,
        'conversationsSize': conversationsJson?.length ?? 0,
        'totalSize':
            (messagesJson?.length ?? 0) + (conversationsJson?.length ?? 0),
        'hasOldMessages': messagesJson != null,
        'hasConversations': conversationsJson != null,
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {'error': e.toString()};
    }
  }

  static Future<String> exportConversations() async {
    try {
      final conversations = await loadConversations();
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'conversations': conversations
            .map(
              (conversation) => {
                'id': conversation.id,
                'title': conversation.title,
                'messages': conversation.messages
                    .map(
                      (message) => {
                        'text': message.text,
                        'isUser': message.isUser,
                        'timestamp': message.timestamp.toIso8601String(),
                      },
                    )
                    .toList(),
                'createdAt': conversation.createdAt.toIso8601String(),
                'updatedAt': conversation.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      };
      return jsonEncode(exportData);
    } catch (e) {
      print('Error exporting conversations: $e');
      throw Exception('Failed to export conversations: $e');
    }
  }

  static Future<void> importConversations(
    String jsonData, {
    bool merge = false,
  }) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      final List<dynamic> conversationsData =
          importData['conversations'] as List<dynamic>;

      final List<Conversation> importedConversations = conversationsData.map((
        json,
      ) {
        final List<ChatMessage> messages = (json['messages'] as List<dynamic>)
            .map((msgJson) {
              return ChatMessage(
                text: msgJson['text'] as String,
                isUser: msgJson['isUser'] as bool,
                timestamp: DateTime.parse(msgJson['timestamp'] as String),
              );
            })
            .toList();

        return Conversation(
          id: json['id'] as String,
          title: json['title'] as String,
          messages: messages,
          createdAt: DateTime.parse(json['createdAt'] as String),
          updatedAt: DateTime.parse(json['updatedAt'] as String),
        );
      }).toList();

      if (merge) {
        final existingConversations = await loadConversations();
        final allConversations = [
          ...importedConversations,
          ...existingConversations,
        ];
        final Map<String, Conversation> uniqueConversations = {};
        for (final conversation in allConversations) {
          uniqueConversations[conversation.id] = conversation;
        }
        await saveConversations(uniqueConversations.values.toList());
      } else {
        await saveConversations(importedConversations);
      }
    } catch (e) {
      print('Error importing conversations: $e');
      throw Exception('Failed to import conversations: $e');
    }
  }
}
