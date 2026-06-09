import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../../data/models/product.dart';
import '../../../widgets/app_scaffold.dart';
import '../../widgets/error_banner.dart';

/// Dashboard presentation screen — consumes [ProductProvider] state only.
///

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      body: Consumer<ProductProvider>(
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: state.loadProducts,
                ),
              ),
            );
          }

          final products = state.products;
          final totalStock =
              products.fold<int>(0, (sum, p) => sum + p.totalStock);
          final lowStock = products.where((p) => p.totalStock < 5).length;

          return Container(
            color: const Color(0xFF283240),
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _MetricCard(
                  title: 'Total Products',
                  value: '${products.length}',
                  icon: Icons.inventory_2,
                  color: Colors.teal,
                ),
                _MetricCard(
                  title: 'Total Stock Units',
                  value: '$totalStock',
                  icon: Icons.warehouse,
                  color: Colors.blue,
                ),
                _MetricCard(
                  title: 'Low Stock Items',
                  value: '$lowStock',
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                ),
                _MetricCard(
                  title: 'Platforms',
                  value: '${_uniquePlatforms(products).length}',
                  icon: Icons.store,
                  color: Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Set<String> _uniquePlatforms(List<Product> products) {
    final platforms = <String>{};
    for (final p in products) {
      platforms.addAll(p.platforms);
    }
    return platforms;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
