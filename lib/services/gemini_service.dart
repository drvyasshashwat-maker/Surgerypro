import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/models.dart';
import 'database_service.dart';

class GeminiService {
  static GenerativeModel? _model;
  static String _apiKey = '';

  static Future<void> init() async {
    final settings = await DatabaseService.getSettings();
    _apiKey = settings.geminiApiKey;
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    }
  }

  static Future<void> updateApiKey(String key) async {
    _apiKey = key;
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
  }

  static bool get isReady => _model != null && _apiKey.isNotEmpty;

  // ── GENERATE MCQs ─────────────────────────────────────────────────────────

  static Future<List<McqQuestion>> generateMcqs({
    required String textContent,
    required String bookTitle,
    required String category,
    int count = 10,
  }) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final prompt = '''
You are an expert medical educator specializing in General Surgery for MRCS, FRCS, and NHS clinical practice.

From the following surgical text, generate $count high-quality MCQ questions.

TEXT:
$textContent

Generate questions in this EXACT JSON format (return ONLY the JSON array, no other text):
[
  {
    "question": "...",
    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
    "correctIndex": 0,
    "explanation": "...",
    "difficulty": "Easy|Medium|Hard"
  }
]

Rules:
- Questions must be clinically relevant and exam-standard
- Cover anatomy, physiology, diagnosis, management, complications
- Include some image-based scenario questions
- Make distractors plausible
- Explanations must be detailed and educational
- Category: $category
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonStr = _extractJson(text);
      final List<dynamic> data = jsonDecode(jsonStr);

      return data.map((item) {
        final q = McqQuestion()
          ..question = item['question'] ?? ''
          ..options = List<String>.from(item['options'] ?? [])
          ..correctIndex = item['correctIndex'] ?? 0
          ..explanation = item['explanation'] ?? ''
          ..difficulty = item['difficulty'] ?? 'Medium'
          ..category = category
          ..sourceBookTitle = bookTitle
          ..createdAt = DateTime.now();
        return q;
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate MCQs: $e');
    }
  }

  // ── GENERATE NOTES ────────────────────────────────────────────────────────

  static Future<List<Note>> generateNotes({
    required String textContent,
    required String bookTitle,
    required String category,
  }) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final prompt = '''
You are an expert surgical educator. From the following text, generate comprehensive study notes for $category exam preparation.

TEXT:
$textContent

Generate notes in this EXACT JSON format (return ONLY the JSON array):
[
  {
    "title": "...",
    "content": "...",
    "type": "Summary|KeyPoints|Clinical|Anatomy",
    "keyPoints": ["point1", "point2", "..."]
  }
]

Generate at least 3 different note types covering:
1. A comprehensive summary
2. Key clinical points and mnemonics
3. Exam-focused bullet points
4. Anatomy and physiology overview if relevant
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonStr = _extractJson(text);
      final List<dynamic> data = jsonDecode(jsonStr);

      return data.map((item) {
        final n = Note()
          ..title = item['title'] ?? ''
          ..content = item['content'] ?? ''
          ..type = item['type'] ?? 'Summary'
          ..category = category
          ..sourceBookTitle = bookTitle
          ..createdAt = DateTime.now();
        return n;
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate notes: $e');
    }
  }

  // ── GENERATE SHORT ANSWERS ────────────────────────────────────────────────

  static Future<List<ShortAnswerQuestion>> generateShortAnswers({
    required String textContent,
    required String bookTitle,
    required String category,
    int count = 5,
  }) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final prompt = '''
From the following surgical text, generate $count short answer questions for $category exam preparation.

TEXT:
$textContent

Return ONLY this JSON array:
[
  {
    "question": "...",
    "modelAnswer": "...",
    "difficulty": "Easy|Medium|Hard"
  }
]

Questions should require 3-5 sentence answers. Focus on clinical decision-making.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final jsonStr = _extractJson(response.text ?? '');
      final List<dynamic> data = jsonDecode(jsonStr);

      return data.map((item) {
        final q = ShortAnswerQuestion()
          ..question = item['question'] ?? ''
          ..modelAnswer = item['modelAnswer'] ?? ''
          ..difficulty = item['difficulty'] ?? 'Medium'
          ..category = category
          ..sourceBookTitle = bookTitle
          ..createdAt = DateTime.now();
        return q;
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate short answers: $e');
    }
  }

  // ── GENERATE LONG ANSWERS ─────────────────────────────────────────────────

  static Future<List<LongAnswerQuestion>> generateLongAnswers({
    required String textContent,
    required String bookTitle,
    required String category,
    int count = 3,
  }) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final prompt = '''
From the following surgical text, generate $count long answer / essay questions for $category.

TEXT:
$textContent

Return ONLY this JSON array:
[
  {
    "question": "...",
    "modelAnswer": "...",
    "keyPoints": ["point1", "point2", "..."],
    "difficulty": "Medium|Hard"
  }
]

These should be detailed structured answers suitable for MRCS/FRCS written exams.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final jsonStr = _extractJson(response.text ?? '');
      final List<dynamic> data = jsonDecode(jsonStr);

      return data.map((item) {
        final q = LongAnswerQuestion()
          ..question = item['question'] ?? ''
          ..modelAnswer = item['modelAnswer'] ?? ''
          ..keyPoints = List<String>.from(item['keyPoints'] ?? [])
          ..difficulty = item['difficulty'] ?? 'Hard'
          ..category = category
          ..sourceBookTitle = bookTitle
          ..createdAt = DateTime.now();
        return q;
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate long answers: $e');
    }
  }

  // ── SUMMARIZE TEXT ────────────────────────────────────────────────────────

  static Future<String> summarizeText(String text, String language) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final langInstruction =
        language == 'English' ? '' : 'Translate the summary to $language.';

    final prompt = '''
Summarize the following surgical text in a clear, structured format for medical exam preparation. 
Include key points, clinical pearls, and important facts. $langInstruction

TEXT:
$text
''';

    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? 'Could not generate summary';
  }

  // ── TRANSLATE TEXT ────────────────────────────────────────────────────────

  static Future<String> translateText(String text, String targetLanguage) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final prompt = 'Translate the following medical text to $targetLanguage:\n\n$text';
    final response = await _model!.generateContent([Content.text(prompt)]);
    return response.text ?? 'Could not translate';
  }

  // ── CHAT WITH AI ──────────────────────────────────────────────────────────

  static Future<String> chat(String message, List<Map<String, String>> history) async {
    if (!isReady) throw Exception('Gemini API key not set');

    final chat = _model!.startChat(
      history: history.map((m) => Content(m['role']!, [TextPart(m['text']!)])).toList(),
      systemInstruction: Content.text(
        'You are SurgeryPro AI, an expert in General Surgery helping with MRCS, FRCS, and NHS clinical practice. '
        'Provide accurate, evidence-based surgical knowledge. Be concise but comprehensive.',
      ),
    );

    final response = await chat.sendMessage(Content.text(message));
    return response.text ?? 'No response';
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static String _extractJson(String text) {
    // Remove markdown code blocks if present
    text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    // Find JSON array
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1) throw Exception('No JSON found in response');
    return text.substring(start, end + 1);
  }
}
