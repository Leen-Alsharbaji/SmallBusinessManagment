/*
  product_stock_view.dart
  - Displays products in a responsive grid
 
*/

import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:small_business_managment/widgets/product_card.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';
import 'package:small_business_managment/services/product_api_service.dart';
import 'package:small_business_managment/data/product_repository.dart';
import 'package:small_business_managment/core/config/app_config.dart';

class ProductStockViewScreen extends StatefulWidget {
  const ProductStockViewScreen({super.key});

  @override
  State<ProductStockViewScreen> createState() => _ProductStockViewScreenState();
}

class _ProductStockViewScreenState extends State<ProductStockViewScreen> {
  late ProductRepository _repo;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // use centralized app config (remove accidental trailing space)
  final String _apiBaseUrl = AppConfig.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    final api = ProductApiService(baseUrl: _apiBaseUrl);
    _repo = ProductRepository(apiService: api);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _repo.fetchProducts();
      // Defensive sanitization: coerce each element into Map<String,dynamic>
      final List<Map<String, dynamic>> sanitized = [];
      for (var i = 0; i < products.length; i++) {
        final item = products[i];
        try {
          final Map<String, dynamic> m = Map<String, dynamic>.from(item);
          // coerce common fields to safe defaults to avoid null exceptions in widgets
          m['id'] = m['id']?.toString() ?? '';
          m['name'] = m['name'] ?? 'Unnamed Product';
          m['brand'] = m['brand'] ?? '';
          if (m['price'] is num) {
            m['price'] = (m['price'] as num).toDouble();
          } else {
            m['price'] = 0.0;
          }
          if (m['totalStock'] is num) {
            m['totalStock'] = (m['totalStock'] as num).toInt();
          } else {
            m['totalStock'] = 0;
          }
          if (m['platforms'] is List) {
            try {
              m['platforms'] = List<String>.from(m['platforms']);
            } catch (_) {
              m['platforms'] = <String>[];
            }
          } else {
            m['platforms'] = <String>[];
          }
          m['primaryImageUrl'] = m['primaryImageUrl'] ?? '';
          m['isManuallyReviewed'] = m['isManuallyReviewed'] ?? false;
          m['matchingConfidence'] = m['matchingConfidence']?.toString() ?? 'N/A';
          sanitized.add(m);
        } catch (e) {
          debugPrint('Failed to coerce product at index $i: $e');
        }
      }
      print('Loaded ${sanitized.length} products (sanitized from ${products.length})');  // Debug log
      if (mounted) {
        setState(() {
          _products = sanitized;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' Error loading products: $e');  // Debug log
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product Stock',
      body: Container(
        color: const Color(0xFF283240),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading products',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 60),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add products using the manual entry form',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/manual-product-entry'),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Products exist – show grid
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
        children: [
          ResponsiveGridList(
            horizontalGridMargin: 16,
            verticalGridMargin: 16,
            minItemWidth: 280,
            maxItemsPerRow: 4,
            children: _products.map((productData) {
              return ProductCard(
                productId: productData['id']?.toString() ?? '',
                name: productData['name'] ?? 'Unnamed Product',
                brand: productData['brand'] ?? '',
                price: (productData['price'] is num) ? (productData['price'] as num).toDouble() : 0.0,
                stock: (productData['totalStock'] is int) ? productData['totalStock'] as int : (productData['totalStock'] is num ? (productData['totalStock'] as num).toInt() : 0),
                imageUrl: productData['primaryImageUrl'] ?? '',
                platforms: (productData['platforms'] is List) ? List<String>.from(productData['platforms']) : <String>[],
                isManuallyReviewed: productData['isManuallyReviewed'] ?? false,
                matchingConfidence: productData['matchingConfidence']?.toString() ?? 'N/A',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}