/*
  sales_entry_form.dart

  What this file does:
  - Provides a form for manually entering sales data for a product.
  - Fetches available products from unified_products collection in Firestore.
  - Allows user to input quantity sold, sales price, currency, notes, and platform.
  - When "Other" platform is selected, shows a text field for custom platform name.
  - Saves the sale record to Firestore (collection "orders") and updates product stock.
  - Includes an admin button to import test products from JSON file.
  - Displays success/error messages.
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _selectedUnifiedProductId;
  String? _selectedProductName;
  String? _selectedBrand;
  String? _selectedPlatformsList;
  int _currentTotalStock = 0;
  
  // Sale details
  int _quantitySold = 1;
  int _salesPrice = 0;
  String _currency = 'USD';
  String _selectedPlatform = 'Trendyol';
  String _otherPlatform = '';
  bool _showOtherPlatformField = false;
  String _notes = '';
  DateTime _saleDate = DateTime.now();
  
  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _otherPlatformController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // UI state
  bool _isLoading = false;
  bool _isFetchingProducts = true;
  bool _isImporting = false;

  // Lists
  final List<String> _platforms = [
    'Trendyol',
    'Amazon',
    'eBay',
    'Etsy',
    'Hepsiburada',
    'Other',
  ];

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'TRY',
    'JPY',
    'CNY',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();          
    _updateDateController();  
  }

  @override
  void dispose() {
    _dateController.dispose();
    _otherPlatformController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // -------------------- Firestore Methods --------------------
  
  /// Fetches the list of products from Firestore 'unified_products' collection
  Future<void> _fetchProducts() async {
    setState(() => _isFetchingProducts = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('unified_products')
          .orderBy('name')
          .get();
      setState(() {
        _products = snapshot.docs;
        _isFetchingProducts = false;
      });
    } catch (e) {
      setState(() => _isFetchingProducts = false);
      _showSnackBar('Failed to load products: $e');
    }
  }

  /// Imports products from products.json file
  Future<void> _importProductsFromJson() async {
    // Check if products already exist
    if (_products.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Products Already Exist'),
          content: Text(
            'You already have ${_products.length} products in your database. '
            'Importing will ADD more products (not replace). '
            'Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Add More'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    
    setState(() => _isImporting = true);
    
    try {
      // Load the JSON file
      final String jsonString = await rootBundle.loadString('products.json');
      final List<dynamic> productsList = json.decode(jsonString);
      
      final firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int errorCount = 0;
      
      // Add each product to Firestore
      for (var product in productsList) {
        try {
          await firestore.collection('unified_products').add({
            ...Map<String, dynamic>.from(product),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          successCount++;
          print('✓ Added: ${product['name']}');
        } catch (e) {
          print('✗ Failed: ${product['name']} - $e');
          errorCount++;
        }
      }
      
      // Show result
      _showSnackBar(
        'Imported $successCount products successfully! ${errorCount > 0 ? "$errorCount failed." : ""}',
        isError: false,
      );
      
      // Refresh the product list
      await _fetchProducts();
      
    } catch (e) {
      print('Import error: $e');
      _showSnackBar('Failed to import products: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _onProductSelected(String? productId) {
    if (productId == null) return;
    final productDoc = _products.firstWhere((doc) => doc.id == productId);
    setState(() {
      _selectedUnifiedProductId = productId;
      _selectedProductName = productDoc['name'] ?? 'Unnamed';
      _selectedBrand = productDoc['brand'] ?? '';
      _selectedPlatformsList = productDoc['platforms'] != null 
          ? (productDoc['platforms'] as List).join(', ') 
          : '';
      _currentTotalStock = productDoc['totalStock'] ?? 0;
    });
  }

  void _onPlatformChanged(String? platform) {
    if (platform == null) return;
    setState(() {
      _selectedPlatform = platform;
      _showOtherPlatformField = (platform == 'Other');
      if (!_showOtherPlatformField) {
        _otherPlatform = '';
        _otherPlatformController.clear();
      }
    });
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnifiedProductId == null) {
      _showSnackBar('Please select a product');
      return;
    }
    if (_quantitySold > _currentTotalStock) {
      _showSnackBar('Insufficient stock! Available: $_currentTotalStock');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      final String finalPlatform = _showOtherPlatformField && _otherPlatform.isNotEmpty
          ? _otherPlatform
          : _selectedPlatform;
      
      // Create sale record in 'orders' collection
      await firestore.collection('orders').add({
        'unifiedProductId': _selectedUnifiedProductId,
        'productName': _selectedProductName,
        'quantity': _quantitySold,
        'salesPrice': _salesPrice,
        'currency': _currency,
        'platform': finalPlatform,
        'notes': _notes,
        'saleDate': Timestamp.fromDate(_saleDate),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update product stock
      final productRef = firestore.collection('unified_products').doc(_selectedUnifiedProductId);
      await productRef.update({
        'totalStock': FieldValue.increment(-_quantitySold),
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
      _selectedUnifiedProductId = null;
      _selectedProductName = null;
      _selectedBrand = null;
      _quantitySold = 1;
      _salesPrice = 0;
      _currency = 'USD';
      _selectedPlatform = 'Trendyol';
      _otherPlatform = '';
      _showOtherPlatformField = false;
      _notes = '';
      _saleDate = DateTime.now();
      _currentTotalStock = 0;
      _otherPlatformController.clear();
      _notesController.clear();
      _updateDateController();
    });
  }

  // -------------------- Helpers --------------------
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUnifiedProductId,
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
                                  final brand = doc['brand'] ?? '';
                                  final stock = doc['totalStock'] ?? 0;
                                  final displayText = brand.isNotEmpty 
                                      ? '$name ($brand) - Stock: $stock'
                                      : '$name - Stock: $stock';
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(displayText),
                                  );
                                }).toList(),
                                onChanged: _onProductSelected,
                                validator: (value) =>
                                    value == null ? 'Please select a product' : null,
                              ),
                              if (_selectedBrand != null && _selectedBrand!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Brand: $_selectedBrand',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (_selectedPlatformsList != null && _selectedPlatformsList!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Available on: $_selectedPlatformsList',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Quantity Sold ----------
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
                              if (_selectedUnifiedProductId != null && qty > _currentTotalStock) {
                                return 'Not enough stock (max $_currentTotalStock)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Sales Price ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            initialValue: _salesPrice == 0 ? '' : _salesPrice.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Sales Price',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Enter price amount',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: UnderlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed >= 0) {
                                setState(() => _salesPrice = parsed);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter sales price';
                              }
                              final price = int.tryParse(value);
                              if (price == null || price < 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Currency Dropdown ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            items: _currencies.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency,
                                    style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _currency = val!),
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            dropdownColor: const Color(0xFF283240),
                            style: const TextStyle(color: Colors.white),
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
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPlatform,
                                items: _platforms.map((platform) {
                                  return DropdownMenuItem<String>(
                                    value: platform,
                                    child: Text(platform,
                                        style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: _onPlatformChanged,
                                decoration: const InputDecoration(
                                  labelText: 'Sales Platform',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                dropdownColor: const Color(0xFF283240),
                                style: const TextStyle(color: Colors.white),
                              ),
                              if (_showOtherPlatformField)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: TextFormField(
                                    controller: _otherPlatformController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Specify Platform',
                                      labelStyle: TextStyle(color: Colors.white70),
                                      hintText: 'e.g., Shopify, WooCommerce, etc.',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() => _otherPlatform = value);
                                    },
                                    validator: (value) {
                                      if (_showOtherPlatformField && (value == null || value.isEmpty)) {
                                        return 'Please specify the platform';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Notes ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _notesController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Additional order details, customer info, etc.',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: UnderlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() => _notes = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Date Picker ----------
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
                      const SizedBox(height: 24),

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
                      
                      const SizedBox(height: 16),
                      
                      // ---------- IMPORT BUTTON (Admin Only - Remove after use) ----------
                       OutlinedButton.icon(
                         onPressed: _isImporting ? null : _importProductsFromJson,
                         icon: _isImporting
                             ? const SizedBox(
                                 width: 18,
                                 height: 18,
                                 child: CircularProgressIndicator(
                                   strokeWidth: 2,
                                 ),
                               )
                             : const Icon(Icons.file_upload),
                         label: Text(_isImporting ? 'Importing...' : 'Import Test Products (JSON)'),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.orange,
                           side: const BorderSide(color: Colors.orange),
                           padding: const EdgeInsets.symmetric(vertical: 12),
                         ),
                       ),
                      
                      const SizedBox(height: 8),
                      
                      // Info text
                      if (_products.isEmpty)
                        const Center(
                          child: Text(
                            'No products found. Use the button above to import test products.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
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