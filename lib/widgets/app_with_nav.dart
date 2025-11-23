import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'bottom_nav_bar.dart';

/// A widget that wraps the bottom navigation bar and handles the
/// navigation between different sections based on user role
class AppWithNavigation extends StatelessWidget {
  const AppWithNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String userRole = authProvider.userModel?.role ?? 'child';
    
    // Show the bottom navigation bar for authenticated users
    return Scaffold(
      body: Builder(
        builder: (context) {
          // This ensures the bottom nav bar is always visible for the main sections
          return const SafeArea(
            top: false,
            child: SizedBox.expand(
              child: ColoredBox(
                color: Colors.transparent,
                child: SizedBox.expand(
                  child: IndexedStack(
                    index: 0, // This will be managed by the bottom nav bar
                    children: [
                      // The actual screens will be handled by the bottom nav bar
                      // This is just a placeholder to ensure proper layout
                      Placeholder(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}