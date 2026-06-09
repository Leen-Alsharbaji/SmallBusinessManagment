import '../datasources/product_remote_datasource.dart';
import '../models/product.dart';

/// Repository bridging product data sources and state management layer.
///
/// Transforms raw JSON from [ProductRemoteDataSource] into typed [Product]
/// models and surfaces domain-level errors to providers.
class ProductRepository {
  ProductRepository({ProductRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProductRemoteDataSource();

  final ProductRemoteDataSource _dataSource;

  /// Load the full unified product catalog.
  Future<List<Product>> getProducts() => _dataSource.fetchProducts();

  /// Persist a new product and return the created record.
  Future<Product> addProduct(Map<String, dynamic> payload) =>
      _dataSource.createProduct(payload);
}
