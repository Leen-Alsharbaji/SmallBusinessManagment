/*
  product_Card.dart

  What this file does:
  - Renders a single product card used in the product stock grid.
  - Lightweight, self-contained card with image, title, description, and
    an action button.

  How to modify:
  - Update the placeholder data with real product data by passing
    more parameters into the constructor.
  - Adjust padding, elevation, and sizes to match your design.
*/

import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final int index;

  const ProductCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black,
      color: const Color(0xBFF2F2F2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 20.0),
        // Slightly increased top padding (14) for better spacing from the
        // top of the grid (per your request).
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 25, 28, 68),
              radius: 50,
              child: const CircleAvatar(
                backgroundImage: NetworkImage("https://via.placeholder.com/100"),
                radius: 45,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Product Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Product details go here',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: null, // Add your onPressed logic
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}