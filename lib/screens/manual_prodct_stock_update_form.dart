// manual_stock_adjustment_form.dart (optimized)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:small_business_managment/data/product_repository.dart';
import 'package:small_business_managment/data/stock_repository.dart';
import 'package:small_business_managment/services/product_api_service.dart';
import 'package:small_business_managment/services/stock_api_service.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ManualStockAdjustmentForm extends StatefulWidget {
  const ManualStockAdjustmentForm({super.key});

  @override
  State<ManualStockAdjustmentForm> createState() =>
      _ManualStockAdjustmentFormState();
}

class _ManualStockAdjustmentFormState extends State<ManualStockAdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  late ProductRepository _productRepository;
  late StockAdjustmentRepository _stockRepository;
  late Future<List<Map<String, dynamic>>> _productsFuture;

  // Cache for products - static to persist across rebuilds
  static List<Map<String, dynamic>> _cachedProducts = [];
  static bool _isCacheValid = false;
  static DateTime _lastFetch = DateTime.now();
  static const Duration _cacheDuration = Duration(minutes: 5);

  String? _selectedProductId;
  String? _selectedProductName;
  int _currentStock = 0;
  int _adjustmentQuantity = 0;
  String _adjustmentType = 'decrease';
  String _selectedReason = 'Sold in-store';
  String _customReason = '';
  bool _showCustomReasonField = false;
  String _notes = '';
  DateTime _adjustmentDate = DateTime.now();

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isSubmitting = false;
  bool _isRefreshing = false;

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
    final apiBaseUrl = 'http://127.0.0.1:8000 '; // Change to your server

    final productApi = ProductApiService(baseUrl: apiBaseUrl);
    _productRepository = ProductRepository(apiService: productApi);

    final stockApi = StockAdjustmentApiService(baseUrl: apiBaseUrl);
    _stockRepository = StockAdjustmentRepository(apiService: stockApi);

    _updateDateController();
    // Kick off product prefetch once to avoid repeated fetches on rebuild.
    _productsFuture = _fetchProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customReasonController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Check if cache is still valid
  bool _isCacheValidAndNotEmpty() {
    return _isCacheValid && 
           _cachedProducts.isNotEmpty && 
           DateTime.now().difference(_lastFetch) < _cacheDuration;
  }

  Future<List<Map<String, dynamic>>> _fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValidAndNotEmpty()) {
      return _cachedProducts;
    }

    try {
      final products = await _productRepository.fetchProducts();
      _cachedProducts = products;
      _isCacheValid = true;
      _lastFetch = DateTime.now();
      return products;
    } catch (e) {
      if (_cachedProducts.isNotEmpty) {
        return _cachedProducts;
      }
      rethrow;
    }
  }

  // Manual refresh
  Future<void> _refreshProducts() async {
    setState(() => _isRefreshing = true);
    try {
      _productsFuture = _fetchProducts(forceRefresh: true);
      await _productsFuture;
      if (_selectedProductId != null && 
          !_cachedProducts.any((p) => p['id'] == _selectedProductId)) {
        _selectedProductId = null;
        _selectedProductName = null;
        _currentStock = 0;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _showSnackBar('Failed to refresh: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _onProductSelected(String? productId) {
    if (productId == null) return;
    final product = _cachedProducts.firstWhere((p) => p['id'] == productId);
    setState(() {
      _selectedProductId = productId;
      _selectedProductName = product['name'] ?? 'Unnamed';
      _currentStock = product['totalStock'] ?? 0;
    });
  }

  void _onAdjustmentTypeChanged(String? type) {
    if (type == null) return;
    setState(() => _adjustmentType = type);
  }

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

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      _showSnackBar('Please select a product');
      return;
    }

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

    final String finalReason = _showCustomReasonField && _customReason.isNotEmpty
        ? _customReason
        : _selectedReason;

    setState(() => _isSubmitting = true);
    try {
      await _stockRepository.adjustStock(
        productId: _selectedProductId!,
        productName: _selectedProductName!,
        adjustmentType: _adjustmentType,
        quantity: _adjustmentQuantity,
        oldStock: _currentStock,
        newStock: newStock,
        reason: finalReason,
        notes: _notes,
        adjustmentDate: _adjustmentDate,
      );

      final productIndex = _cachedProducts.indexWhere((p) => p['id'] == _selectedProductId);
      if (productIndex != -1) {
        _cachedProducts[productIndex]['totalStock'] = newStock;
      }
      _currentStock = newStock;

      _showSnackBar(
        'Stock ${_adjustmentType == 'increase' ? 'increased' : 'decreased'} successfully!\n'
        'Stock changed: ${_adjustmentType == 'decrease' ? _currentStock + _adjustmentQuantity : _currentStock - _adjustmentQuantity} → $newStock',
        isError: false,
      );
      _resetForm();
    } catch (e) {
      _showSnackBar('Error updating stock: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manual Stock Adjustment',
      body: Container(
        color: const Color(0xFF283240),
        child: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white70, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load products: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}), // retrigger FutureBuilder
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No products found. Please add products first.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              }

              // Products loaded successfully
              final products = snapshot.data!;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Selection Dropdown
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedProductId,
                                isExpanded: true,
                                hint: const Text(
                                  'Select a product',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Select Product *',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                dropdownColor: const Color(0xFF283240),
                                style: const TextStyle(color: Colors.white),
                                items: products.map((product) {
                                  final name = product['name'] ?? 'Unnamed';
                                  final brand = product['brand'] ?? '';
                                  final stock = product['totalStock'] ?? 0;
                                  final displayText = brand.isNotEmpty
                                      ? '$name ($brand) - Stock: $stock'
                                      : '$name - Stock: $stock';
                                  return DropdownMenuItem<String>(
                                    value: product['id'],
                                    child: Text(displayText),
                                  );
                                }).toList(),
                                onChanged: _onProductSelected,
                                validator: (value) => value == null ? 'Please select a product' : null,
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

                      // Adjustment Type Toggle
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Adjustment Type *', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Decrease Stock'),
                                      selected: _adjustmentType == 'decrease',
                                      onSelected: (selected) {
                                        if (selected) _onAdjustmentTypeChanged('decrease');
                                      },
                                      selectedColor: Colors.redAccent,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      labelStyle: TextStyle(
                                        color: _adjustmentType == 'decrease' ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Increase Stock'),
                                      selected: _adjustmentType == 'increase',
                                      onSelected: (selected) {
                                        if (selected) _onAdjustmentTypeChanged('increase');
                                      },
                                      selectedColor: Colors.green,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      labelStyle: TextStyle(
                                        color: _adjustmentType == 'increase' ? Colors.white : Colors.white70,
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

                      // Quantity Field
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              setState(() => _adjustmentQuantity = (parsed != null && parsed > 0) ? parsed : 0);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter quantity';
                              final qty = int.tryParse(value);
                              if (qty == null || qty < 1) return 'Must be a positive number';
                              if (_adjustmentType == 'decrease' && _selectedProductId != null && qty > _currentStock) {
                                return 'Cannot remove more than current stock ($_currentStock)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason Dropdown
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedReason,
                                items: _adjustmentReasons.map((reason) {
                                  return DropdownMenuItem<String>(
                                    value: reason,
                                    child: Text(reason, style: const TextStyle(color: Colors.white)),
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
                                validator: (value) => value == null ? 'Please select a reason' : null,
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
                                    onChanged: (value) => setState(() => _customReason = value),
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

                      // Notes
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            onChanged: (value) => setState(() => _notes = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Adjustment Date
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Adjustment Date',
                              labelStyle: const TextStyle(color: Colors.white70),
                              suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                              border: const UnderlineInputBorder(),
                            ),
                            onTap: () => _selectDate(context),
                            validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Preview
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
                                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14),
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

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitAdjustment,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(_isSubmitting ? 'Updating Stock...' : 'Apply Adjustment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _adjustmentType == 'decrease' ? Colors.redAccent : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}