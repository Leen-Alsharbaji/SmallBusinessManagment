import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';

// Re-export MyApp for tests that import `main.dart`.
export 'app.dart' show MyApp;

/// Entrypoint: load env, initialize Firebase and run the app defined in `app.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env
  await dotenv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}