/* what this file does:
  provides a form for manually updating product stock levels. This allows users to adjust 
  inventory counts for products that may have been sold or received outside of connected marketplaces,
   ensuring that the app's inventory data remains accurate and up-to-date. 
   The form can include fields for selecting a product, entering the new stock quantity, 
   and optionally providing a reason for the adjustment 
   (e.g., "Sold in-store", "Received new shipment", "Inventory correction"). 
   This functionality is essential for maintaining accurate inventory records and providing 
   reliable insights to the user.
 */

/*
  manual_stock_adjustment_form.dart

  What this file does:
  - Provides a form for manually updating product stock levels.
  - Allows users to adjust inventory counts for products sold or received outside of connected marketplaces.
  - Includes fields for selecting a product, entering stock adjustment quantity, and providing a reason.
  - Supports both increasing (add stock) and decreasing (remove stock) operations.
  - Saves stock adjustment records to Firestore and updates product stock levels.
  - Tracks adjustment history for auditing purposes.
  - Displays success/error messages.
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ManualStockAdjustmentForm extends StatefulWidget {
  const ManualStockAdjustmentForm({super.key});

  @override
  State<ManualStockAdjustmentForm> createState() => _ManualStockAdjustmentFormState();
}

class _ManualStockAdjustmentFormState extends State<ManualStockAdjustmentForm> {
  // -------------------- Form Key --------------------
  final _formKey = GlobalKey<FormState>();
  
  // -------------------- Data --------------------
  List<QueryDocumentSnapshot> _products = [];
  String? _selectedProductId;
  String? _selectedProductName;
  int _currentStock = 0;
  int _adjustmentQuantity = 0;
  String _adjustmentType = 'decrease'; // 'decrease' or 'increase'
  String _selectedReason = 'Sold in-store';
  String _customReason = '';
  bool _showCustomReasonField = false;
  String _notes = '';
  DateTime _adjustmentDate = DateTime.now();
  
  // -------------------- Controllers --------------------
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  // -------------------- UI State --------------------
  bool _isLoading = false;
  bool _isFetchingProducts = true;
  
  // -------------------- Lists --------------------
  final List<String> _adjustmentReasons = [
    'Sold in-store',
    'Received new shipment',
    'Inventory correction',
    'Damaged/Defective',
    'Return from customer',
    'Sample/Demo',
    'Lost/Theft',
    'Transferred to other location',
    'Other',
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _updateDateController();
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _customReasonController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  
  // -------------------- Firestore Methods --------------------
  
  /// Fetches products from Firestore 'unified_products' collection
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
  
  /// Called when a product is selected
  void _onProductSelected(String? productId) {
    if (productId == null) return;
    final productDoc = _products.firstWhere((doc) => doc.id == productId);
    setState(() {
      _selectedProductId = productId;
      _selectedProductName = productDoc['name'] ?? 'Unnamed';
      _currentStock = productDoc['totalStock'] ?? 0;
    });
  }
  
  /// Called when adjustment type changes
  void _onAdjustmentTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _adjustmentType = type;
    });
  }
  
  /// Called when reason changes
  void _onReasonChanged(String? reason) {
    if (reason == null) return;
    setState(() {
      _selectedReason = reason;
      _showCustomReasonField = (reason == 'Other');
      if (!_showCustomReasonField) {
        _customReason = '';
        _customReasonController.clear();
      }
    });
  }
  
  /// Updates product stock and saves adjustment record
  Future<void> _submitAdjustment() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProductId == null) {
      _showSnackBar('Please select a product');
      return;
    }
    
    // Calculate new stock
    int newStock;
    if (_adjustmentType == 'decrease') {
      newStock = _currentStock - _adjustmentQuantity;
      if (newStock < 0) {
        _showSnackBar('Cannot reduce stock below 0! Current stock: $_currentStock');
        return;
      }
    } else {
      newStock = _currentStock + _adjustmentQuantity;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get final reason
      final String finalReason = _showCustomReasonField && _customReason.isNotEmpty
          ? _customReason
          : _selectedReason;
      
      // Create stock adjustment record
      await firestore.collection('stock_adjustments').add({
        'productId': _selectedProductId,
        'productName': _selectedProductName,
        'adjustmentType': _adjustmentType, // 'increase' or 'decrease'
        'quantity': _adjustmentQuantity,
        'oldStock': _currentStock,
        'newStock': newStock,
        'reason': finalReason,
        'notes': _notes,
        'adjustmentDate': Timestamp.fromDate(_adjustmentDate),
        'createdAt': FieldValue.serverTimestamp(),
        'adjustedBy': 'Manual Entry', // Could be replaced with user ID if you have auth
      });
      
      // Update product stock
      final productRef = firestore.collection('unified_products').doc(_selectedProductId);
      await productRef.update({
        'totalStock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _showSnackBar(
        'Stock ${_adjustmentType == 'increase' ? 'increased' : 'decreased'} successfully!\n'
        'Stock changed: $_currentStock → $newStock',
        isError: false,
      );
      
      _resetForm();
      await _fetchProducts(); // Refresh product list to show updated stock
      
    } catch (e) {
      _showSnackBar('Error updating stock: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Resets all form fields
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedProductId = null;
      _selectedProductName = null;
      _currentStock = 0;
      _adjustmentQuantity = 0;
      _adjustmentType = 'decrease';
      _selectedReason = 'Sold in-store';
      _customReason = '';
      _showCustomReasonField = false;
      _notes = '';
      _adjustmentDate = DateTime.now();
      _quantityController.clear();
      _customReasonController.clear();
      _notesController.clear();
      _updateDateController();
    });
  }
  
  // -------------------- Helper Methods --------------------
  
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  void _updateDateController() {
    _dateController.text = DateFormat('dd.MM.yyyy').format(_adjustmentDate);
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _adjustmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _adjustmentDate) {
      setState(() {
        _adjustmentDate = picked;
        _updateDateController();
      });
    }
  }
  
  // -------------------- UI Build --------------------
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manual Stock Adjustment',
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
                      // ---------- Product Selection ----------
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
                                initialValue: _selectedProductId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Select Product *',
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
                              if (_selectedProductName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Current Stock: $_currentStock units',
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ---------- Adjustment Type Toggle ----------
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
                                'Adjustment Type *',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Decrease Stock'),
                                      selected: _adjustmentType == 'decrease',
                                      onSelected: (selected) {
                                        if (selected) {
                                          _onAdjustmentTypeChanged('decrease');
                                        }
                                      },
                                      selectedColor: Colors.redAccent,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      labelStyle: TextStyle(
                                        color: _adjustmentType == 'decrease' 
                                            ? Colors.white 
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Increase Stock'),
                                      selected: _adjustmentType == 'increase',
                                      onSelected: (selected) {
                                        if (selected) {
                                          _onAdjustmentTypeChanged('increase');
                                        }
                                      },
                                      selectedColor: Colors.green,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      labelStyle: TextStyle(
                                        color: _adjustmentType == 'increase' 
                                            ? Colors.white 
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ---------- Quantity ----------
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _adjustmentType == 'decrease' 
                                  ? 'Quantity to Remove *' 
                                  : 'Quantity to Add *',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Enter quantity',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: const UnderlineInputBorder(),
                              suffixText: 'units',
                              suffixStyle: const TextStyle(color: Colors.white54),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _adjustmentQuantity = parsed);
                              } else {
                                setState(() => _adjustmentQuantity = 0);
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
                              if (_adjustmentType == 'decrease' && _selectedProductId != null) {
                                if (qty > _currentStock) {
                                  return 'Cannot remove more than current stock ($_currentStock)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ---------- Reason Dropdown ----------
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
                                initialValue: _selectedReason,
                                items: _adjustmentReasons.map((reason) {
                                  return DropdownMenuItem<String>(
                                    value: reason,
                                    child: Text(
                                      reason,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onReasonChanged,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for Adjustment *',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                dropdownColor: const Color(0xFF283240),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) =>
                                    value == null ? 'Please select a reason' : null,
                              ),
                              if (_showCustomReasonField)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: TextFormField(
                                    controller: _customReasonController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Specify Reason',
                                      labelStyle: TextStyle(color: Colors.white70),
                                      hintText: 'e.g., Store transfer, Exhibition, etc.',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() => _customReason = value);
                                    },
                                    validator: (value) {
                                      if (_showCustomReasonField && (value == null || value.isEmpty)) {
                                        return 'Please specify the reason';
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
                              labelText: 'Additional Notes (Optional)',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'e.g., Invoice #, customer details, etc.',
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
                      
                      // ---------- Adjustment Date ----------
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
                              labelText: 'Adjustment Date',
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
                      
                      // ---------- Preview & Submit ----------
                      if (_adjustmentQuantity > 0 && _selectedProductName != null)
                        Card(
                          color: Colors.teal.withValues(alpha: 0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Adjustment Preview',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_selectedProductName\n'
                                  '${_adjustmentType == 'decrease' ? 'Remove' : 'Add'}: $_adjustmentQuantity units\n'
                                  'Current: $_currentStock → New: ${_adjustmentType == 'decrease' ? _currentStock - _adjustmentQuantity : _currentStock + _adjustmentQuantity}',
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // ---------- Submit Button ----------
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitAdjustment,
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
                        label: Text(_isLoading ? 'Updating Stock...' : 'Apply Adjustment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _adjustmentType == 'decrease' 
                              ? Colors.redAccent 
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info text
                      if (_products.isEmpty)
                        const Center(
                          child: Text(
                            'No products found. Please add products first.',
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