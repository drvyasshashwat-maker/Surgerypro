import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'gemini_service.dart';

class ProcessingService {
  static Future<void> processBook(Book book, String category) async {
    try {
      // Mark as processing
      book.isProcessing = true;
      await DatabaseService.saveBook(book);

      String fullText = '';

      if (book.fileType == 'pdf') {
        fullText = await _extractPdfText(book.filePath, book);
      } else if (book.fileType == 'image') {
        fullText = await _describeImage(book.filePath);
      } else {
        fullText = await File(book.filePath).readAsString();
      }

      if (fullText.isEmpty) {
        book.isProcessing = false;
        await DatabaseService.saveBook(book);
        return;
      }

      // Process in chunks of 3000 characters
      final chunks = _splitIntoChunks(fullText, 3000);
      final totalChunks = chunks.length;

      List<McqQuestion> allMcqs = [];
      List<Note> allNotes = [];
      List<ShortAnswerQuestion> allShort = [];
      List<LongAnswerQuestion> allLong = [];

      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];

        try {
          // Generate MCQs from each chunk
          final mcqs = await GeminiService.generateMcqs(
            textContent: chunk,
            bookTitle: book.title,
            category: category,
            count: 5,
          );
          allMcqs.addAll(mcqs);

          // Generate notes from every 3rd chunk
          if (i % 3 == 0) {
            final notes = await GeminiService.generateNotes(
              textContent: chunk,
              bookTitle: book.title,
              category: category,
            );
            allNotes.addAll(notes);
          }

          // Generate short answers from every 5th chunk
          if (i % 5 == 0) {
            final shorts = await GeminiService.generateShortAnswers(
              textContent: chunk,
              bookTitle: book.title,
              category: category,
              count: 3,
            );
            allShort.addAll(shorts);
          }

          // Generate long answers from every 10th chunk
          if (i % 10 == 0) {
            final longs = await GeminiService.generateLongAnswers(
              textContent: chunk,
              bookTitle: book.title,
              category: category,
              count: 1,
            );
            allLong.addAll(longs);
          }

          // Update progress
          book.processedPages = ((i + 1) / totalChunks * book.totalPages).round();
          await DatabaseService.saveBook(book);

          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // Continue processing even if one chunk fails
          continue;
        }
      }

      // Save all generated content
      if (allMcqs.isNotEmpty) await DatabaseService.saveMcqs(allMcqs);
      if (allNotes.isNotEmpty) await DatabaseService.saveNotes(allNotes);
      if (allShort.isNotEmpty) await DatabaseService.saveShortAnswers(allShort);
      if (allLong.isNotEmpty) await DatabaseService.saveLongAnswers(allLong);

      // Generate summary
      final summaryChunk = fullText.substring(0, fullText.length.clamp(0, 5000));
      book.summary = await GeminiService.summarizeText(summaryChunk, 'English');

      book.isProcessed = true;
      book.isProcessing = false;
      await DatabaseService.saveBook(book);
    } catch (e) {
      book.isProcessing = false;
      await DatabaseService.saveBook(book);
      rethrow;
    }
  }

  static Future<String> _extractPdfText(String filePath, Book book) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      book.totalPages = document.pages.count;
      await DatabaseService.saveBook(book);

      final buffer = StringBuffer();
      final extractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        try {
          final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
          buffer.writeln(text);
        } catch (_) {
          continue;
        }
      }

      document.dispose();
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  static Future<String> _describeImage(String filePath) async {
    // For images, return a placeholder - Gemini vision would be used here
    return 'Clinical image uploaded from $filePath';
  }

  static List<String> _splitIntoChunks(String text, int chunkSize) {
    final chunks = <String>[];
    for (int i = 0; i < text.length; i += chunkSize) {
      chunks.add(text.substring(i, (i + chunkSize).clamp(0, text.length)));
    }
    return chunks;
  }

  static String getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (ext == 'epub') return 'epub';
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return 'image';
    return 'text';
  }
}
