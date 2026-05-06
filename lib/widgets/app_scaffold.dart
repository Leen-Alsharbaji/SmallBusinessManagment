/*
  app_scaffold.dart

  What this file does:
  - Provides a reusable responsive scaffold with a side navigation menu (drawer)
+  - Provides a reusable responsive scaffold with a side navigation menu (drawer)
    that behaves differently on large screens (desktop/tablet) vs small screens
    (phone).

  Behavior:
  - On wide screens (>= 800 logical pixels) the drawer is shown as a permanently
    visible side rail using a Drawer widget placed in a Row; on narrow screens
    it uses the platform-standard Drawer that's hidden by default and opened
    via an AppBar button.

  How to use:
  - Wrap your screen's main content with `AppScaffold(body: ...)`.
  - The AppScaffold exposes a menu button (hamburger) when the drawer is
    hidden and shows the drawer permanently when wide.
*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final Color backgroundColor;

  const AppScaffold({super.key, required this.body, this.title = '', this.backgroundColor = const Color(0xFF283240)});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  // Key used to open the drawer on small screens
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Width threshold to treat layout as "large" (desktop/laptop)
  static const double _kLargeScreenWidth = 800;

  @override
  Widget build(BuildContext context) {
  final isLarge = MediaQuery.of(context).size.width >= _kLargeScreenWidth;
  final user = FirebaseAuth.instance.currentUser;
  final isAuthenticated = user != null;

    // The navigation menu content
    Widget navList = ListView(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: const Color(0xFF283240)),
          child: const Text('Menu', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 20)),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        ListTile(
          leading: const Icon(Icons.inventory),
          title: const Text('Product Stock'),
          onTap: () => Navigator.pushReplacementNamed(context, '/product-stock'),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
        ),
      ],
    );

    // Large screens: show a permanent side menu
    if (isLarge) {
      // If not authenticated, do not show the navigation rail; just show
      // the content in a normal scaffold so the menu isn't available.
      if (!isAuthenticated) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: widget.body,
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFF283240),
        appBar: AppBar(title: Text(widget.title)),
        body: Row(
          children: [
            SizedBox(
              width: 260,
              child: Drawer(child: navList),
            ),
            Expanded(child: widget.body),
          ],
        ),
      );
    }

    // Small screens: if not authenticated, don't provide a drawer or menu
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: widget.body,
      );
    }

    // Authenticated small screens: standard drawer that opens/closes
    return Scaffold(
      backgroundColor: const Color(0xFF283240),
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(child: navList),
      body: widget.body,
    );
  }
}
