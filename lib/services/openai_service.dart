import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String apiKey;

  OpenAIService() : apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  
  void validateApiKey() {
    if (apiKey.isEmpty) {
      throw Exception('API key must not be empty');
    }
  }
}

// Add any additional methods and logic for your OpenAI service here.