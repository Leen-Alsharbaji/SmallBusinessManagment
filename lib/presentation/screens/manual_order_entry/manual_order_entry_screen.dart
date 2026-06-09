import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '/data/models/order.dart';
import '/data/models/product.dart';
import '/presentation/providers/order_provider.dart';
import '/presentation/providers/product_provider.dart';
import '/presentation/widgets/error_banner.dart';
import '/widgets/app_scaffold.dart';

/// Manual Order Entry screen — pure presentation layer.
///
/// Consumes [ProductProvider] and [OrderProvider] for all data operations.
/// Contains no HTTP calls or direct Firestore access.
class ManualOrderEntryScreen extends StatefulWidget {
  const ManualOrderEntryScreen({super.key});

  @override
  State<ManualOrderEntryScreen> createState() => _ManualOrderEntryScreenState();
}

class _ManualOrderEntryScreenState extends State<ManualOrderEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _otherPlatformController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProductId;
  int _quantity = 1;
  double _salesPrice = 0;
  String _currency = 'TRY';
  String _platform = 'WhatsApp';
  bool _showOtherPlatform = false;
  DateTime _saleDate = DateTime.now();

  static const _platforms = [
    'WhatsApp',
    'Instagram',
    'Trendyol',
    'Hepsiburada',
    'Other',
  ];

  static const _currencies = ['TRY', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _updateDateController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _otherPlatformController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd.MM.yyyy').format(_saleDate);
  }

  Product? get _selectedProduct {
    if (_selectedProductId == null) return null;
    return context.read<ProductProvider>().findById(_selectedProductId!);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final product = _selectedProduct;
    if (product == null) {
      _showSnack('Please select a product');
      return;
    }

    final platform = _showOtherPlatform
        ? _otherPlatformController.text.trim()
        : _platform;

    final order = ManualOrder(
      productId: product.id,
      productName: product.name,
      quantity: _quantity,
      salesPrice: _salesPrice,
      currency: _currency,
      platform: platform,
      notes: _notesController.text.trim(),
      saleDate: _saleDate,
    );

    final success = await context.read<OrderProvider>().submitOrder(order);
    if (!mounted) return;

    if (success) {
      _showSnack('Sale recorded successfully!', isError: false);
      await context.read<ProductProvider>().loadProducts();
      _resetForm();
    } else {
      final error = context.read<OrderProvider>().errorMessage;
      _showSnack(error ?? 'Failed to record sale');
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedProductId = null;
      _quantity = 1;
      _salesPrice = 0;
      _currency = 'TRY';
      _platform = 'WhatsApp';
      _showOtherPlatform = false;
      _saleDate = DateTime.now();
      _otherPlatformController.clear();
      _notesController.clear();
      _updateDateController();
    });
  }

  void _showSnack(String message, {bool isError = true}) {
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
      title: 'Manual Order Entry',
      body: Container(
        color: const Color(0xFF283240),
        child: Consumer2<ProductProvider, OrderProvider>(
          builder: (context, productState, orderState, _) {
            if (productState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (productState.hasError)
                      ErrorBanner(
                        message: productState.errorMessage!,
                        onRetry: productState.loadProducts,
                      ),
                    if (orderState.hasError)
                      ErrorBanner(
                        message: orderState.errorMessage!,
                        onDismiss: orderState.clearError,
                      ),
                    _sectionCard(
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProductId,
                        isExpanded: true,
                        decoration: _inputDecoration('Select Product'),
                        dropdownColor: const Color(0xFF283240),
                        style: const TextStyle(color: Colors.white),
                        items: productState.products
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.displayLabel),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedProductId = val),
                        validator: (v) =>
                            v == null ? 'Please select a product' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      TextFormField(
                        initialValue: '1',
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Quantity sold'),
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() => _quantity = parsed);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter quantity';
                          final qty = int.tryParse(v);
                          if (qty == null || qty < 1) {
                            return 'Must be a positive number';
                          }
                          final stock = _selectedProduct?.totalStock ?? 0;
                          if (qty > stock) {
                            return 'Not enough stock (max $stock)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      TextFormField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Sales Price'),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed >= 0) {
                            setState(() => _salesPrice = parsed);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter price';
                          if (double.tryParse(v) == null) return 'Invalid price';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: _inputDecoration('Currency'),
                        dropdownColor: const Color(0xFF283240),
                        style: const TextStyle(color: Colors.white),
                        items: _currencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _platform,
                            decoration: _inputDecoration('Sales Platform'),
                            dropdownColor: const Color(0xFF283240),
                            style: const TextStyle(color: Colors.white),
                            items: _platforms
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _platform = v!;
                              _showOtherPlatform = v == 'Other';
                            }),
                          ),
                          if (_showOtherPlatform) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _otherPlatformController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Specify Platform'),
                              validator: (v) {
                                if (_showOtherPlatform &&
                                    (v == null || v.isEmpty)) {
                                  return 'Specify the platform';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Notes (Optional)'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Sale Date').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today,
                              color: Colors.white70),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _saleDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _saleDate = picked;
                              _updateDateController();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: orderState.isSubmitting ? null : _submit,
                      icon: orderState.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        orderState.isSubmitting ? 'Saving...' : 'Record Sale',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const UnderlineInputBorder(),
      );

  Widget _sectionCard(Widget child) => Card(
        color: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}
