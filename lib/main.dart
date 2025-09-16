import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'services/ai_service.dart';
import 'widgets/app_drawer.dart';
import 'widgets/chat_screen.dart';
import 'widgets/dialog_utils.dart';
import 'managers/conversation_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'AskPitra',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
              displaySmall: TextStyle(fontFamily: 'Poppins'),
              headlineLarge: TextStyle(fontFamily: 'Poppins'),
              headlineMedium: TextStyle(fontFamily: 'Poppins'),
              headlineSmall: TextStyle(fontFamily: 'Poppins'),
              titleLarge: TextStyle(fontFamily: 'Poppins'),
            ),
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MyHomePage(
            title: 'AskPitra',
            isDarkMode: _isDarkMode,
            onThemeToggle: _toggleTheme,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final String title;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ConversationManager _conversationManager;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversationManager = ConversationManager();
    _conversationManager.addListener(_onConversationChanged);
    _conversationManager.loadConversations();
  }

  @override
  void dispose() {
    _conversationManager.removeListener(_onConversationChanged);
    _conversationManager.dispose();
    super.dispose();
  }

  void _onConversationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    if (_conversationManager.currentConversation == null) {
      await _conversationManager.createNewConversation();
    }

    _conversationManager.addMessage(ChatMessage(text: text, isUser: true));

    if (_conversationManager.messages.length == 1) {
      _conversationManager.updateConversationTitle(text);
    }

    setState(() {
      _isLoading = true;
    });

    await _conversationManager.saveCurrentConversation();
    _generateAIResponse(text);
  }

  Future<void> _generateAIResponse(String userInput) async {
    try {
      final aiResponse = await AIService.generateResponse(
        userInput,
        _conversationManager.messages,
      );

      setState(() {
        _isLoading = false;
      });

      _conversationManager.addMessage(
        ChatMessage(text: aiResponse, isUser: false),
      );
      await _conversationManager.saveCurrentConversation();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _conversationManager.addMessage(
        ChatMessage(
          text:
              'Terjadi kesalahan saat memproses permintaan. Silakan coba lagi.',
          isUser: false,
        ),
      );
      await _conversationManager.saveCurrentConversation();
    }
  }

  void _showDeleteConversationDialog(Conversation conversation) {
    DialogUtils.showDeleteConversationDialog(
      context,
      conversation,
      (conversation) => _conversationManager.deleteConversation(conversation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _conversationManager.currentConversation?.title ?? widget.title,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      drawer: AppDrawer(
        colorScheme: colorScheme,
        conversations: _conversationManager.conversations,
        currentConversation: _conversationManager.currentConversation,
        isDarkMode: widget.isDarkMode,
        onNewConversation: () async {
          await _conversationManager.createNewConversation();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onSwitchConversation: (conversation) async {
          await _conversationManager.switchConversation(conversation);
          if (mounted) {
            Navigator.pop(context);
          }
        },
        onDeleteConversation: _showDeleteConversationDialog,
        onThemeToggle: widget.onThemeToggle,
        onShowAbout: () {
          Navigator.pop(context);
          DialogUtils.showAppAboutDialog(context, colorScheme);
        },
      ),
      body: ChatScreen(
        messages: _conversationManager.messages,
        onMessageSubmitted: _handleSubmitted,
        onMessageAdded: _conversationManager.addMessage,
        isLoading: _isLoading,
        colorScheme: colorScheme,
      ),
    );
  }
}
