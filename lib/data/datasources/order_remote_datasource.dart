import '../../core/network/api_client.dart';
import '../models/order.dart';

/// Remote data source for manual order submission.
///
/// Delegates atomic stock decrement to the FastAPI OrderService rather than
/// writing directly to Firestore from the UI layer.
class OrderRemoteDataSource {
  OrderRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Submit a manual order via `POST /api/orders/manual`.
  Future<OrderResult> submitManualOrder(ManualOrder order) async {
    final data =
        await _client.post('/api/orders/manual', order.toJson());
    return OrderResult.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
