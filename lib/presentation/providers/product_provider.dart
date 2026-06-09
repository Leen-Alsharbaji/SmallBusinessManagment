import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository_impl.dart';

/// Product catalog state — bridges UI widgets and [ProductRepository].
///
/// Manages loading/error/success states so presentation widgets remain pure.
class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  final ProductRepository _repository;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Fetch products from the backend inventory API.
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts();
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
