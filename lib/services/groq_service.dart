import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

/// A Groq model the user can pick from in the assistant. Limited to
/// free-tier models to keep clear of tighter rate limits.
class GroqModelOption {
  final String id;
  final String label;

  const GroqModelOption({required this.id, required this.label});
}

class GroqService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Selectable models, in display order. The first entry is the default.
  static const List<GroqModelOption> availableModels = [
    GroqModelOption(id: 'llama-3.3-70b-versatile', label: 'Llama 3.3 70B'),
    GroqModelOption(id: 'llama-3.1-8b-instant', label: 'Llama 3.1 8B Instant'),
    GroqModelOption(id: 'gemma2-9b-it', label: 'Gemma2 9B'),
  ];

  static const String defaultModel = 'llama-3.3-70b-versatile';

  String _systemPrompt(String financialContext) => '''
You are "Fin", a friendly and concise personal-finance assistant built into an
expense-tracking app. Answer questions about the user's spending, income,
budget and savings using ONLY the data provided below. Be specific and cite
real numbers from the data. If the user asks something the data cannot answer,
say so briefly and offer general guidance. Keep answers short (a few sentences),
use the user's currency symbol (\$), and be encouraging.

=== USER FINANCIAL DATA ===
$financialContext
=== END DATA ===
''';

  Future<String> sendMessage({
    required String financialContext,
    required List<ChatMessage> history,
    required String message,
    String modelName = defaultModel,
  }) async {
    if (!AppConfig.isGroqConfigured) {
      throw Exception(
          'Groq API key not configured. Set GROQ_API_KEY via --dart-define '
          'or edit lib/core/app_config.dart.');
    }

    // OpenAI-compatible chat format: system prompt, then prior turns, then the
    // new user message.
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(financialContext)},
      for (final m in history)
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      {'role': 'user', 'content': message},
    ];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'model': modelName, 'messages': messages}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
          'Groq request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final reply =
        (choices != null && choices.isNotEmpty)
            ? (choices.first['message']?['content'] as String?)?.trim()
            : null;

    return reply != null && reply.isNotEmpty
        ? reply
        : "Sorry, I couldn't generate a response. Please try again.";
  }
}
