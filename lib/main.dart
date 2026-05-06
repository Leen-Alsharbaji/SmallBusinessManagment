import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
// Re-export MyApp for tests that import `main.dart`.
export 'app.dart' show MyApp;

/// Entrypoint: initialize Firebase and run the app defined in `app.dart`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}