/*
  product_card.dart

  What this file does:
  - Renders a single product card used in the product stock grid.
  - Displays real product data from Firestore including:
    - Product name and unified ID
    - Brand, price, and stock count
    - Primary image (with fallback)
    - Platform availability badges
  - Includes edit and delete functionality for product management.
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final String brand;
  final double price;
  final int stock;
  final String imageUrl;
  final List<String> platforms;
  final bool isManuallyReviewed;
  final String matchingConfidence;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.platforms,
    required this.isManuallyReviewed,
    required this.matchingConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
  elevation: 8,
  // use withOpacity instead of non-existent withValues
  shadowColor: Colors.black.withOpacity(0.3),
  color: const Color(0xBFF2F2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.inventory_2,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
          
          // Product Info Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Unified Product ID (small font)
                Text(
                  'ID: $productId',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Brand (if available)
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          brand,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Price and Stock Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    // Stock with color coding
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStockColor(stock).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: _getStockColor(stock),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$stock left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStockColor(stock),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Platform Badges
                if (platforms.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: platforms.take(3).map((platform) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                          decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          platform,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (platforms.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${platforms.length - 3} more',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
                
                const SizedBox(height: 12),
                
                // Review Status Indicator
                Row(
                  children: [
                    Icon(
                      isManuallyReviewed ? Icons.verified : Icons.pending,
                      size: 12,
                      color: isManuallyReviewed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isManuallyReviewed ? 'Verified' : 'Auto-matched',
                      style: TextStyle(
                        fontSize: 10,
                        color: isManuallyReviewed ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (!isManuallyReviewed) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($matchingConfidence)',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(context),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Quick Stock Update Button (when stock is low)
                if (stock < 10 && stock > 0) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _quickAddStock(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Restock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get stock color based on quantity
  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    if (stock < 50) return Colors.blue;
    return Colors.green;
  }
  
  // Show edit dialog for product
  void _showEditDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController brandController = TextEditingController(text: brand);
    final TextEditingController priceController = TextEditingController(text: price.toString());
    final TextEditingController stockController = TextEditingController(text: stock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                await firestore.collection('unified_products').doc(productId).update({
                  'name': nameController.text,
                  'brand': brandController.text,
                  'price': double.tryParse(priceController.text) ?? price,
                  'totalStock': int.tryParse(stockController.text) ?? stock,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Confirm delete action
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "$name"?\n\nThis action cannot be undone and will remove all associated sales records.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                
                // Optional: Check if product has sales before deleting
                final salesSnapshot = await firestore
                    .collection('orders')
                    .where('unifiedProductId', isEqualTo: productId)
                    .limit(1)
                    .get();
                
                if (salesSnapshot.docs.isNotEmpty && context.mounted) {
                  // Confirm again if there are sales
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Warning'),
                      content: Text(
                        'This product has ${salesSnapshot.docs.length}+ sales records. '
                        'Deleting it will remove all associated data. '
                        'Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Yes, Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmDelete != true) return;
                }
                
                // Delete the product
                await firestore.collection('unified_products').doc(productId).delete();
                
                if (context.mounted) {
                  Navigator.pop(context); // Close the confirm dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // Quick add stock for low inventory
  void _quickAddStock(BuildContext context) {
    final TextEditingController quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: $stock'),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to add',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final int addQuantity = int.tryParse(quantityController.text) ?? 0;
              if (addQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }
              
              try {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                await firestore.collection('unified_products').doc(productId).update({
                  'totalStock': FieldValue.increment(addQuantity),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $addQuantity items to stock'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}