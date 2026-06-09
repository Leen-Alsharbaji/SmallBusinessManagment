// repositories/stock_repository.dart
import '../services/stock_api_service.dart';

class StockAdjustmentRepository {
  final StockAdjustmentApiService _apiService;

  StockAdjustmentRepository({required StockAdjustmentApiService apiService})
      : _apiService = apiService;

  Future<void> adjustStock({
    required String productId,
    required String productName,
    required String adjustmentType,
    required int quantity,
    required int oldStock,
    required int newStock,
    required String reason,
    required String notes,
    required DateTime adjustmentDate,
  }) async {
    final adjustmentData = {
      'productId': productId,
      'productName': productName,
      'adjustmentType': adjustmentType,
      'quantity': quantity,
      'oldStock': oldStock,
      'newStock': newStock,
      'reason': reason,
      'notes': notes,
      'adjustmentDate': adjustmentDate.toIso8601String(),
    };
    await _apiService.adjustStock(adjustmentData);
  }
}