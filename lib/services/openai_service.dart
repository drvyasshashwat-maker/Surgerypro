import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  final String apiKey;

  OpenAIService(this.apiKey);

  Future<String> getChatCompletion(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey,
      },
      body: jsonEncode({
        'model': 'gpt-4.1-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from OpenAI: ${response.statusCode}');
    }
  }
}