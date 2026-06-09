import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProductApiService {
  static ProductApiService? _instance;
  final String baseUrl;
  final http.Client _httpClient;

  List<Map<String, dynamic>>? _productsCache;

  ProductApiService._(this.baseUrl, http.Client? httpClient)
      : _httpClient = httpClient ?? http.Client();

  factory ProductApiService({required String baseUrl, http.Client? httpClient}) {
    _instance ??= ProductApiService._(baseUrl, httpClient);
    return _instance!;
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final uri = Uri.parse('$baseUrl/api/products/');
    final response = await _httpClient.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(productData),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product: ${response.statusCode}');
    }
  }

Future<List<Map<String, dynamic>>> getProducts() async {
  if (_productsCache != null) return _productsCache!;

  final uri = Uri.parse('$baseUrl/api/products/');
  final response = await _httpClient
      .get(uri, headers: _getHeaders())
      .timeout(const Duration(seconds: 20));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    print(' API response type: ${data.runtimeType}');
    if (data.isNotEmpty) {
      print(' First item keys: ${data[0].keys}');
    }
    _productsCache = data.map((e) => Map<String, dynamic>.from(e)).toList();
    return _productsCache!;
  } else {
    throw Exception('Failed to fetch products: ${response.statusCode}');
  }
}

  Future<Map<String, dynamic>> getProduct(String productId) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');
    final response = await _httpClient.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product: ${response.statusCode}');
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');
    final response = await _httpClient.put(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(productData),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
    if (_productsCache != null) {
      final idx = _productsCache!.indexWhere((p) => p['id']?.toString() == productId);
      if (idx >= 0) {
        _productsCache![idx] = {..._productsCache![idx], ...productData};
      }
    }
  }

  Future<void> deleteProduct(String productId) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId');
    final response = await _httpClient.delete(uri, headers: _getHeaders()).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }

  void dispose() {
    _httpClient.close();
  }

  void clearCache() {
    _productsCache = null;
  }
}