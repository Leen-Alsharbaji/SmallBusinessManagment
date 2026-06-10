// product_stock_view.dart
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
  late Future<List<Map<String, dynamic>>> _productsFuture;

  // Shared Static Cache Strategy matching the Manual Adjustment Form
  static List<Map<String, dynamic>> _cachedProducts = [];
  static bool _isCacheValid = false;
  static DateTime _lastFetch = DateTime.now();
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final api = ProductApiService(baseUrl: AppConfig.apiBaseUrl);
    _repo = ProductRepository(apiService: api);
    
    // Kick off product cache/fetch evaluation on startup
    _productsFuture = _fetchProducts();
  }

  // Check if cache is still active, full, and within time limits
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
      final rawProducts = await _repo.fetchProducts();
      final List<Map<String, dynamic>> sanitized = [];
      
      // Defensive sanitization pipeline
      for (var i = 0; i < rawProducts.length; i++) {
        final item = rawProducts[i];
        try {
          final Map<String, dynamic> m = Map<String, dynamic>.from(item);
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

      debugPrint('Loaded ${sanitized.length} products (sanitized from ${rawProducts.length})');
      
      _cachedProducts = sanitized;
      _isCacheValid = true;
      _lastFetch = DateTime.now();
      return sanitized;
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (_cachedProducts.isNotEmpty) {
        return _cachedProducts; // Fallback gracefully to old data if API drops
      }
      rethrow;
    }
  }

  // Handle pull-to-refresh directly tracking state
  Future<void> _refreshProducts() async {
    setState(() => _isRefreshing = true);
    try {
      _productsFuture = _fetchProducts(forceRefresh: true);
      await _productsFuture;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product Stock',
      body: Container(
        color: const Color(0xFF283240),
        child: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white70, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading products',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _productsFuture = _fetchProducts(forceRefresh: true);
                          });
                        },
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

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
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

              // Fixed: ResponsiveGridList is now the root scrollable widget.
              // Added verticalGridMargin: 24 to preserve your layout's top/bottom layout spacing.
              return ResponsiveGridList(
                horizontalGridMargin: 16,
                verticalGridMargin: 24,
                minItemWidth: 280,
                maxItemsPerRow: 4,
                children: products.map((productData) {
                  return ProductCard(
                    productId: productData['id']?.toString() ?? '',
                    name: productData['name'] ?? 'Unnamed Product',
                    brand: productData['brand'] ?? '',
                    price: (productData['price'] is num) ? (productData['price'] as num).toDouble() : 0.0,
                    stock: (productData['totalStock'] is int) ? productData['totalStock'] as int : 0,
                    imageUrl: productData['primaryImageUrl'] ?? '',
                    platforms: (productData['platforms'] is List) ? List<String>.from(productData['platforms']) : <String>[],
                    isManuallyReviewed: productData['isManuallyReviewed'] ?? false,
                    matchingConfidence: productData['matchingConfidence']?.toString() ?? 'N/A',
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}