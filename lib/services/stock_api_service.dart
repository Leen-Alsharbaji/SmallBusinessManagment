import 'dart:convert';
import 'package:http/http.dart' as http;
// removed unused import

class StockAdjustmentApiService {
  static StockAdjustmentApiService? _instance;
  final String baseUrl;
  final http.Client _httpClient;

  StockAdjustmentApiService._(this.baseUrl, http.Client? httpClient)
      : _httpClient = httpClient ?? http.Client();

  factory StockAdjustmentApiService({required String baseUrl, http.Client? httpClient}) {
    _instance ??= StockAdjustmentApiService._(baseUrl, httpClient);
    return _instance!;
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<void> adjustStock(Map<String, dynamic> adjustmentData) async {
    final uri = Uri.parse('$baseUrl/api/stock/adjust');
    final response = await _httpClient.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(adjustmentData),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      String error = 'Failed to adjust stock';
      try {
        final data = jsonDecode(response.body);
        error = data['detail'] ?? error;
      } catch (_) {}
      throw Exception(error);
    }
  }

  void dispose() {
    _httpClient.close();
  }
}