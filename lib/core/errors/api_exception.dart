/// Typed API error returned by the FastAPI global exception handlers.
class ApiError {
  const ApiError({
    required this.message,
    required this.code,
    this.details,
  });

  final String message;
  final String code;
  final dynamic details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>? ?? json;
    return ApiError(
      message: error['message'] as String? ?? 'Unknown error',
      code: error['code'] as String? ?? 'unknown',
      details: error['details'],
    );
  }

  @override
  String toString() => '$code: $message';
}

/// Exception thrown by data sources when HTTP calls fail.
class ApiException implements Exception {
  ApiException(this.error, {this.statusCode});

  final ApiError error;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): ${error.message}';
}
