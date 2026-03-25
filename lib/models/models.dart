import 'package:isar/isar.dart';

part 'models.g.dart';

// ─── BOOK ───────────────────────────────────────────────────────────────────

@collection
class Book {
  Id id = Isar.autoIncrement;
  late String title;
  late String filePath;
  late String fileType; // pdf, epub, image
  late DateTime uploadedAt;
  bool isProcessed = false;
  bool isProcessing = false;
  int totalPages = 0;
  int processedPages = 0;
  String? summary;
  String category = 'General'; // MRCS, FRCS, NHS, General
}

// ─── MCQ QUESTION ───────────────────────────────────────────────────────────

@collection
class McqQuestion {
  Id id = Isar.autoIncrement;
  late String question;
  late List<String> options;
  late int correctIndex;
  late String explanation;
  String category = 'General'; // MRCS, FRCS, NHS
  String difficulty = 'Medium'; // Easy, Medium, Hard
  String? imageBase64;
  String? sourceBookTitle;
  int timesAnswered = 0;
  int timesCorrect = 0;
  bool isFlagged = false;
  late DateTime createdAt;
}

// ─── SHORT ANSWER QUESTION ──────────────────────────────────────────────────

@collection
class ShortAnswerQuestion {
  Id id = Isar.autoIncrement;
  late String question;
  late String modelAnswer;
  String category = 'General';
  String difficulty = 'Medium';
  String? sourceBookTitle;
  bool isFlagged = false;
  late DateTime createdAt;
}

// ─── LONG ANSWER QUESTION ───────────────────────────────────────────────────

@collection
class LongAnswerQuestion {
  Id id = Isar.autoIncrement;
  late String question;
  late String modelAnswer;
  late List<String> keyPoints;
  String category = 'General';
  String difficulty = 'Hard';
  String? sourceBookTitle;
  bool isFlagged = false;
  late DateTime createdAt;
}

// ─── NOTE ───────────────────────────────────────────────────────────────────

@collection
class Note {
  Id id = Isar.autoIncrement;
  late String title;
  late String content;
  String category = 'General'; // MRCS, FRCS, NHS
  String type = 'Summary'; // Summary, KeyPoints, Clinical, Anatomy
  String? sourceBookTitle;
  bool isFavorite = false;
  late DateTime createdAt;
}

// ─── CLINICAL IMAGE ─────────────────────────────────────────────────────────

@collection
class ClinicalImage {
  Id id = Isar.autoIncrement;
  late String title;
  late String description;
  late String imageBase64;
  String type = 'Clinical'; // Clinical, Radiology, Sketch, Diagram
  String category = 'General';
  String? sourceBookTitle;
  List<String> tags = [];
  bool isFavorite = false;
  late DateTime createdAt;
}

// ─── QUIZ SESSION ────────────────────────────────────────────────────────────

@collection
class QuizSession {
  Id id = Isar.autoIncrement;
  late String mode; // timed, flashcard, practice, exam
  late String category;
  late int totalQuestions;
  int answeredQuestions = 0;
  int correctAnswers = 0;
  int timeLimitSeconds = 0;
  late DateTime startedAt;
  DateTime? completedAt;
  bool isCompleted = false;
}

// ─── SETTINGS ───────────────────────────────────────────────────────────────

@collection
class AppSettings {
  Id id = 1;
  String geminiApiKey = '';
  int dailyMcqTarget = 50;
  int dailyStudyMinutes = 60;
  bool backgroundProcessing = true;
  bool dailyReminder = true;
  String reminderTime = '08:00';
  String defaultCategory = 'All';
  int examTimerSeconds = 90; // per question
  bool showExplanationAfterAnswer = true;
  bool autoGenerateFromBooks = true;
}
