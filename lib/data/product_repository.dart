// repositories/product_repository.dart
import '../services/product_api_service.dart';


class ProductRepository {
  final ProductApiService _apiService;

  ProductRepository({required ProductApiService apiService}) : _apiService = apiService;

  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _apiService.createProduct(productData);
      return response['id'];
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      return await _apiService.getProducts();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Map<String, dynamic> prepareProductData({
    required String name,
    required String brand,
    required String category,
    required String description,
    required double price,
    required int totalStock,
    required List<String> platforms,
    required bool isManuallyReviewed,
    required String matchingConfidence,
    String? sku,
    String? primaryImageUrl,
  }) {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'description': description,
      'price': price,
      'totalStock': totalStock,
      'platforms': platforms,
      'isManuallyReviewed': isManuallyReviewed,
      'matchingConfidence': matchingConfidence,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      if (primaryImageUrl != null && primaryImageUrl.isNotEmpty) 'primaryImageUrl': primaryImageUrl,
    };
  }
}