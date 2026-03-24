import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GeminiService _aiService = GeminiService();
  String _aiResponse = "Upload a book to start studying...";
  bool _isLoading = false;

  // This function lets you pick a book from your phone
  Future<void> _pickAndProcessBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      
      // For now, we take the file name or a small snippet
      // In the next step, we will add the PDF text extractor
      String fileName = result.files.single.name;
      
      final response = await _aiService.getSurgeryStudyMaterial("Context from book: $fileName");
      
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Surgery Pro: FRCS & MRCS")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoading) CircularProgressIndicator(),
            if (!_isLoading) ...[
              ElevatedButton.icon(
                onPressed: _pickAndProcessBook,
                icon: Icon(Icons.upload_file),
                label: Text("Upload Surgery Book (PDF)"),
              ),
              SizedBox(height: 20),
              Text(_aiResponse, style: TextStyle(fontSize: 16)),
            ]
          ],
        ),
      ),
    );
  }
}
