import 'package:google_generative_ai/google_generative_ai.dart';

// Access the key you defined in the build script
const apiKey = String.fromEnvironment('GEMINI_API_KEY');

final _model = GenerativeModel(
  model: 'gemini-3.1-flash-preview', // The 3.1 Flash ID for March 2026
  apiKey: _apiKey,
);

// To send a message:
final content = [Content.text('Hello Gemini, help me with this surgery case...')];
final response = await model.generateContent(content);
print(response.text);
