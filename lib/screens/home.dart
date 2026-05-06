/*
  home.dart

  What this file does:
  - Provides the app's main `HomeScreen` shown after sign-in.
  - Shows a button to open the `ProfileScreen` and a sign-out button.

  Sign-out behavior:
  - The sign-out button explicitly calls `FirebaseAuth.instance.signOut()`
    and then routes the user back to '/sign-in' so they can sign in again.

  How to modify:
  - Change the sign-out routing target to any route you prefer.
  - Replace the `ProfileScreen` navigation with any other screen if desired.
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOutAndRoute(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 250, child: Image.asset('assets/dash.png')),
            Text('Welcome!', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _signOutAndRoute(context),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}