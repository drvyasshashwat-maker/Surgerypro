import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/gemini_service.dart';
import 'practice_screen.dart'; // Ensure this file exists in lib/screens/

class HomeScreen extends StatefulWidget {
  final Isar isar;
  HomeScreen({required this.isar});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GeminiService _aiService;
  String _statusMessage = "Ready to build your surgical knowledge base.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pass the database to the AI service so it can save questions
    _aiService = GeminiService(widget.isar);
  }

  // Helper: Extracts words from the physical PDF file
  Future<String> _readPdf(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return "Error: $e";
    }
  }

  // Logic: Picks book, extracts text, sends to Gemini, and saves to Isar
  Future<void> _handleBookUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _statusMessage = "Reading textbook...";
      });

      try {
        final String path = result.files.single.path!;
        final String fileName = result.files.single.name;
        
        // 1. Extract text
        String fullText = await _readPdf(path);
        
        // 2. Send snippet to Gemini (limited to 6000 chars for efficiency)
        String snippet = fullText.length > 6000 ? fullText.substring(0, 6000) : fullText;
        
        setState(() => _statusMessage = "Gemini is generating MCQs...");
        
        // 3. AI Service processes and saves directly to Database
        await _aiService.processAndSaveBookContent(snippet, fileName);

        setState(() {
          _statusMessage = "Success! New questions added from $fileName";
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _statusMessage = "System Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Surgery Pro: MRCS & FRCS"),
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Surgical Icon / Logo Area
            Icon(Icons.health_and_safety, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "Surgical Knowledge Engine",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),

            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 20),
            ],

            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            SizedBox(height: 50),

            // Action Buttons
            if (!_isLoading) ...[
              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _handleBookUpload,
                  icon: Icon(Icons.upload_file),
                  label: Text("UPLOAD TEXTBOOK"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Practice Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticeScreen(isar: widget.isar),
                      ),
                    );
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text("START PRACTICE MODE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

