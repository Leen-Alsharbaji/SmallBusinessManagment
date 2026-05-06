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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'Small Business Management Platform',
      initialRoute: '/sign-in', // Change this to '/sign-in' if you want to start at the sign-in screen.
      routes: {
        '/sign-in': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/product-stock': (context) => const ProductStockViewScreen(),
      },
      
    );
  }
}

