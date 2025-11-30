import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/app_usage_provider.dart';
import '../../providers/focus_session_provider.dart';
import '../../providers/children_provider.dart';
import 'debug_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Filter state variables
  String _selectedTimeRange = 'Aujourd\'hui';
  String _selectedDataType = 'Tout';
  String _selectedChild = 'Tous';
  bool _showFilters = false;
  
  // Filter options
  final List<String> _timeRangeOptions = [
    'Aujourd\'hui',
    'Cette semaine',
    'Ce mois',
    'Les 3 derniers mois'
  ];
  
  final List<String> _dataTypeOptions = [
    'Tout',
    'Temps d\'écran',
    'Humeur',
    'Applications',
    'Sessions de focus'
  ];

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
      final focusSessionProvider = Provider.of<FocusSessionProvider>(context, listen: false);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final userId = authProvider.userModel!.uid;
        final userRole = authProvider.userModel!.role;
        
        screenTimeProvider.loadScreenTimeData(userId);
        
        // Start real-time listening based on user role
        if (userRole == 'child') {
          await screenTimeProvider.startUsageRealtimeListening(userId);
        } else if (userRole == 'parent') {
          // Get children IDs and start listening
          await childrenProvider.loadChildrenForParent(userId);
          final children = childrenProvider.children;
          if (children.isNotEmpty) {
            final childrenIds = children.map((child) => child.childId).toList();
            await screenTimeProvider.startChildrenRealtimeListening(childrenIds);
          }
        }
        
        moodProvider.loadMoodEntries(userId);
        appUsageProvider.loadAppUsageData(userId, daysBack: 1); // Load today's data only
        focusSessionProvider.loadFocusSessions(userId);
        
        // Load linked people data based on user role
        if (userRole == 'parent') {
          childrenProvider.loadChildrenForParent(userId);
        } else if (userRole == 'child') {
          childrenProvider.getParentForChild(userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final appUsageProvider = Provider.of<AppUsageProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context);

    // Get actual screen time data
    final todayScreenTime = screenTimeProvider.getTodayScreenTime();
    final weeklyAverage = screenTimeProvider.getWeeklyAverage();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${authProvider.userModel?.name ?? 'Utilisateur'}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voici votre résumé',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      todayScreenTime,
                      'Écran aujourd\'hui',
                      Icons.devices_other,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '${moodProvider.averageMood.toStringAsFixed(1)}',
                      'Humeur moyenne',
                      Icons.sentiment_satisfied,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      appUsageProvider.appUsageData.length.toString(),
                      'Sessions aujourd\'hui',
                      Icons.local_fire_department,
                      Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      weeklyAverage.toString(),
                      'Temps productif',
                      Icons.check_circle,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Debug Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'État des données',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Screen Time Data', screenTimeProvider.screenTimeData != null ? 'Available' : 'Not Available'),
                      _buildInfoRow('Mood Entries', '${moodProvider.moodEntries.length}'),
                      _buildInfoRow('App Usage Sessions', '${appUsageProvider.appUsageData.length}'),
                      _buildInfoRow('Focus Sessions', '${focusSessionProvider.sessions.length}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.red.shade900,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DebugDashboardScreen()),
          );
        },
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    AuthProvider authProvider,
    ChildrenProvider childrenProvider,
  ) {
    return Container(); // Simplified for now
  }

  bool _shouldShowSection(String sectionType) {
    return _selectedDataType == 'Tout' || _selectedDataType == sectionType;
  }

  void _refreshData(AuthProvider authProvider) {
    if (authProvider.userModel == null) return;
    
    final userId = authProvider.userModel!.uid;
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context, listen: false);
    
    screenTimeProvider.loadScreenTimeData(userId);
    moodProvider.loadMoodEntries(userId);
    appUsageProvider.loadAppUsageData(userId, daysBack: 1);
    focusSessionProvider.loadFocusSessions(userId);
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: value == 'Not Available' ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop real-time listening when dashboard is disposed
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
    screenTimeProvider.stopRealtimeListening();
    super.dispose();
  }
}
