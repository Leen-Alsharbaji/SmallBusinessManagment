/*
  profile.dart

  Enhanced Profile Screen:
  - Displays the current user's display name, email, and profile photo
    (if available in Firebase Auth).
  - Provides a form to connect a Trendyol seller account (seller ID & password).
  - Shows placeholder cards for other marketplaces (UI only).
  - Sign‑out button still routes back to '/sign-in'.
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
 
  final TextEditingController _trendyolSellerIdController = TextEditingController();
  final TextEditingController _trendyolPasswordController = TextEditingController();

  
  void _connectTrendyol() {
    final sellerId = _trendyolSellerIdController.text.trim();
    final password = _trendyolPasswordController.text.trim();
    if (sellerId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both Seller ID and Password')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trendyol connected (simulated) for seller ID: $sellerId')),
    );
    
    _trendyolSellerIdController.clear();
    _trendyolPasswordController.clear();
  }

  Future<void> _signOutAndRoute(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AppScaffold(
      title: 'Profile',
      backgroundColor: const Color(0xFF283240),
      body: Container(
        color: const Color(0xFF283240),
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ---- User Profile Section ----
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // User photo
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, size: 32, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // User name & email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Text(
                            user?.email ?? 'No email',
                             style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                        ]
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Trendyol Integration  ----
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Trendyol Integration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your Trendyol seller credentials to enable API calls.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _trendyolSellerIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Seller ID',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _trendyolPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password / API Secret',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _connectTrendyol,
                      icon: const Icon(Icons.link),
                      label: const Text('Connect Trendyol'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Other Marketplaces (UI only) ----
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Other marketplaces (UI demo)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMarketplacePlaceholder('Amazon', Icons.store),
                    const SizedBox(height: 8),
                    _buildMarketplacePlaceholder('eBay', Icons.sell),
                    const SizedBox(height: 8),
                    _buildMarketplacePlaceholder('Etsy', Icons.brush),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ---- Sign Out Button ----
            Center(
              child: ElevatedButton(
                onPressed: () => _signOutAndRoute(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplacePlaceholder(String name, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name integration is not yet implemented (UI only)')),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
        ),
        child: const Text('Connect (UI only)'),
      ),
    );
  }
}