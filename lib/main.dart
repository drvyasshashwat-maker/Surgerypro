import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/gemini_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await GeminiService.init();
  runApp(const SurgeryProApp());
}

class SurgeryProApp extends StatelessWidget {
  const SurgeryProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SurgeryPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
