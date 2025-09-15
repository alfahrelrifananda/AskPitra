import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/chat_message.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'widgets/chat_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  try {
    await dotenv.load(fileName: ".env"); // Load environment variables
  } catch (e) {
    throw Exception('Error loading .env file: $e'); // Print error if any
  }
  runApp(const MyApp()); // Runs the app
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskPitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'AskPitra',
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
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

  final List<String> _suggestions = [
    'Filosofi UPITRA',
    'Program Studi di UPITRA',
    'Nilai-Nilai UPITRA',
    'Apa visi dan misi UPITRA',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads messages from storage
  Future<void> _loadMessages() async {
    final messages = await StorageService.loadMessages();
    setState(() {
      _messages.clear();
      _messages.addAll(messages);
    });
  }

  /// Saves messages to storage
  Future<void> _saveMessages() async {
    await StorageService.saveMessages(_messages);
  }

  /// Handles message submission
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _saveMessages();
    _scrollToBottom();

    _generateAIResponse(text);
  }

  /// Generates AI response
  Future<void> _generateAIResponse(String userInput) async {
    try {
      final aiResponse = await AIService.generateResponse(userInput, _messages);

      setState(() {
        _isLoading = false;
        _messages.insert(0, ChatMessage(text: aiResponse, isUser: false));

        // Limit messages to prevent memory issues
        if (_messages.length > 50) {
          _messages.removeRange(50, _messages.length);
        }
      });

      _saveMessages();
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
      _saveMessages();
      _scrollToBottom();
    }
  }

  /// Scrolls to bottom of chat
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

  /// Clears all chat messages
  Future<void> _clearChat() async {
    await StorageService.clearMessages();
    setState(() {
      _messages.clear();
    });
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

  /// Builds the app bar
  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: Text(widget.title, style: TextStyle(color: colorScheme.onSurface)),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      actions: [
        // Clear chat button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () =>
              ChatWidgets.showClearChatDialog(context, colorScheme, _clearChat),
          tooltip: 'Clear chat history',
        ),
      ],
    );
  }

  /// Builds the navigation drawer
  Widget _buildDrawer(ColorScheme colorScheme) {
    return NavigationDrawer(
      backgroundColor: colorScheme.surface,
      children: [
        // Drawer Header
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primary.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.chat_bubble_outline,
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

        // Navigation Items
        NavigationDrawerDestination(
          icon: Icon(Icons.chat_outlined, color: colorScheme.onSurfaceVariant),
          selectedIcon: Icon(Icons.chat, color: colorScheme.primary),
          label: const Text('Chat'),
        ),
        NavigationDrawerDestination(
          icon: Icon(
            Icons.history_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          selectedIcon: Icon(Icons.history, color: colorScheme.primary),
          label: const Text('Riwayat Chat'),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(),
        ),

        // Settings Section
        ListTile(
          leading: Icon(
            Icons.settings_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          title: const Text('Pengaturan'),
          onTap: () {
            Navigator.pop(context);
            _showSettingsDialog(context, colorScheme);
          },
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
        ListTile(
          leading: Icon(
            Icons.help_outline,
            color: colorScheme.onSurfaceVariant,
          ),
          title: const Text('Bantuan'),
          onTap: () {
            Navigator.pop(context);
            _showHelpDialog(context, colorScheme);
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Shows settings dialog
  void _showSettingsDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pengaturan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Mode Gelap'),
                trailing: Switch(
                  value: widget.isDarkMode,
                  onChanged: (bool value) {
                    widget.onThemeToggle();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  /// Shows about dialog
  void _showAboutDialog(BuildContext context, ColorScheme colorScheme) {
    showAboutDialog(
      context: context,
      applicationName: 'AskPitra',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.chat_bubble_outline,
        size: 48,
        color: colorScheme.primary,
      ),
      children: [
        const Text(
          'AskPitra adalah asisten AI yang dirancang khusus untuk membantu mahasiswa dan staf UPITRA mendapatkan informasi yang diperlukan.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Dibuat dengan ❤️ untuk komunitas UPITRA',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  /// Shows help dialog
  void _showHelpDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bantuan'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cara Menggunakan AskPitra:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('1. Ketik pertanyaan Anda di kotak input'),
                Text('2. Tekan tombol kirim atau Enter'),
                Text('3. Tunggu respons dari AI'),
                Text('4. Gunakan saran pertanyaan untuk memulai'),
                SizedBox(height: 16),
                Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Ajukan pertanyaan yang spesifik'),
                Text('• Gunakan bahasa Indonesia yang jelas'),
                Text('• Jika tidak puas, coba formulasi ulang pertanyaan'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the chat list
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
