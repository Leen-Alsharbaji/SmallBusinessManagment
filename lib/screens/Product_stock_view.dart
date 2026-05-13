/*
  product_stock_view.dart

  What this file does:
  - Provides a screen for viewing and managing product stock levels.
  - Fetches products from the unified_products collection in Firestore.
  - Displays products in a responsive grid with real data.
  - Shows product image, name, stock count, brand, and price.
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:small_business_managment/widgets/product_card.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ProductStockViewScreen extends StatelessWidget {
  const ProductStockViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product Stock',
      body: Container(
        color: const Color(0xFF283240),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('unified_products')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            // Handle error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading products: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh by rebuilding the stream
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Handle empty state
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white70,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No products found',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add products using the sales entry form or import them',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to sales entry form to add products
                        Navigator.pushNamed(context, '/sales-entry');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Display products in grid
            final products = snapshot.data!.docs;
            
            return Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: ResponsiveGridList(
                horizontalGridMargin: 16,
                verticalGridMargin: 16,
                minItemWidth: 280,
                maxItemsPerRow: 4,
                children: products.map((doc) {
                  final productData = doc.data() as Map<String, dynamic>;
                  return ProductCard(
                    productId: doc.id,
                    name: productData['name'] ?? 'Unnamed Product',
                    brand: productData['brand'] ?? '',
                    price: (productData['price'] ?? 0).toDouble(),
                    stock: productData['totalStock'] ?? 0,
                    imageUrl: productData['primaryImageUrl'] ?? '',
                    platforms: List<String>.from(productData['platforms'] ?? []),
                    isManuallyReviewed: productData['isManuallyReviewed'] ?? false,
                    matchingConfidence: productData['matchingConfidence'] ?? 'N/A',
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}