import '../../core/network/api_client.dart';
import '../models/product.dart';

/// Remote data source for inventory product endpoints.
///
/// Performs HTTP I/O only — no business rules or UI logic.
class ProductRemoteDataSource {
  ProductRemoteDataSource({ApiClient? client})
      : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Fetch all unified products from `GET /api/inventory/products`.
  Future<List<Product>> fetchProducts() async {
    final data = await _client.get('/api/inventory/products');
    final list = data as List<dynamic>;
    return list
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Create a product via `POST /api/inventory/products`.
  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _client.post('/api/inventory/products', payload);
    return Product.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
