import '../datasources/order_remote_datasource.dart';
import '../models/order.dart';

/// Repository for manual order operations.
class OrderRepository {
  OrderRepository({OrderRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? OrderRemoteDataSource();

  final OrderRemoteDataSource _dataSource;

  /// Atomically record a manual sale via the backend OrderService.
  Future<OrderResult> submitManualOrder(ManualOrder order) =>
      _dataSource.submitManualOrder(order);
}
