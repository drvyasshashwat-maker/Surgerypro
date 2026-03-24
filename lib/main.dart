import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/surgical_question.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Tell Flutter to wake up before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Find a folder on your phone to store the "Vault"
  final dir = await getApplicationDocumentsDirectory();
  
  // 3. Open the "Vault" (Isar Database)
  // This uses the 'SurgicalQuestionSchema' created by your build_runner
  final isar = await Isar.open(
    [SurgicalQuestionSchema],
    directory: dir.path,
  );

  // 4. Start the app and give it the Database handle
  runApp(SurgeryProApp(isar: isar));
}

class SurgeryProApp extends StatelessWidget {
  final Isar isar;
  SurgeryProApp({required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surgery Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Makes it look modern like NHS apps
      ),
      home: HomeScreen(isar: isar), // Pass the database to the Home Screen
    );
  }
}
