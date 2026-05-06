import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider; // Add this import
import 'package:firebase_ui_auth/firebase_ui_auth.dart';                  // And this import
import 'package:flutter/material.dart';

import 'screens/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(                                       // Modify from here...
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(providers: []);
        }

        return const HomeScreen();
      },
    );                                                                 // To here.
  }
}