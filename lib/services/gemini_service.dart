import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Line 4: Accessing your secret key from Codemagic
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Line 6-9: Setting up the AI model
  final _model = GenerativeModel(
    model: 'gemini-1.5-pro-latest', // Pro is better for reading long textbooks
    apiKey: _apiKey,
  );

  // Line 11-25: This function sends your book text to the AI
  Future<String> getSurgeryStudyMaterial(String bookText) async {
    final prompt = [
      Content.text('''
        You are a Senior NHS General Surgeon. Use this text: "$bookText"
        Generate: 
        1. 3 MRCS/FRCS style MCQs.
        2. A management plan based on NICE guidelines.
        3. A summary of the surgical anatomy involved.
      ''')
    ];

    final response = await _model.generateContent(prompt);
    return response.text ?? "No response from AI";
  }
}
