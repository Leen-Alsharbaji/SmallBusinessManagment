/*
  manual_product_entry_form.dart

  What this file does:
  - Provides a form to manually enter new product details.
  - Allows users to add products to inventory that may not be automatically imported.
  - Includes fields for product name, brand, category, description, price, stock, SKU, platforms, and image URL.
  - Saves the product to Firestore 'unified_products' collection.
  - Includes manual review flag and matching confidence for product verification.
  - Allows users to input custom platform when "Other" is selected from dropdown.
  - Displays success/error messages.
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ManualProductEntryForm extends StatefulWidget {
  const ManualProductEntryForm({super.key});

  @override
  State<ManualProductEntryForm> createState() => _ManualProductEntryFormState();
}

class _ManualProductEntryFormState extends State<ManualProductEntryForm> {
  // -------------------- Form Key --------------------
  final _formKey = GlobalKey<FormState>();
  
  // -------------------- Controllers --------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _totalStockController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _primaryImageUrlController = TextEditingController();
  final TextEditingController _customPlatformController = TextEditingController();
  
  // -------------------- Dropdown/Selection Values --------------------
  String _selectedPlatform = 'Trendyol';
  final List<String> _selectedPlatforms = [];
  bool _showCustomPlatformField = false;
  String _customPlatform = '';
  
  String _selectedMatchingConfidence = 'high';
  bool _isManuallyReviewed = true;
  
  // -------------------- Available Options --------------------
  final List<String> _availablePlatforms = [
    'Trendyol',
    'Amazon',
    'eBay',
    'Etsy',
    'Hepsiburada',
    'Shopify',
    'WooCommerce',
    'Other',
  ];
  
  final List<String> _confidenceLevels = ['high', 'medium', 'low'];
  
  final List<String> _categories = [
    'Hair Care',
    'Skincare',
    'Makeup',
    'Fragrance',
    'Body Care',
    'Men\'s Grooming',
    'Baby Care',
    'Natural Products',
    'Other',
  ];
  
  // -------------------- UI State --------------------
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _totalStockController.dispose();
    _skuController.dispose();
    _primaryImageUrlController.dispose();
    _customPlatformController.dispose();
    super.dispose();
  }

  // -------------------- Helper Methods --------------------
  
  /// Called when platform dropdown changes
  void _onPlatformChanged(String? platform) {
    if (platform == null) return;
    setState(() {
      _selectedPlatform = platform;
      _showCustomPlatformField = (platform == 'Other');
      if (!_showCustomPlatformField) {
        _customPlatform = '';
        _customPlatformController.clear();
      }
    });
  }
  
  /// Adds a platform to the selected platforms list
  void _addPlatform() {
    String platformToAdd;
    
    // Check if "Other" is selected and get custom platform name
    if (_selectedPlatform == 'Other') {
      if (_customPlatform.trim().isEmpty) {
        _showSnackBar('Please enter a custom platform name');
        return;
      }
      platformToAdd = _customPlatform.trim();
    } else {
      platformToAdd = _selectedPlatform;
    }
    
    // Check if platform already exists
    if (_selectedPlatforms.contains(platformToAdd)) {
      _showSnackBar('Platform already added');
      return;
    }
    
    setState(() {
      _selectedPlatforms.add(platformToAdd);
      // Reset the selection
      _selectedPlatform = 'Trendyol';
      _customPlatform = '';
      _showCustomPlatformField = false;
      _customPlatformController.clear();
    });
  }
  
  /// Removes a platform from the selected platforms list
  void _removePlatform(String platform) {
    setState(() {
      _selectedPlatforms.remove(platform);
    });
  }
  
  /// Shows snackbar message
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Submits the product to Firestore
  Future<void> _submitProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    // Validate platforms
    if (_selectedPlatforms.isEmpty) {
      _showSnackBar('Please add at least one sales platform');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Prepare product data
      final Map<String, dynamic> productData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'totalStock': int.parse(_totalStockController.text),
        'platforms': _selectedPlatforms,
        'isManuallyReviewed': _isManuallyReviewed,
        'matchingConfidence': _selectedMatchingConfidence,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if provided
      if (_skuController.text.trim().isNotEmpty) {
        productData['matchedProductid'] = _skuController.text.trim();
      }
      
      if (_primaryImageUrlController.text.trim().isNotEmpty) {
        productData['primaryImageUrl'] = _primaryImageUrlController.text.trim();
      }
      
      // Save to Firestore
      await firestore.collection('unified_products').add(productData);
      
      // Show success message
      _showSnackBar('Product added successfully!', isError: false);
      
      // Reset form
      _resetForm();
      
    } catch (e) {
      _showSnackBar('Error adding product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Resets all form fields
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _nameController.clear();
      _brandController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _totalStockController.clear();
      _skuController.clear();
      _primaryImageUrlController.clear();
      _selectedPlatforms.clear();
      _selectedPlatform = 'Trendyol';
      _selectedMatchingConfidence = 'high';
      _isManuallyReviewed = true;
      _showCustomPlatformField = false;
      _customPlatform = '';
      _customPlatformController.clear();
    });
  }

  // -------------------- UI Build --------------------
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manual Product Entry',
      body: Container(
        color: const Color(0xFF283240),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- Product Name ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'e.g., L\'Oreal Paris Elvive Shampoo',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Brand Name ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _brandController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Brand *',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'e.g., L\'Oreal, Nivea, Garnier',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter brand name';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Category Dropdown ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoryController.text.isEmpty ? null : _categoryController.text,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoryController.text = value ?? '';
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      dropdownColor: const Color(0xFF283240),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (_categoryController.text.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Description ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Product description, features, benefits...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product description';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Price & Stock Row ----------
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Price (USD) *',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '0.00',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: UnderlineInputBorder(),
                              prefixText: '\$ ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter valid price';
                              }
                              if (double.parse(value) < 0) {
                                return 'Price cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _totalStockController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Total Stock *',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: UnderlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter stock quantity';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null) {
                                return 'Please enter valid number';
                              }
                              if (stock < 0) {
                                return 'Stock cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // ---------- SKU (Optional) ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _skuController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'SKU / Product ID (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'e.g., LRL-009',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Platforms Selection ----------
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
                        const Text(
                          'Sales Platforms *',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        
                        // Selected platforms chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedPlatforms.map((platform) {
                            return Chip(
                              label: Text(platform),
                              backgroundColor: Colors.teal.withValues(alpha: 0.3),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removePlatform(platform),
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                        
                        if (_selectedPlatforms.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No platforms added yet',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        
                        // Platform dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPlatform,
                          items: _availablePlatforms.map((platform) {
                            return DropdownMenuItem<String>(
                              value: platform,
                              child: Text(platform, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: _onPlatformChanged,
                          decoration: const InputDecoration(
                            labelText: 'Select Platform to Add',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: const Color(0xFF283240),
                          style: const TextStyle(color: Colors.white),
                        ),
                        
                        // Custom platform input field (shown when "Other" is selected)
                        if (_showCustomPlatformField)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              controller: _customPlatformController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Custom Platform Name',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'e.g., Shopify, WooCommerce, MercadoLibre',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: UnderlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _customPlatform = value;
                                });
                              },
                              validator: (value) {
                                if (_showCustomPlatformField && (value == null || value.isEmpty)) {
                                  return 'Please enter a platform name';
                                }
                                return null;
                              },
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Add platform button
                        ElevatedButton.icon(
                          onPressed: _addPlatform,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Platform'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Image URL (Optional) ----------
                Card(
                  color: Colors.white.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _primaryImageUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Primary Image URL (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'https://...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ---------- Manual Review & Confidence ----------
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
                        // Manual Review Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Manually Reviewed',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Switch(
                              value: _isManuallyReviewed,
                              onChanged: (value) {
                                setState(() {
                                  _isManuallyReviewed = value;
                                });
                              },
                              activeThumbColor: Colors.teal,
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        
                        // Matching Confidence Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMatchingConfidence,
                          items: _confidenceLevels.map((level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(
                                level.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMatchingConfidence = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Matching Confidence',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFF283240),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ---------- Submit Button ----------
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitProduct,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Adding Product...' : 'Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info text
                const Center(
                  child: Text(
                    'All fields marked with * are required\nSelect "Other" from dropdown to add custom platforms',
                    style: TextStyle(
                      color: Colors.white54,
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