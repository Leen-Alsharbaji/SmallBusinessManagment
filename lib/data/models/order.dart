/// Manual order model for WhatsApp/Instagram sales entry.
class ManualOrder {
  const ManualOrder({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salesPrice,
    required this.currency,
    required this.platform,
    required this.saleDate,
    this.notes = '',
  });

  final String productId;
  final String productName;
  final int quantity;
  final double salesPrice;
  final String currency;
  final String platform;
  final String notes;
  final DateTime saleDate;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'salesPrice': salesPrice,
        'currency': currency,
        'platform': platform,
        'notes': notes,
        'saleDate': saleDate.toIso8601String(),
      };
}

/// Response returned after a successful atomic order submission.
class OrderResult {
  const OrderResult({
    required this.id,
    required this.transactionId,
    required this.productName,
    required this.quantity,
  });

  final String id;
  final String? transactionId;
  final String productName;
  final int quantity;

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      id: json['id'] as String? ?? '',
      transactionId: json['transactionId'] as String?,
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
