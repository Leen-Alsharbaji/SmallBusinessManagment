// services/trendyol_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Model classes for type safety
class TrendyolConnectionStatus {
  final bool isConnected;
  final String? connectedAt;
  final String? sellerId;
  final String? errorMessage;
  
  TrendyolConnectionStatus({
    required this.isConnected,
    this.connectedAt,
    this.sellerId,
    this.errorMessage,
  });
  
  factory TrendyolConnectionStatus.fromJson(Map<String, dynamic> json) {
    return TrendyolConnectionStatus(
      isConnected: json['connected'] ?? false,
      connectedAt: json['connected_at'],
      sellerId: json['seller_id'],
      errorMessage: json['error'],
    );
  }
}

class TrendyolCredentials {
  final String uid;
  final String sellerId;
  final String apiPassword;
  
  TrendyolCredentials({
    required this.uid,
    required this.sellerId,
    required this.apiPassword,
  });
  
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'seller_id': sellerId,
    'api_password': apiPassword,
  };
}

class TrendyolApiException implements Exception {
  final String message;
  final int? statusCode;
  
  TrendyolApiException(this.message, {this.statusCode});
  
  @override
  String toString() => 'TrendyolApiException: $message (Status: $statusCode)';
}

// MAIN SERVICE CLASS
class TrendyolService {
  final String baseUrl;
  final http.Client _httpClient;
  
  TrendyolService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  Future<TrendyolConnectionStatus> checkConnection(String uid) async {
    if (kDebugMode) {
      print(' Checking Trendyol connection for user: $uid');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/auth/marketplace/trendyol/$uid');
      final response = await _httpClient
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      
      if (kDebugMode) {
        print(' Connection check response: ${response.statusCode}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TrendyolConnectionStatus.fromJson(data);
      } else if (response.statusCode == 404) {
        return TrendyolConnectionStatus(isConnected: false);
      } else {
        throw TrendyolApiException(
          'Failed to check connection',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw TrendyolApiException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw TrendyolApiException('Invalid response format: $e');
    } catch (e) {
      throw TrendyolApiException('Unexpected error: $e');
    }
  }
  
  Future<TrendyolConnectionStatus> connectAccount(TrendyolCredentials credentials) async {
    if (kDebugMode) {
      print(' Connecting Trendyol account for user: ${credentials.uid}');
    }
    
    if (credentials.sellerId.isEmpty) {
      throw TrendyolApiException('Seller ID cannot be empty');
    }
    if (credentials.apiPassword.isEmpty) {
      throw TrendyolApiException('API Password cannot be empty');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/auth/marketplace/trendyol');
      final response = await _httpClient
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(credentials.toJson()),
          )
          .timeout(const Duration(seconds: 30));
      
      if (kDebugMode) {
        print(' Connection response: ${response.statusCode}');
        print(' Response body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TrendyolConnectionStatus.fromJson(data);
      } else {
        String errorMessage = 'Connection failed';
        try {
          final error = jsonDecode(response.body);
          errorMessage = error['detail'] ?? error['message'] ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw TrendyolApiException(errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException  {
      throw TrendyolApiException('Cannot connect to server. Check your internet.');
    } catch (e) {
      if (e is TrendyolApiException) rethrow;
      throw TrendyolApiException('Unexpected error: $e');
    }
  }
  
  Future<void> disconnectAccount(String uid) async {
    if (kDebugMode) {
      print(' Disconnecting Trendyol account for user: $uid');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/auth/marketplace/trendyol/$uid');
      final response = await _httpClient
          .delete(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw TrendyolApiException(
          'Failed to disconnect',
          statusCode: response.statusCode,
        );
      }
      
      if (kDebugMode) {
        print(' Successfully disconnected Trendyol');
      }
    } catch (e) {
      throw TrendyolApiException('Failed to disconnect: $e');
    }
  }
  
  // 4. GET PRODUCTS FROM TRENDYOL (Example of another API call)
  Future<List<Map<String, dynamic>>> getProducts(String uid) async {
    if (kDebugMode) {
      print(' Fetching Trendyol products for user: $uid');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/trendyol/products/$uid');
      final response = await _httpClient
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      } else {
        throw TrendyolApiException(
          'Failed to fetch products',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw TrendyolApiException('Failed to fetch products: $e');
    }
  }
  
  // 5. GET ORDERS FROM TRENDYOL
  Future<List<Map<String, dynamic>>> getOrders(String uid, {DateTime? startDate, DateTime? endDate}) async {
    if (kDebugMode) {
      print(' Fetching Trendyol orders for user: $uid');
    }
    
    try {
      var uri = Uri.parse('$baseUrl/trendyol/orders/$uid');
      
      // Add query parameters if dates provided
      if (startDate != null || endDate != null) {
        final queryParams = <String, String>{};
        if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
        if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await _httpClient
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      } else {
        throw TrendyolApiException(
          'Failed to fetch orders',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw TrendyolApiException('Failed to fetch orders: $e');
    }
  }
  
  // 6. UPDATE PRODUCT STOCK
  Future<void> updateProductStock(String uid, String productId, int quantity) async {
    if (kDebugMode) {
      print('Updating stock for product $productId to $quantity');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/trendyol/products/$uid/$productId/stock');
      final response = await _httpClient
          .put(
            uri,
            headers: _getHeaders(),
            body: jsonEncode({'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw TrendyolApiException(
          'Failed to update stock',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw TrendyolApiException('Failed to update stock: $e');
    }
  }
  
  // 7. BATCH UPDATE - Multiple products at once
  Future<void> batchUpdateProducts(String uid, List<Map<String, dynamic>> updates) async {
    if (kDebugMode) {
      print(' Batch updating ${updates.length} products');
    }
    
    try {
      final uri = Uri.parse('$baseUrl/trendyol/products/$uid/batch');
      final response = await _httpClient
          .put(
            uri,
            headers: _getHeaders(),
            body: jsonEncode({'updates': updates}),
          )
          .timeout(const Duration(seconds: 60)); // Longer timeout for batch ops
      
      if (response.statusCode != 200) {
        throw TrendyolApiException(
          'Batch update failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw TrendyolApiException('Batch update failed: $e');
    }
  }
  
  // Dispose method to close HTTP client
  void dispose() {
    _httpClient.close();
  }
}