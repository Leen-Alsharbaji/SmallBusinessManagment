/*
  sales_entry_form.dart

  What this file does:
  - Provides a form for manually entering sales data for a product.
  - Fetches available products from Firestore and presents them in a dropdown.
  - Allows user to input quantity sold, select the sales platform, and pick a sale date.
  - Saves the sale record to Firestore (collection "sales") and updates product stock.
  - Displays success/error messages.
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class SalesEntryForm extends StatefulWidget {
  const SalesEntryForm({super.key});

  @override
  State<SalesEntryForm> createState() => _SalesEntryFormState();
}

class _SalesEntryFormState extends State<SalesEntryForm> {
  // -------------------- Data --------------------
  final _formKey = GlobalKey<FormState>();
  
  // Product selection
  List<QueryDocumentSnapshot> _products = [];
  String? _selectedProductId;
  String? _selectedProductName;
  int _currentStock = 0;
  
  // Sale details
  int _quantitySold = 1;
  String _selectedPlatform = 'Trendyol';
  DateTime _saleDate = DateTime.now();
  
  // Controller for date display
  final TextEditingController _dateController = TextEditingController();
  
  // UI state
  bool _isLoading = false;
  bool _isFetchingProducts = true;

  // List of platforms (can be extended)
  final List<String> _platforms = [
    'Trendyol',
    'Amazon',
    'eBay',
    'Etsy',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();          // ← COMMENT: Pulls all products from Firestore
    _updateDateController();   // initialise date field
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // -------------------- Firestore Methods --------------------
  /// Fetches the list of products from Firestore 'products' collection.
  /// Ordered by product name.
  /// COMMENT: This is the main product pull from DB. If you need to debug,
  /// check the snapshot.docs length and individual doc fields.
  Future<void> _fetchProducts() async {
    setState(() => _isFetchingProducts = true);
    try {
      // COMMENT: The query below loads ALL products. For large catalogs,
      // consider pagination or limiting fields.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .get();
      setState(() {
        _products = snapshot.docs;
        _isFetchingProducts = false;
      });
      // COMMENT: snapshot.docs contains each product document.
      // Each doc has .id and .data() e.g. doc['name'], doc['currentStock'].
    } catch (e) {
      setState(() => _isFetchingProducts = false);
      _showSnackBar('Failed to load products: $e');
    }
  }

  void _onProductSelected(String? productId) {
    if (productId == null) return;
    // COMMENT: Locate the selected product document from the local list.
    final productDoc = _products.firstWhere((doc) => doc.id == productId);
    setState(() {
      _selectedProductId = productId;
      _selectedProductName = productDoc['name'];
      _currentStock = productDoc['currentStock'] ?? 0;
    });
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      _showSnackBar('Please select a product');
      return;
    }
    if (_quantitySold > _currentStock) {
      _showSnackBar('Insufficient stock! Available: $_currentStock');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // 1. Create a sale record in 'sales' collection
      // COMMENT: This writes a new document with the sale details.
      await firestore.collection('sales').add({
        'productId': _selectedProductId,
        'productName': _selectedProductName,
        'quantity': _quantitySold,
        'platform': _selectedPlatform,
        'saleDate': Timestamp.fromDate(_saleDate),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Update the product stock (decrement by quantity sold)
      // COMMENT: This modifies the existing product document.
      final productRef = firestore.collection('products').doc(_selectedProductId);
      await productRef.update({
        'currentStock': FieldValue.increment(-_quantitySold),
      });
      
      _showSnackBar('Sale recorded successfully!', isError: false);
      _resetForm();
    } catch (e) {
      _showSnackBar('Error saving sale: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedProductId = null;
      _selectedProductName = null;
      _quantitySold = 1;
      _selectedPlatform = 'Trendyol';
      _saleDate = DateTime.now();
      _currentStock = 0;
      _updateDateController();
    });
  }

  // -------------------- Helpers --------------------
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd.MM.yyyy').format(_saleDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _saleDate) {
      setState(() {
        _saleDate = picked;
        _updateDateController();
      });
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manual Sales Entry',
      body: Container(
        color: const Color(0xFF283240),
        child: _isFetchingProducts
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
     
                    children: [
                      // ---------- Product Dropdown ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedProductId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Product',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            dropdownColor: const Color(0xFF283240),
                            style: const TextStyle(color: Colors.white),
                            items: _products.map((doc) {
                              final name = doc['name'] ?? 'Unnamed';
                              final stock = doc['currentStock'] ?? 0;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text('$name (Stock: $stock)'),
                              );
                            }).toList(),
                            onChanged: _onProductSelected,
                            validator: (value) =>
                                value == null ? 'Please select a product' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Quantity Sold (Text field) ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            initialValue: _quantitySold.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Quantity sold',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: UnderlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _quantitySold = parsed);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              final qty = int.tryParse(value);
                              if (qty == null || qty < 1) {
                                return 'Must be a positive number';
                              }
                              if (_selectedProductId != null && qty > _currentStock) {
                                return 'Not enough stock (max $_currentStock)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Platform Dropdown ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedPlatform,
                            items: _platforms.map((platform) {
                              return DropdownMenuItem<String>(
                                value: platform,
                                child: Text(platform,
                                    style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedPlatform = val!),
                            decoration: const InputDecoration(
                              labelText: 'Sales Platform',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            dropdownColor: const Color(0xFF283240),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Date Picker (Text field with onTap) ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Sale Date',
                              labelStyle: const TextStyle(color: Colors.white70),
                              suffixIcon: const Icon(Icons.calendar_today,
                                  color: Colors.white70),
                              border: const UnderlineInputBorder(),
                            ),
                            onTap: () => _selectDate(context),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please select a date' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ---------- Submit Button ----------
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitSale,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Saving...' : 'Record Sale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}