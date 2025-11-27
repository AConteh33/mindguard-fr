import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/app_usage_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/focus_session_provider.dart';
import '../../widgets/visual/glass_button.dart';
import '../../animations/custom_animations.dart';
import '../../widgets/visual/enhanced_stat_card.dart';
import '../../widgets/visual/mood_visualization.dart';
import '../../widgets/app_usage_widget.dart';
import '../../widgets/linked_people_widget.dart';
import '../../widgets/visual/animated_background_visual.dart';

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
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAnimations.slideInFromBottom(
                  child: Text(
                    'Bonjour, ${authProvider.userModel?.name ?? 'Utilisateur'}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                CustomAnimations.slideInFromBottom(
                  offset: 30,
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    'Voici votre résumé',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Section
                CustomAnimations.slideInFromBottom(
                  offset: 40,
                  duration: const Duration(milliseconds: 700),
                  child: _buildFilterSection(context, authProvider, childrenProvider),
                ),
                const SizedBox(height: 24),
                
                // Stats Cards
                CustomAnimations.staggeredList(
                  children: [
                    SizedBox(
                      height: 160,
                      child: Row(
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
                              weeklyAverage.toString(),
                              'Temps productif',
                              Icons.check_circle,
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: Row(
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
                              '${moodProvider.averageMood.toStringAsFixed(1)}',
                              'Score moyen',
                              Icons.sentiment_satisfied,
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Linked People Section
                if (authProvider.userModel?.role == 'parent' || authProvider.userModel?.role == 'child')
                  CustomAnimations.slideInFromBottom(
                    offset: 60,
                    duration: const Duration(milliseconds: 800),
                    child: LinkedPeopleWidget(
                      parent: childrenProvider.parent,
                      children: childrenProvider.children,
                      currentUserRole: authProvider.userModel?.role ?? '',
                      currentUserId: authProvider.userModel?.uid ?? '',
                    ),
                  ),
                if (authProvider.userModel?.role == 'parent' || authProvider.userModel?.role == 'child')
                  const SizedBox(height: 24),
                
                // App Usage Section (filtered by data type)
                if (_shouldShowSection('Applications'))
                  CustomAnimations.slideInFromBottom(
                    offset: 60,
                    duration: const Duration(milliseconds: 1000),
                    child: AppUsageWidget(
                      topApps: appUsageProvider.getTopAppsByUsage(limit: 5),
                      isLoading: appUsageProvider.isLoading,
                    ),
                  ),
                if (_shouldShowSection('Applications'))
                  const SizedBox(height: 24),
                
                // Mood visualization (filtered by data type)
                if (_shouldShowSection('Humeur'))
                  CustomAnimations.slideInFromBottom(
                    offset: 60,
                    duration: const Duration(milliseconds: 900),
                    child: ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Humeur récente',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                GlassButton(
                                  onPressed: () {
                                    context.push('/mood/history');
                                  },
                                  child: const Text('Voir tout'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Show up to 4 most recent mood entries
                                if (moodProvider.moodEntries.isNotEmpty) ...[
                                  for (int i = 0; i < moodProvider.moodEntries.length && i < 4; i++)
                                    Expanded(
                                      child: MoodVisualization(
                                        moodValue: moodProvider.moodEntries[i]['moodValue'],
                                      ),
                                    ),
                                ] else
                                  Expanded(
                                    child: Text(
                                      'Aucune donnée d\'humeur',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_shouldShowSection('Humeur'))
                  const SizedBox(height: 24),
                
                // Focus sessions (filtered by data type)
                if (_shouldShowSection('Sessions de focus'))
                  CustomAnimations.slideInFromBottom(
                    offset: 90,
                    duration: const Duration(milliseconds: 1200),
                    child: ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sessions de concentration',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                GlassButton(
                                  onPressed: () {
                                    context.push('/focus');
                                  },
                                  child: const Text('Voir tout'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Show loading state while focus sessions are loading
                            if (focusSessionProvider.isLoading)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else
                              // Get actual focus session statistics
                              Builder(
                                builder: (context) {
                                  final focusStats = focusSessionProvider.getFocusStats();
                                  final completionRate = ((focusStats['completionRate'] as double) * 100).round();
                                  final totalSessions = focusStats['totalSessions'] as int;
                                  
                                  // Show empty state if no sessions
                                  if (totalSessions == 0) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.timer_off,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Aucune session de concentration',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                          ),
                                          Text(
                                            'Commencez votre première session pour voir les statistiques',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.timer,
                                                size: 32,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                totalSessions.toString(),
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              Text(
                                                'Sessions totales',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.emoji_events,
                                                size: 32,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '$completionRate%',
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                              ),
                                              Text(
                                                'Taux de réussite',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_shouldShowSection('Sessions de focus'))
                  const SizedBox(height: 24),
                
                // Screen time trends (filtered by data type)
                if (_shouldShowSection('Temps d\'écran'))
                  CustomAnimations.slideInFromBottom(
                    offset: 120,
                    duration: const Duration(milliseconds: 1500),
                    child: ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Tendances du temps d\'écran',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                GlassButton(
                                  onPressed: () {
                                    context.push('/reports/insights');
                                  },
                                  child: const Text('Voir tout'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insert_chart,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Graphique des tendances',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Affiche les tendances sur 7 jours',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Motivational card
                CustomAnimations.slideInFromBottom(
                  offset: 150,
                  duration: const Duration(milliseconds: 1800),
                  child: ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prenez une pause',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Vous avez bien travaillé aujourd\'hui. Pensez à faire une pause régulière.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    AuthProvider authProvider,
    ChildrenProvider childrenProvider,
  ) {
    // Get child options for parent users
    List<String> childOptions = ['Tous'];
    if (authProvider.userModel?.role == 'parent') {
      childOptions.addAll(childrenProvider.children.map((child) => child.childName).toList());
    }

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ShadButton.ghost(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showFilters ? 'Masquer' : 'Afficher',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showFilters) ...[
              const SizedBox(height: 16),
              
              // Time Range Filter
              _buildFilterDropdown(
                'Période',
                _selectedTimeRange,
                _timeRangeOptions,
                (value) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                  _refreshData(authProvider);
                },
              ),
              
              const SizedBox(height: 12),
              
              // Data Type Filter
              _buildFilterDropdown(
                'Type de données',
                _selectedDataType,
                _dataTypeOptions,
                (value) {
                  setState(() {
                    _selectedDataType = value;
                  });
                },
              ),
              
              // Child Filter (only for parents)
              if (authProvider.userModel?.role == 'parent' && childOptions.length > 1) ...[
                const SizedBox(height: 12),
                _buildFilterDropdown(
                  'Enfant',
                  _selectedChild,
                  childOptions,
                  (value) {
                    setState(() {
                      _selectedChild = value;
                    });
                    _refreshData(authProvider);
                  },
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Reset Filters Button
              Row(
                children: [
                  ShadButton.outline(
                    onPressed: () {
                      setState(() {
                        _selectedTimeRange = 'Aujourd\'hui';
                        _selectedDataType = 'Tout';
                        _selectedChild = 'Tous';
                      });
                      _refreshData(authProvider);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  const Spacer(),
                  Text(
                    'Filtres actifs: ${_getActiveFilterCount()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(selectedValue) ? selectedValue : options.first,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedTimeRange != 'Aujourd\'hui') count++;
    if (_selectedDataType != 'Tout') count++;
    if (_selectedChild != 'Tous') count++;
    return count;
  }

  bool _shouldShowSection(String sectionType) {
    // Show section if "Tout" is selected or if the specific type matches
    return _selectedDataType == 'Tout' || _selectedDataType == sectionType;
  }

  void _refreshData(AuthProvider authProvider) {
    if (authProvider.userModel == null) return;
    
    final userId = authProvider.userModel!.uid;
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context, listen: false);
    
    // Calculate days back based on time range
    int daysBack = 1; // Default to today
    switch (_selectedTimeRange) {
      case 'Cette semaine':
        daysBack = 7;
        break;
      case 'Ce mois':
        daysBack = 30;
        break;
      case 'Les 3 derniers mois':
        daysBack = 90;
        break;
    }
    
    // Refresh data with new filters
    screenTimeProvider.loadScreenTimeData(userId);
    moodProvider.loadMoodEntries(userId);
    appUsageProvider.loadAppUsageData(userId, daysBack: daysBack);
    focusSessionProvider.loadFocusSessions(userId);
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return EnhancedStatCard(
      value: value,
      label: label,
      icon: icon,
      color: color,
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
