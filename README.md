# AskPitra - Flutter Chat Application

A Flutter-based AI chat application specifically designed for UPITRA (Universitas Pignatelli Triputra) with integrated knowledge base functionality.

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point and main UI
├── models/
│   └── chat_message.dart        # Chat message model and UI widget
├── services/
│   ├── ai_service.dart          # AI/Gemini API service
│   ├── knowledge_base.dart      # UPITRA knowledge base service
│   └── storage_service.dart     # Local storage service
└── widgets/
    └── chat_widgets.dart        # Reusable chat UI widgets
```

## 📋 File Descriptions

### `lib/main.dart`
- **Purpose**: Main application entry point and primary UI
- **Contains**: App configuration, main chat screen, navigation logic
- **Dependencies**: All other modules

### `lib/constants/app_constants.dart`
- **Purpose**: Centralized configuration and constants
- **Contains**: API keys, URLs, error messages, UI constants, default suggestions
- **Benefits**: Easy configuration management, no hardcoded values

### `lib/models/chat_message.dart`
- **Purpose**: Chat message data model and presentation
- **Contains**: ChatMessage widget with rich text parsing, timestamp handling, copy functionality
- **Features**: Supports markdown, code blocks, bold text, long-press actions

### `lib/services/ai_service.dart`
- **Purpose**: AI/Gemini API integration
- **Contains**: API communication, response parsing, error handling
- **Features**: Knowledge-enhanced prompts, conversation history, proper error messages

### `lib/services/knowledge_base.dart`
- **Purpose**: UPITRA-specific knowledge management
- **Contains**: Knowledge search, prompt enhancement, contextual information
- **Features**: Keyword matching, relevant context injection

### `lib/services/storage_service.dart`
- **Purpose**: Local data persistence
- **Contains**: Save/load messages, clear chat history, storage management
- **Features**: JSON serialization, error handling, storage size tracking

### `lib/widgets/chat_widgets.dart`
- **Purpose**: Reusable UI components
- **Contains**: Welcome screen, input field, loading indicators, dialogs
- **Benefits**: Consistent UI, reusable components, better maintainability

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- Valid Google Gemini API key

### Installation

1. **Clone or create the project structure**:
   ```bash
   mkdir ask_pitra
   cd ask_pitra
   flutter create .
   ```

2. **Replace the files** with the provided structured code:
   - Copy each file to its respective location
   - Ensure the directory structure matches exactly

3. **Update dependencies** in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     http: ^1.1.0
     shared_preferences: ^2.2.2
     shimmer: ^3.0.0
   ```

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Configure API Key**:
   - Update the `geminiApiKey` in `lib/constants/app_constants.dart`
   - Replace with your actual Google Gemini API key

6. **Run the application**:
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Configuration
Edit `lib/constants/app_constants.dart`:
- `geminiApiKey`: Your Google Gemini API key
- `aiTemperature`: AI response creativity (0.0-1.0)
- `maxOutputTokens`: Maximum response length

### Knowledge Base
Edit `lib/services/knowledge_base.dart`:
- Add new knowledge entries to `_knowledge` map
- Update `_keywords` list for better matching
- Modify search logic if needed

### UI Customization
Edit `lib/constants/app_constants.dart`:
- `defaultSuggestions`: Preset questions
- `welcomeMessage`: Welcome screen text
- Update error messages and labels

## 🎯 Features

- ✅ **Knowledge-Enhanced Responses**: Automatic context injection for UPITRA-related queries
- ✅ **Persistent Chat History**: Local storage with automatic save/load
- ✅ **Rich Text Support**: Markdown, code blocks, bold text formatting
- ✅ **Loading Indicators**: Beautiful shimmer loading effects
- ✅ **Error Handling**: Comprehensive error handling with user-friendly messages
- ✅ **Responsive Design**: Material 3 design with proper theming
- ✅ **Copy Functionality**: Long-press to copy messages
- ✅ **Suggestion System**: Quick-start questions for users

## 🔄 How It Works

1. **User Input**: User types a question
2. **Knowledge Search**: System searches for relevant UPITRA knowledge
3. **Prompt Enhancement**: If relevant knowledge found, context is added to the prompt
4. **AI Processing**: Enhanced prompt sent to Gemini API
5. **Response Display**: AI response displayed with rich formatting
6. **Storage**: Conversation automatically saved locally

## 🛠️ Customization

### Adding New Knowledge
```dart
// In lib/services/knowledge_base.dart
static const Map<String, String> _knowledge = {
  'your_new_topic': '''
  Your knowledge content here...
  ''',
};

static const List<String> _keywords = [
  'your_new_keyword',
  // ... existing keywords
];
```

### Adding New Suggestions
```dart
// In lib/constants/app_constants.dart
static const List<String> defaultSuggestions = [
  'Your new suggestion question',
  // ... existing suggestions
];
```

### Modifying AI Behavior
```dart
// In lib/constants/app_constants.dart
static const String systemInstruction = """
Your custom system instruction here...
""";
```

## 📱 Build and Deploy

### Android Release Build
```bash
flutter build apk --release
```

### iOS Release Build
```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Common Issues

1. **API Key Issues**: Ensure your Gemini API key is valid and has proper permissions
2. **Network Errors**: Check internet connection and API endpoint availability
3. **Storage Issues**: Clear app data if persistent storage problems occur
4. **Build Errors**: Run `flutter clean && flutter pub get`

### Debugging
- Enable debug prints in each service file
- Check console output for detailed error information
- Use Flutter Inspector for UI debugging

## 📄 License

This project is created for educational purposes. Please ensure you comply with Google Gemini API terms of service.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch
3. Follow the established file structure
4. Add proper documentation
5. Submit a pull request

---

**Note**: Remember to keep your API keys secure and never commit them to public repositories. Consider using environment variables or secure configuration files for production deployments.