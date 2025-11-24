import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/auth_provider.dart';

// Import your main tab screens
import 'dashboard/dashboard_screen.dart';
import 'chat/chat_tab_screen.dart';
import 'chat/chat_screen.dart' as family_chat;
import 'focus/focus_mode_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'children/children_management_screen.dart';
import 'professional_tools/psychologist_dashboard_screen.dart';

class MainTabScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainTabScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _buildScreens();
  }

  void _buildScreens() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role ?? 'child';
    
    switch (userRole) {
      case 'parent':
        _screens = [
          const DashboardScreen(), // Parent dashboard with general overview
          const ChatTabScreen(), // Chat with children
          const FocusModeScreen(),
          const ChildrenManagementScreen(), // Children monitoring section
          const ProfileScreen(), // Removed Settings for parents to prioritize child management
        ];
        break;
      case 'psychologist':
        _screens = [
          const PsychologistDashboardScreen(), // Psychologist dashboard with scheduling and chat
          const ChatTabScreen(), // Chat with clients
          const FocusModeScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ];
        break;
      case 'child':
      default:
        _screens = [
          const DashboardScreen(), // Child dashboard
          const ChatTabScreen(), // Chat with parent
          const FocusModeScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ];
        break;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userModel?.role ?? 'child';
    
    return Scaffold(
      body: Column(
        children: [
          // Tiny settings bar for child users
          if (userRole == 'child')
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to settings screen (index 4 for child)
                      _onTabTapped(4);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Paramètres',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // AppBar (only show if not child or if child has no settings bar)
                if (userRole != 'child')
                  AppBar(
                    title: Text(
                      _getAppBarTitle(userRole, _currentIndex),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _showQuickSignOutDialog(context),
                        icon: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Se déconnecter',
                      ),
                      const SizedBox(width: 8),
                    ],
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                
                // PageView content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: _getBottomNavItems(userRole),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String userRole) {
    switch (userRole) {
      case 'parent':
        return [
          _buildBottomNavItem(Icons.dashboard, 'Tableau de bord'),
          _buildBottomNavItem(Icons.chat, 'Messages'),
          _buildBottomNavItem(Icons.timer, 'Focus'),
          _buildBottomNavItem(Icons.supervisor_account, 'Enfants'),
          _buildBottomNavItem(Icons.person, 'Profil'),
        ];
      case 'psychologist':
        return [
          _buildBottomNavItem(Icons.calendar_today, 'Agenda'),
          _buildBottomNavItem(Icons.chat, 'Messages'),
          _buildBottomNavItem(Icons.timer, 'Focus'),
          _buildBottomNavItem(Icons.person, 'Profil'),
          _buildBottomNavItem(Icons.settings, 'Paramètres'),
        ];
      case 'child':
      default:
        return [
          _buildBottomNavItem(Icons.dashboard, 'Tableau de bord'),
          _buildBottomNavItem(Icons.chat, 'Messages'),
          _buildBottomNavItem(Icons.timer, 'Concentration'),
          _buildBottomNavItem(Icons.person, 'Profil'),
          _buildBottomNavItem(Icons.settings, 'Paramètres'),
        ];
    }
  }

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24),
      label: label,
    );
  }

  String _getAppBarTitle(String userRole, int currentIndex) {
    final titles = {
      'parent': ['Tableau de bord', 'Messages', 'Focus', 'Enfants', 'Profil'],
      'psychologist': ['Tableau de bord', 'Patients', 'Agenda', 'Messages', 'Profil', 'Paramètres'],
      'child': ['Tableau de bord', 'Messages', 'Concentration', 'Profil', 'Paramètres'],
    };

    final roleTitles = titles[userRole] ?? titles['child']!;
    if (currentIndex < roleTitles.length) {
      return roleTitles[currentIndex];
    }
    return 'MindGuard FR';
  }

  void _showQuickSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter?',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ShadButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.signOut();
                context.go('/');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}
