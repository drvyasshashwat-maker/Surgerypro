import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GeminiService _aiService = GeminiService();
  String _aiResponse = "Upload a surgical textbook to start your study session.";
  bool _isLoading = false;

  // 1. Function to extract text from the PDF file
  Future<String> _extractTextFromPdf(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extracts text from all pages of the book
      String text = PdfTextExtractor(document).extractText();
      document.dispose(); // Critical for saving memory on your phone
      return text;
    } catch (e) {
      return "Error reading PDF content: $e";
    }
  }

  // 2. Main function to pick the book and send it to Gemini
  Future<void> _pickAndProcessBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      
      try {
        // Extract the actual medical text
        String fullText = await _extractTextFromPdf(result.files.single.path!);
        
        // Take a high-yield snippet (first 6000 characters) for the AI to analyze
        String snippet = fullText.length > 6000 ? fullText.substring(0, 6000) : fullText;
        
        // Send to your Gemini Service
        final response = await _aiService.getSurgeryStudyMaterial(snippet);
        
        setState(() {
          _aiResponse = response;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _aiResponse = "Processing error: $e";
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
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Surgical Knowledge Engine",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Upload your books (Bailey & Love, Sabiston, etc.) to generate MCQs."),
            SizedBox(height: 30),
            
            Center(
              child: _isLoading 
                ? Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Gemini is analyzing your textbook..."),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: _pickAndProcessBook,
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text("UPLOAD SURGERY BOOK"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
            ),
            
            SizedBox(height: 40),
            Divider(),
            Text(
              "Study Material & MCQs:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            SizedBox(height: 15),
            
            // The area where the AI questions and notes will appear
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                _aiResponse,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
