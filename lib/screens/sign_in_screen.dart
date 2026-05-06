/*
  sign_in_screen.dart

  What this file does:
  - Renders the sign-in UI using Firebase UI Auth.
  - Keeps auth provider configuration in one place (the `providers` list).
  - Calls `onSignedIn` when authentication completes so the app can
    navigate to the appropriate screen.

  How to modify:
  - Add / remove providers in `providers`.
  - Change navigation in `onSignedIn` to redirect users elsewhere after
    successful sign-in.
*/

import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui_auth;

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The list of available auth providers shown to the user.
    final providers = [firebase_ui_auth.EmailAuthProvider()];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF000080), Color(0xFF4A90E2), Color(0xFFB3E5FC)],
          ),
        ),
        child: FirebaseUISignInScreen(
          providers: providers,
          onSignedIn: () {
            // Navigate to the profile route (registered in app.dart)
            Navigator.pushReplacementNamed(context, '/profile');
          },
        ),
      ),
    );
  }
}

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