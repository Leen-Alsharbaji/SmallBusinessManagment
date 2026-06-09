import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository_impl.dart';

/// Manual order entry state management.
///
/// Handles form submission lifecycle and surfaces backend validation errors
/// (e.g. insufficient stock) to the UI without direct Firestore access.
class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderRepository? repository})
      : _repository = repository ?? OrderRepository();

  final OrderRepository _repository;

  bool _isSubmitting = false;
  String? _errorMessage;
  OrderResult? _lastResult;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  OrderResult? get lastResult => _lastResult;
  bool get hasError => _errorMessage != null;

  /// Submit a manual order; clears previous errors on retry.
  Future<bool> submitOrder(ManualOrder order) async {
    _isSubmitting = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      _lastResult = await _repository.submitManualOrder(order);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.error.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to record sale: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
