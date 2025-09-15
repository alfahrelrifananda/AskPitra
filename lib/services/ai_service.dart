import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'knowledge_base.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  static Future<String> generateResponse(
    String userInput,
    List<ChatMessage> messages,
  ) async {
    try {
      String? directAnswer = _tryDirectAnswer(userInput);

      String enhancedInput = KnowledgeBase.enhancePromptWithKnowledge(
        userInput,
      );

      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      final headers = {'Content-Type': 'application/json'};

      List<Map<String, dynamic>> previousMessages = [];
      int messageLimit = messages.length > 6 ? 6 : messages.length;

      for (int i = messages.length - messageLimit; i < messages.length; i++) {
        previousMessages.add({
          "parts": [
            {"text": messages[i].text},
          ],
          "role": messages[i].isUser ? "user" : "model",
        });
      }

      previousMessages.add({
        "parts": [
          {"text": enhancedInput},
        ],
        "role": "user",
      });

      final body = jsonEncode({
        "contents": previousMessages,
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 2048,
          "stopSequences": [],
        },
        "systemInstruction": {
          "parts": [
            {"text": _getEnhancedSystemPrompt()},
          ],
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE",
          },
        ],
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (_isValidResponse(data)) {
          String aiResponse =
              data['candidates'][0]['content']['parts'][0]['text'] ??
              'Maaf, saya tidak dapat memproses permintaan Anda saat ini.';

          return _postProcessResponse(aiResponse, userInput);
        }
        return 'Maaf, saya tidak dapat memahami respons AI.';
      } else {
        print('Error Response: ${response.body}');
        return _getErrorMessage(response.statusCode);
      }
    } catch (e) {
      print('Exception caught: $e');
      if (e.toString().contains('TimeoutException')) {
        return 'Koneksi timeout. Silakan coba lagi.';
      }
      return 'Terjadi kesalahan jaringan. Silakan periksa koneksi Anda.';
    }
  }

  static String? _tryDirectAnswer(String userInput) {
    String lowerInput = userInput.toLowerCase().trim();

    if (lowerInput.contains('halo') ||
        lowerInput.contains('hai') ||
        lowerInput.contains('hello') ||
        lowerInput.contains('hi')) {
      return 'Halo! Saya AskPitra, asisten AI untuk membantu Anda mengetahui informasi tentang UPITRA (Universitas Pignatelli Triputra). Ada yang bisa saya bantu?';
    }

    if (lowerInput.contains('apa itu upitra') ||
        lowerInput.contains('tentang upitra')) {
      return KnowledgeBase.getKnowledgeByKey('upitra');
    }

    return null;
  }

  static String _getEnhancedSystemPrompt() {
    return '''
Anda adalah AskPitra, asisten AI khusus untuk UPITRA (Universitas Pignatelli Triputra). 

PERAN UTAMA:
- Menjadi sumber informasi terpercaya tentang UPITRA
- Membantu calon mahasiswa, mahasiswa, dan masyarakat umum memahami UPITRA
- Memberikan jawaban yang akurat berdasarkan knowledge base yang tersedia

PEDOMAN RESPON:
1. SELALU prioritaskan informasi dari konteks UPITRA yang diberikan
2. Gunakan bahasa Indonesia yang ramah, profesional, dan mudah dipahami
3. Jika ditanya hal di luar UPITRA, coba kaitkan dengan konteks universitas jika memungkinkan
4. Jika tidak tahu jawaban pasti, katakan dengan jujur dan sarankan untuk menghubungi admisi UPITRA
5. Berikan informasi yang lengkap namun ringkas dan mudah dicerna
6. Gunakan format yang menarik dengan bullet points atau numbering jika diperlukan

FOKUS INFORMASI:
- Program studi dan kurikulum
- Konsep Link and Match
- Visi, misi, dan nilai-nilai UPITRA
- Informasi pendaftaran dan admisi
- Lokasi dan fasilitas kampus
- Kemitraan dengan industri

Jawab dengan antusias dan membantu, seolah-olah Anda adalah bagian dari tim admisi UPITRA!
''';
  }

  static String _postProcessResponse(String response, String userInput) {
    response = response.trim();

    if (!response.endsWith('.') &&
        !response.endsWith('!') &&
        !response.endsWith('?')) {
      response += '.';
    }

    if (response.length < 50 &&
        !userInput.toLowerCase().contains('halo') &&
        !userInput.toLowerCase().contains('hai')) {
      response +=
          '\n\nAda informasi lain tentang UPITRA yang ingin Anda ketahui?';
    }

    return response;
  }

  static bool _isValidResponse(Map<String, dynamic> data) {
    return data['candidates'] != null &&
        data['candidates'].isNotEmpty &&
        data['candidates'][0]['content'] != null &&
        data['candidates'][0]['content']['parts'] != null &&
        data['candidates'][0]['content']['parts'].isNotEmpty &&
        data['candidates'][0]['content']['parts'][0]['text'] != null;
  }

  static String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Terjadi kesalahan dalam format permintaan. Silakan coba lagi.';
      case 401:
        return 'Akses tidak diotorisasi. Silakan periksa konfigurasi API.';
      case 403:
        return 'Akses ditolak. Silakan periksa konfigurasi API.';
      case 429:
        return 'Terlalu banyak permintaan. Silakan coba lagi dalam beberapa saat.';
      case 500:
      case 502:
      case 503:
        return 'Server sedang bermasalah. Silakan coba lagi nanti.';
      case 504:
        return 'Server timeout. Silakan coba lagi.';
      default:
        return 'Error $statusCode: Terjadi kesalahan tak terduga. Silakan coba lagi.';
    }
  }

  static bool isApiKeyValid() {
    return _apiKey.isNotEmpty && _apiKey.startsWith('AIza');
  }

  static Future<bool> checkServiceHealth() async {
    try {
      final response = await generateResponse(
        'test',
        [],
      ).timeout(const Duration(seconds: 10));
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
