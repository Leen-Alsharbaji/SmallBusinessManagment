import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui_auth;

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [firebase_ui_auth.EmailAuthProvider()];

    return Scaffold(
      body: Container( 
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF000080), 
              Color(0xFF4A90E2), 
              Color(0xFFB3E5FC), 
            ],
          ),
        ),
        child: FirebaseUISignInScreen( 
          providers: providers,
          onSignedIn: () {
            Navigator.pushReplacementNamed(context, '/profile');
          },
        ),
      ),
    );
  }
}

// Your existing FirebaseUISignInScreen stays exactly the same
class FirebaseUISignInScreen extends StatelessWidget {
  final List<firebase_ui_auth.AuthProvider> providers;
  final VoidCallback onSignedIn;

  const FirebaseUISignInScreen({
    super.key,
    required this.providers,
    required this.onSignedIn,
  });

  @override
  Widget build(BuildContext context) {
    return firebase_ui_auth.SignInScreen(
      providers: providers,
      actions: [
        firebase_ui_auth.AuthStateChangeAction<firebase_ui_auth.UserCreated>((context, state) {
          onSignedIn();
        }),
        firebase_ui_auth.AuthStateChangeAction<firebase_ui_auth.SignedIn>((context, state) {
          onSignedIn();
        }),
      ],
    );
  }
}