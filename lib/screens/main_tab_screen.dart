import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/auth_provider.dart';
import '../providers/parental_controls_provider.dart';
import '../providers/children_provider.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive/responsive_builder.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/responsive_text.dart';
import '../widgets/responsive/responsive_container.dart';
import '../services/screen_time_monitoring_service.dart';

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
  final ScreenTimeMonitoringService _screenTimeService = ScreenTimeMonitoringService();
  bool _isMonitoringInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _buildScreens();
    
    // Ensure initial index is within bounds
    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
      _pageController.animateToPage(0, duration: Duration.zero, curve: Curves.linear);
    }
    
    // Initialize screen time monitoring for child users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenTimeMonitoring();
    });
  }

  void _buildScreens() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role ?? 'child';
    
    print('Building screens for user role: $userRole');
    
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
    
    print('Screens list built with ${_screens.length} screens');
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Stop screen time monitoring when app is closed
    if (_isMonitoringInitialized) {
      _screenTimeService.stopMonitoring();
    }
    super.dispose();
  }

  // Initialize screen time monitoring for child users
  Future<void> _initializeScreenTimeMonitoring() async {
    if (_isMonitoringInitialized) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userRole = authProvider.userModel?.role ?? 'child';
      
      // Only start monitoring for child users
      if (userRole == 'child' && authProvider.userModel != null) {
        final childId = authProvider.userModel!.uid;
        
        // Get parent ID and parental controls
        final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
        await childrenProvider.getParentForChild(childId);
        
        final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context, listen: false);
        await parentalControlsProvider.loadScreenTimeLimit(childId);
        
        // Get parent ID (if linked)
        String? parentId;
        final parent = childrenProvider.parent;
        if (parent != null) {
          parentId = parent.uid;
        }
        
        if (parentId != null) {
          // Start screen time monitoring
          await _screenTimeService.startMonitoring(
            childId: childId,
            parentId: parentId,
            parentalControlsProvider: parentalControlsProvider,
          );
          
          _isMonitoringInitialized = true;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Suivi du temps d\'écran activé'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          
          print('Screen time monitoring started for child: $childId');
        }
      }
    } catch (e) {
      print('Error initializing screen time monitoring: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'activation du suivi du temps d\'écran'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    print('_onTabTapped called with index: $index, screens length: ${_screens.length}');
    
    // Ensure index is within bounds
    if (index < 0 || index >= _screens.length) {
      print('Invalid tab index: $index, screens length: ${_screens.length}');
      return;
    }
    
    print('Tab tapped successfully - changing to index $index');
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
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    print('MainTabScreen build: role=$userRole, deviceType=$deviceType, screenWidth=$screenWidth, screens=${_screens.length}');
    
    // For debugging: force mobile layout if screen width is small
    if (screenWidth < 800) {
      print('Forcing mobile layout due to screen width: $screenWidth');
      return _buildMobileLayout(context, userRole);
    }
    
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, userRole),
      tablet: _buildTabletLayout(context, userRole),
      desktop: _buildDesktopLayout(context, userRole),
    );
  }

  Widget _buildMobileLayout(BuildContext context, String userRole) {
    print('Building mobile layout for user role: $userRole, screens count: ${_screens.length}');
    
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
            child: _screens.isNotEmpty
                ? PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      print('PageView changed to index: $index');
                      // Ensure index is within bounds
                      if (index >= 0 && index < _screens.length) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                    children: _screens,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des écrans...'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(userRole),
    );
  }

  Widget _buildTabletLayout(BuildContext context, String userRole) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation for tablet
          if (userRole == 'child')
            Container(
              width: 60,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  // Settings button at top
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () => _onTabTapped(4),
                      icon: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Paramètres',
                    ),
                  ),
                  const Divider(),
                  // Navigation items
                  Expanded(
                    child: _buildSideNavigation(userRole),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 80,
              color: Theme.of(context).colorScheme.surface,
              child: _buildSideNavigation(userRole),
            ),
          
          // Main content
          Expanded(
            child: _screens.isNotEmpty
                ? PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      // Ensure index is within bounds
                      if (index >= 0 && index < _screens.length) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                    children: _screens,
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String userRole) {
    return Scaffold(
      body: Row(
        children: [
          // Persistent side navigation for desktop
          Container(
            width: ResponsiveHelper.isDesktop(context) ? 250 : 200,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // App header
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ResponsiveText(
                          'MindGuard',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (userRole == 'child')
                        IconButton(
                          onPressed: () => _onTabTapped(4),
                          icon: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Paramètres',
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // Navigation items
                Expanded(
                  child: _buildExpandedSideNavigation(userRole),
                ),
              ],
            ),
          ),
          
          // Main content with proper max width
          Expanded(
            child: ResponsiveContainer(
              child: _screens.isNotEmpty
                  ? PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        // Ensure index is within bounds
                        if (index >= 0 && index < _screens.length) {
                          setState(() {
                            _currentIndex = index;
                          });
                        }
                      },
                      children: _screens,
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(String userRole) {
    final items = _getBottomNavItems(userRole);
    print('Building bottom navigation for user role: $userRole, items count: ${items.length}, current index: $_currentIndex');
    
    return Container(
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
        onTap: (index) {
          print('Bottom navigation tapped: index $index');
          _onTabTapped(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: items,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildSideNavigation(String userRole) {
    final navItems = _getSideNavItems(userRole);
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        final isSelected = _currentIndex == index;
        
        return ListTile(
          leading: Icon(
            item['icon'],
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: null, // Remove text labels
          selected: isSelected,
          onTap: () => _onTabTapped(index),
        );
      },
    );
  }

  Widget _buildExpandedSideNavigation(String userRole) {
    final navItems = _getSideNavItems(userRole);
    
    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        final isSelected = _currentIndex == index;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              item['icon'],
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            title: null, // Remove text labels
            selected: isSelected,
            onTap: () => _onTabTapped(index),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSideNavItems(String userRole) {
    switch (userRole) {
      case 'parent':
        return [
          {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
          {'icon': Icons.chat, 'label': 'Messages'},
          {'icon': Icons.timer, 'label': 'Focus'},
          {'icon': Icons.supervisor_account, 'label': 'Enfants'},
          {'icon': Icons.person, 'label': 'Profil'},
        ];
      case 'psychologist':
        return [
          {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
          {'icon': Icons.people, 'label': 'Patients'},
          {'icon': Icons.calendar_today, 'label': 'Agenda'},
          {'icon': Icons.chat, 'label': 'Messages'},
          {'icon': Icons.person, 'label': 'Profil'},
          {'icon': Icons.settings, 'label': 'Paramètres'},
        ];
      case 'child':
      default:
        return [
          {'icon': Icons.dashboard, 'label': 'Tableau de bord'},
          {'icon': Icons.chat, 'label': 'Messages'},
          {'icon': Icons.timer, 'label': 'Concentration'},
          {'icon': Icons.person, 'label': 'Profil'},
          {'icon': Icons.settings, 'label': 'Paramètres'},
        ];
    }
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
          _buildBottomNavItem(Icons.dashboard, 'Tableau de bord'),
          _buildBottomNavItem(Icons.people, 'Patients'),
          _buildBottomNavItem(Icons.calendar_today, 'Agenda'),
          _buildBottomNavItem(Icons.chat, 'Messages'),
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
