import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'widgets/chat_widgets.dart';

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
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  int _selectedDrawerIndex = 0;

  final List<String> _suggestions = [
    'Filosofi UPITRA',
    'Nilai-Nilai UPITRA',
    'Program Studi di UPITRA',
    'Apa visi dan misi UPITRA',
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final conversations = await StorageService.loadConversations();
    setState(() {
      _conversations = conversations;
      if (_conversations.isNotEmpty) {
        _currentConversation = _conversations.first;
        _messages.clear();
        _messages.addAll(_currentConversation!.messages.reversed);
      }
    });
  }

  Future<void> _createNewConversation() async {
    final newConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Obrolan Baru',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _conversations.insert(0, newConversation);
      _currentConversation = newConversation;
      _messages.clear();
      _selectedDrawerIndex = 0;
    });

    await StorageService.saveConversations(_conversations);

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _switchConversation(Conversation conversation) async {
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _messages.addAll(conversation.messages.reversed);
      _selectedDrawerIndex = 0;
    });

    Navigator.pop(context);
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    setState(() {
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
    });

    await StorageService.saveConversations(_conversations);
  }

  void _updateConversationTitle(String firstMessage) {
    if (_currentConversation != null &&
        _currentConversation!.title == 'Obrolan Baru') {
      final title = firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;

      setState(() {
        _currentConversation!.title = title;
        _currentConversation!.updatedAt = DateTime.now();
      });
    }
  }

  Future<void> _saveCurrentConversation() async {
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

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    if (_currentConversation == null) {
      await _createNewConversation();
    }

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    if (_messages.length == 1) {
      _updateConversationTitle(text);
    }

    await _saveCurrentConversation();
    _scrollToBottom();

    _generateAIResponse(text);
  }

  Future<void> _generateAIResponse(String userInput) async {
    try {
      final aiResponse = await AIService.generateResponse(userInput, _messages);

      setState(() {
        _isLoading = false;
        _messages.insert(0, ChatMessage(text: aiResponse, isUser: false));

        if (_messages.length > 50) {
          _messages.removeRange(50, _messages.length);
        }
      });

      await _saveCurrentConversation();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.insert(
          0,
          ChatMessage(
            text:
                'Terjadi kesalahan saat memproses permintaan. Silakan coba lagi.',
            isUser: false,
          ),
        );
      });
      await _saveCurrentConversation();
      _scrollToBottom();
    }
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

  Future<void> _clearCurrentConversation() async {
    if (_currentConversation != null) {
      setState(() {
        _messages.clear();
        _currentConversation!.messages.clear();
        _currentConversation!.updatedAt = DateTime.now();
      });
      await _saveCurrentConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(colorScheme),
      drawer: _buildDrawer(colorScheme),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? ChatWidgets.buildWelcomeScreen(
                    colorScheme,
                    _suggestions,
                    _handleSubmitted,
                  )
                : _buildChatList(colorScheme),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 12.0,
                ),
                child: ChatWidgets.buildInputField(
                  context,
                  colorScheme,
                  _textController,
                  _handleSubmitted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        _currentConversation?.title ?? widget.title,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
    );
  }

  Widget _buildDrawer(ColorScheme colorScheme) {
    return Drawer(
      backgroundColor: colorScheme.surface,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.primaryContainer.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'AskPitra',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Assistant untuk UPITRA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createNewConversation,
                icon: const Icon(Icons.add),
                label: const Text('Obrolan Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada obrolan',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final isSelected =
                          _currentConversation?.id == conversation.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: isSelected
                              ? colorScheme.primaryContainer.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 4,
                            ),
                            leading: Icon(
                              Icons.chat_outlined,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                            title: Text(
                              conversation.title,
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatDate(conversation.updatedAt),
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            trailing: PopupMenuButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurface.withOpacity(0.6),
                                size: 20,
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showDeleteConversationDialog(
                                    conversation,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _switchConversation(conversation),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),

          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Mode Gelap'),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (bool value) {
                widget.onThemeToggle();
              },
              activeColor: colorScheme.primary,
            ),
            onTap: widget.onThemeToggle,
          ),

          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Tentang Aplikasi'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context, colorScheme);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConversationDialog(Conversation conversation) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Hapus Obrolan'),
            content: Text(
              'Apakah Anda yakin ingin menghapus obrolan "${conversation.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteConversation(conversation);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      );
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAboutDialog(BuildContext context, ColorScheme colorScheme) {
    showAboutDialog(
      context: context,
      applicationName: 'AskPitra',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.auto_awesome_outlined,
        size: 48,
        color: colorScheme.primary,
      ),
      children: [
        const Text(
          'AskPitra adalah asisten AI yang dirancang khusus untuk membantu mahasiswa mendapatkan informasi yang diperlukan.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Dibuat dengan ❤️ untuk komunitas UPITRA',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildChatList(ColorScheme colorScheme) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == 0) {
          return ChatWidgets.buildLoadingIndicator(colorScheme);
        }
        return _messages[_isLoading ? index - 1 : index];
      },
    );
  }
}
