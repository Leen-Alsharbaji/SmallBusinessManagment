/*
  product_stock_view.dart

  What this file does:
  - Provides a screen for viewing and managing product stock levels.
  - Allows users to add, update, and delete products from their inventory.

  How to modify:
  - Add functionality for adding new products.
  - Implement update and delete operations for existing products.
  - Enhance the UI with better styling and layout options.
*/
/*
  product_stock_view.dart

  What this file does:
  - Shows product cards in a responsive grid for inventory management.
  - Uses `AppScaffold` to provide a responsive side navigation menu.

  Changes made:
  - Added top padding to the grid so cards have breathing room from the
    top of the screen.
*/
import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:small_business_managment/widgets/product_Card.dart';
import 'package:small_business_managment/widgets/app_scaffold.dart';

class ProductStockViewScreen extends StatelessWidget {
  const ProductStockViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product Stock',
      body: Container(
        color: const Color(0xFF283240),
        padding: const EdgeInsets.only(top: 24.0), 
        child: ResponsiveGridList(
          horizontalGridMargin: 16,
          verticalGridMargin: 16,
          minItemWidth: 200,
          children: List.generate(
            20, 
            (index) => ProductCard(index: index),
          ),
        ),
      ),
    );
  }
}