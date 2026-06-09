/// Unified catalog product model deserialized from FastAPI inventory endpoints.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.totalStock,
    required this.platforms,
    this.sku,
    this.primaryImageUrl,
    this.isManuallyReviewed = true,
    this.matchingConfidence = 'high',
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price;
  final int totalStock;
  final List<String> platforms;
  final String? sku;
  final String? primaryImageUrl;
  final bool isManuallyReviewed;
  final String matchingConfidence;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sku: json['sku'] as String?,
      primaryImageUrl: json['primaryImageUrl'] as String?,
      isManuallyReviewed: json['isManuallyReviewed'] as bool? ?? true,
      matchingConfidence: json['matchingConfidence'] as String? ?? 'high',
    );
  }

  String get displayLabel {
    if (brand.isNotEmpty) {
      return '$name ($brand) - Stock: $totalStock';
    }
    return '$name - Stock: $totalStock';
  }
}
