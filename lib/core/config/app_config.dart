///Application-wide configuration constants.

/// Central API and feature configuration for the Smart Inventory Hub client.
class AppConfig {
  AppConfig._();

  /// FastAPI backend base URL (no trailing slash).
  static const String apiBaseUrl = 'http://127.0.0.1:8000';

  /// API prefix including versionless resource paths.
  static const String apiPrefix = '/api';

  static String get inventoryProductsUrl => '$apiBaseUrl$apiPrefix/inventory/products';
  static String get manualOrdersUrl => '$apiBaseUrl$apiPrefix/orders/manual';
  static String get stockAdjustUrl => '$apiBaseUrl$apiPrefix/inventory/stock/adjust';
  static String trendyolAuthUrl(String uid) =>
      '$apiBaseUrl$apiPrefix/auth/marketplace/trendyol/$uid';
}
