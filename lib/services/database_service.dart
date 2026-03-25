import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseService {
  static late Isar _isar;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        BookSchema,
        McqQuestionSchema,
        ShortAnswerQuestionSchema,
        LongAnswerQuestionSchema,
        NoteSchema,
        ClinicalImageSchema,
        QuizSessionSchema,
        AppSettingsSchema,
      ],
      directory: dir.path,
    );
    _initialized = true;

    // Init settings if not exist
    final settings = await _isar.appSettings.get(1);
    if (settings == null) {
      await _isar.writeTxn(() async {
        await _isar.appSettings.put(AppSettings());
      });
    }
  }

  static Isar get db => _isar;

  // ── SETTINGS ──────────────────────────────────────────────────────────────

  static Future<AppSettings> getSettings() async {
    return (await _isar.appSettings.get(1)) ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings s) async {
    await _isar.writeTxn(() async => await _isar.appSettings.put(s));
  }

  // ── BOOKS ─────────────────────────────────────────────────────────────────

  static Future<List<Book>> getBooks() async {
    return await _isar.books.where().sortByUploadedAtDesc().findAll();
  }

  static Future<int> saveBook(Book book) async {
    return await _isar.writeTxn(() async => await _isar.books.put(book));
  }

  static Future<void> deleteBook(int id) async {
    await _isar.writeTxn(() async => await _isar.books.delete(id));
  }

  // ── MCQ ───────────────────────────────────────────────────────────────────

  static Future<List<McqQuestion>> getMcqs({
    String? category,
    String? difficulty,
    int limit = 50,
  }) async {
    var query = _isar.mcqQuestions.where();
    final all = await query.findAll();
    var filtered = all;
    if (category != null && category != 'All') {
      filtered = filtered.where((q) => q.category == category).toList();
    }
    if (difficulty != null && difficulty != 'All') {
      filtered = filtered.where((q) => q.difficulty == difficulty).toList();
    }
    filtered.shuffle();
    return filtered.take(limit).toList();
  }

  static Future<void> saveMcq(McqQuestion q) async {
    await _isar.writeTxn(() async => await _isar.mcqQuestions.put(q));
  }

  static Future<void> saveMcqs(List<McqQuestion> qs) async {
    await _isar.writeTxn(() async => await _isar.mcqQuestions.putAll(qs));
  }

  static Future<int> getMcqCount() async {
    return await _isar.mcqQuestions.count();
  }

  // ── NOTES ─────────────────────────────────────────────────────────────────

  static Future<List<Note>> getNotes({String? category}) async {
    final all = await _isar.notes.where().sortByCreatedAtDesc().findAll();
    if (category == null || category == 'All') return all;
    return all.where((n) => n.category == category).toList();
  }

  static Future<void> saveNote(Note note) async {
    await _isar.writeTxn(() async => await _isar.notes.put(note));
  }

  static Future<void> saveNotes(List<Note> notes) async {
    await _isar.writeTxn(() async => await _isar.notes.putAll(notes));
  }

  static Future<int> getNoteCount() async {
    return await _isar.notes.count();
  }

  // ── SHORT ANSWER ──────────────────────────────────────────────────────────

  static Future<List<ShortAnswerQuestion>> getShortAnswers({
    String? category,
    int limit = 20,
  }) async {
    final all = await _isar.shortAnswerQuestions.where().findAll();
    var filtered = category == null || category == 'All'
        ? all
        : all.where((q) => q.category == category).toList();
    filtered.shuffle();
    return filtered.take(limit).toList();
  }

  static Future<void> saveShortAnswers(List<ShortAnswerQuestion> qs) async {
    await _isar.writeTxn(
        () async => await _isar.shortAnswerQuestions.putAll(qs));
  }

  // ── LONG ANSWER ───────────────────────────────────────────────────────────

  static Future<List<LongAnswerQuestion>> getLongAnswers({
    String? category,
    int limit = 10,
  }) async {
    final all = await _isar.longAnswerQuestions.where().findAll();
    var filtered = category == null || category == 'All'
        ? all
        : all.where((q) => q.category == category).toList();
    filtered.shuffle();
    return filtered.take(limit).toList();
  }

  static Future<void> saveLongAnswers(List<LongAnswerQuestion> qs) async {
    await _isar.writeTxn(
        () async => await _isar.longAnswerQuestions.putAll(qs));
  }

  // ── IMAGES ────────────────────────────────────────────────────────────────

  static Future<List<ClinicalImage>> getImages({String? category}) async {
    final all =
        await _isar.clinicalImages.where().sortByCreatedAtDesc().findAll();
    if (category == null || category == 'All') return all;
    return all.where((i) => i.category == category).toList();
  }

  static Future<void> saveImages(List<ClinicalImage> images) async {
    await _isar.writeTxn(() async => await _isar.clinicalImages.putAll(images));
  }

  static Future<int> getImageCount() async {
    return await _isar.clinicalImages.count();
  }

  // ── QUIZ SESSIONS ─────────────────────────────────────────────────────────

  static Future<void> saveSession(QuizSession session) async {
    await _isar.writeTxn(() async => await _isar.quizSessions.put(session));
  }

  static Future<List<QuizSession>> getRecentSessions({int limit = 10}) async {
    return await _isar.quizSessions
        .where()
        .sortByStartedAtDesc()
        .limit(limit)
        .findAll();
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  static Future<Map<String, int>> getStats() async {
    return {
      'mcqs': await _isar.mcqQuestions.count(),
      'notes': await _isar.notes.count(),
      'images': await _isar.clinicalImages.count(),
      'books': await _isar.books.count(),
      'shortAnswers': await _isar.shortAnswerQuestions.count(),
      'longAnswers': await _isar.longAnswerQuestions.count(),
    };
  }
}
