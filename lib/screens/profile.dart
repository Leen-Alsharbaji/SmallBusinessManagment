/*
  profile.dart

  What this file does:
  - Provides a simple profile screen that shows the current user's basic
    status and exposes a sign-out button.
  - After signing out we route the user back to the '/sign-in' route so
    they can authenticate again.

  How to modify:
  - Add more user details (displayName, photoURL) by reading
    `FirebaseAuth.instance.currentUser`.
  - Change the post-sign-out routing by editing `_signOutAndRoute`.

  what this file has:
  presents the users details : such as email or uid, and a sign out button. After signing out, the user is routed back to the sign-in screen.
  presents the options for marketplaces/websies the user/seller wants to connect to with space to add their secret keys to help us connect each marketplace and make their api calls
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOutAndRoute(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AppScaffold(
      title: 'Profile',
      body: Container(
        color: Colors.blue,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user != null) ...[
                Text('Signed in as ${user.email ?? user.uid}'),
                const SizedBox(height: 12),
              ] else ...[
                const Text('Not signed in'),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: () => _signOutAndRoute(context),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}