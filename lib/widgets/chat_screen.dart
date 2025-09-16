import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onMessageSubmitted;
  final Function(ChatMessage) onMessageAdded;
  final bool isLoading;
  final ColorScheme colorScheme;

  const ChatScreen({
    super.key,
    required this.messages,
    required this.onMessageSubmitted,
    required this.onMessageAdded,
    required this.isLoading,
    required this.colorScheme,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Jelaskan Filosofi UPITRA',
    'Sebutkan Nilai-Nilai UPITRA',
    'Program Studi yang ada di UPITRA',
    'Apa saja Visi dan misi UPITRA',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    widget.onMessageSubmitted(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? ChatWidgets.buildWelcomeScreen(
                  widget.colorScheme,
                  _suggestions,
                  _handleSubmitted,
                )
              : _buildChatList(),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.isLoading && index == 0) {
          return ChatWidgets.buildLoadingIndicator(widget.colorScheme);
        }
        return widget.messages[widget.isLoading ? index - 1 : index];
      },
    );
  }

  Widget _buildInputArea() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: widget.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: ChatWidgets.buildInputField(
            context,
            widget.colorScheme,
            _textController,
            _handleSubmitted,
          ),
        ),
      ),
    );
  }
}
