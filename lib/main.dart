import 'package:flutter/material.dart';
import 'app.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await FirebaseService.initialize();
    runApp(const GamifiedProductivityApp());
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(GamifiedProductivityApp());
  }
}

/// Fallback error app for Firebase initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: const Center(
          child: Text('Failed to initialize Firebase. Please restart the app.'),
        ),
      ),
    );
  }
}
