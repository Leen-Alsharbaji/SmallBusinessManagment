/*
This is the Profile screen of the Small Business Management app. It allows users to view their profile 
information and connect their Trendyol marketplace account through a secure API integration. The screen fetches the user's profile data from Firebase Authentication and displays it in a card format.
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _trendyolSellerIdController = TextEditingController();
  final TextEditingController _trendyolPasswordController = TextEditingController();
  
  // API base URL 
  final String apiBaseUrl = 'http://localhost:8000/api';
  
  // State variables
  bool _isConnecting = false;
  bool _isTrendyolConnected = false;
  String? _connectedAt;
  String? _userDisplayName;
  String? _userEmail;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Set basic info from Firebase Auth
    setState(() {
      _userDisplayName = user.displayName;
      _userEmail = user.email;
      _userPhotoUrl = user.photoURL;
    });
    
    // Fetch marketplace connection status from FastAPI
    await _checkTrendyolConnection(user.uid);
  }
  
  Future<void> _checkTrendyolConnection(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/auth/marketplace/trendyol/$uid'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isTrendyolConnected = data['connected'] ?? false;
          _connectedAt = data['connected_at'];
        });
      }
    } catch (e) {
      print('Error checking connection: $e');
    }
  }

  Future<void> _connectTrendyol() async {
    final sellerId = _trendyolSellerIdController.text.trim();
    final password = _trendyolPasswordController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    
    if (sellerId.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in both Seller ID and Password');
      return;
    }
    
    if (user == null) {
      _showSnackBar('User not logged in');
      return;
    }
    
    setState(() => _isConnecting = true);
    
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/marketplace/trendyol'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'seller_id': sellerId,
          'api_password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        _showSnackBar('Trendyol connected successfully!', isError: false);
        _trendyolSellerIdController.clear();
        _trendyolPasswordController.clear();
        await _checkTrendyolConnection(user.uid);
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar('Error: ${error['detail'] ?? 'Connection failed'}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _signOutAndRoute(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
  }
  
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      backgroundColor: const Color(0xFF283240),
      body: Container(
        color: const Color(0xFF283240),
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // User Profile Section
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: _userPhotoUrl != null
                          ? NetworkImage(_userPhotoUrl!)
                          : null,
                      child: _userPhotoUrl == null
                          ? const Icon(Icons.person, size: 32, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userDisplayName ?? 'No name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail ?? 'No email',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Trendyol Integration Card
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Trendyol Integration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (_isTrendyolConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Connected',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isTrendyolConnected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Connected since: ${_connectedAt?.substring(0, 10) ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    const Text(
                      'Enter your Trendyol seller credentials to enable API calls. Your credentials will be encrypted before storage.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      onPressed: _isConnecting ? null : _connectTrendyol,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link),
                      label: Text(_isConnecting ? 'Connecting...' : 'Connect Trendyol'),
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

            // Other Marketplaces (UI only)
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
                      'Other marketplaces (coming soon)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMarketplacePlaceholder('Amazon', Icons.store),
                    const SizedBox(height: 8),
                    _buildMarketplacePlaceholder('Hepsiburada', Icons.shopping_bag),
                    const SizedBox(height: 8),
                    _buildMarketplacePlaceholder('eBay', Icons.sell),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
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
          _showSnackBar('$name integration coming soon', isError: false);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
        ),
        child: const Text('Coming soon'),
      ),
    );
  }
}