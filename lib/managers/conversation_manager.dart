import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';

class ConversationManager extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  List<ChatMessage> _messages = [];

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  List<ChatMessage> get messages => _messages;

  Future<void> loadConversations() async {
    final conversations = await StorageService.loadConversations();
    _conversations = conversations;

    if (_conversations.isNotEmpty) {
      _currentConversation = _conversations.first;
      _messages.clear();
      _messages.addAll(_currentConversation!.messages.reversed);
    }

    notifyListeners();
  }

  Future<void> createNewConversation() async {
    final newConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Obrolan Baru',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _conversations.insert(0, newConversation);
    _currentConversation = newConversation;
    _messages.clear();

    await StorageService.saveConversations(_conversations);
    notifyListeners();
  }

  Future<void> switchConversation(Conversation conversation) async {
    _currentConversation = conversation;
    _messages.clear();
    _messages.addAll(conversation.messages.reversed);
    notifyListeners();
  }

  Future<void> deleteConversation(Conversation conversation) async {
    _conversations.remove(conversation);

    if (_currentConversation?.id == conversation.id) {
      if (_conversations.isNotEmpty) {
        _currentConversation = _conversations.first;
        _messages.clear();
        _messages.addAll(_currentConversation!.messages.reversed);
      } else {
        _currentConversation = null;
        _messages.clear();
      }
    }

    await StorageService.saveConversations(_conversations);
    notifyListeners();
  }

  void updateConversationTitle(String firstMessage) {
    if (_currentConversation != null &&
        _currentConversation!.title == 'Obrolan Baru') {
      final title = firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;

      _currentConversation!.title = title;
      _currentConversation!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> saveCurrentConversation() async {
    if (_currentConversation != null) {
      _currentConversation!.messages = List.from(_messages.reversed);
      _currentConversation!.updatedAt = DateTime.now();

      final index = _conversations.indexWhere(
        (c) => c.id == _currentConversation!.id,
      );
      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      await StorageService.saveConversations(_conversations);
    }
  }

  void addMessage(ChatMessage message) {
    _messages.insert(0, message);

    // Keep only the last 50 messages
    if (_messages.length > 50) {
      _messages.removeRange(50, _messages.length);
    }

    notifyListeners();
  }

  Future<void> clearCurrentConversation() async {
    if (_currentConversation != null) {
      _messages.clear();
      _currentConversation!.messages.clear();
      _currentConversation!.updatedAt = DateTime.now();
      await saveCurrentConversation();
      notifyListeners();
    }
  }
}
