/*
  app.dart

  What this file does:
  - Declares `MyApp`, the root widget which configures named routes for
    the application. The routes are:
      - '/sign-in' -> SignInScreen
      - '/home'    -> HomeScreen
      - '/profile' -> ProfileScreen

  How to modify:
  - Add screens by registering new named routes in the `routes` map.
  - You can also change initialRoute to an auth-aware decision if you
    prefer to route users depending on their sign-in status.
*/

import 'package:flutter/material.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/Product_stock_view.dart';
import 'screens/manual_new_product_entry_form.dart';
import 'screens/dashboard_analytics.dart';
import 'screens/manual_sale_entry _form.dart';
import 'screens/manual_prodct_stock_update_form.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'Small Business Management Platform',
      initialRoute: '/sign-in', 
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/product-stock': (context) => const ProductStockViewScreen(),
        '/manual-sale-entry-form': (context) => const SalesEntryForm(),
      },
      
    );
  }
}

