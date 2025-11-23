import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Determine user role to customize navigation
    String userRole = authProvider.userModel?.role ?? 'child';
    
    return NavigationBar(
      selectedIndex: _getCurrentIndex(context, userRole),
      onDestinationSelected: (int index) {
        String destinationPath = _getDestinationPath(index, userRole);
        GoRouter.of(context).go(destinationPath);
      },
      destinations: _getNavDestinations(userRole),
    );
  }

  int _getCurrentIndex(BuildContext context, String role) {
    String location = GoRouterState.of(context).uri.toString();

    switch (role) {
      case 'parent':
        if (location.startsWith('/dashboard')) return 0;
        if (location.startsWith('/children')) return 1;
        if (location.startsWith('/parental-controls')) return 2;
        if (location.startsWith('/profile')) return 3;
        if (location.startsWith('/settings')) return 4;
        break;
      case 'psychologist':
        if (location.startsWith('/dashboard')) return 0;
        if (location.startsWith('/sessions')) return 1;  // Using sessions for psychologist clients
        if (location.startsWith('/resources')) return 2;
        if (location.startsWith('/profile')) return 3;
        if (location.startsWith('/settings')) return 4;
        break;
      case 'child':
      default:
        if (location.startsWith('/dashboard')) return 0;
        if (location.startsWith('/chat')) return 1;
        if (location.startsWith('/focus')) return 2;
        if (location.startsWith('/profile')) return 3;
        if (location.startsWith('/settings')) return 4;
        break;
    }

    return 0; // Default to dashboard
  }

  String _getDestinationPath(int index, String role) {
    switch (role) {
      case 'parent':
        switch (index) {
          case 0: return '/dashboard';
          case 1: return '/children';
          case 2: return '/parental-controls';
          case 3: return '/profile';
          case 4: return '/settings';
          default: return '/dashboard';
        }
      case 'psychologist':
        switch (index) {
          case 0: return '/dashboard';
          case 1: return '/sessions';  // Using sessions for psychologist clients
          case 2: return '/resources';
          case 3: return '/profile';
          case 4: return '/settings';
          default: return '/dashboard';
        }
      case 'child':
      default:
        switch (index) {
          case 0: return '/dashboard';
          case 1: return '/chat';
          case 2: return '/focus';
          case 3: return '/profile';
          case 4: return '/settings';
          default: return '/dashboard';
        }
    }
  }

  List<NavigationDestination> _getNavDestinations(String role) {
    switch (role) {
      case 'parent':
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.supervisor_account),
            label: 'Enfants',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom),
            label: 'Contrôles',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ];
      case 'psychologist':
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Ressources',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ];
      case 'child':
      default:
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.do_not_disturb_on),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ];
    }
  }
}