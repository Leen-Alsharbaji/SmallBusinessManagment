import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/api_exception.dart';

/// Low-level HTTP client shared by all remote data sources.
///
/// Parses structured FastAPI error payloads into [ApiException] so the
/// presentation layer can render user-friendly error states.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String _baseUrl;

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> get(String path) async {
    final response = await _http
        .get(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _http
        .put(
          Uri.parse('$_baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final response = await _http
        .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        ApiError.fromJson(decoded),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        ApiError(
          message: response.body.isNotEmpty
              ? response.body
              : 'Request failed with status ${response.statusCode}',
          code: 'http_error',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  void dispose() => _http.close();
}
