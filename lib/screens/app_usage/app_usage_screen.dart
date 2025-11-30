import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/app_usage_provider.dart';
import '../../services/app_usage_platform_service.dart';
import '../../widgets/visual/custom_line_chart.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  Future<bool> _checkPermissions() async {
    return await AppUsagePlatformService.hasUsageStatsPermission();
  }

  Future<void> _requestPermissions() async {
    final granted = await AppUsagePlatformService.requestUsageStatsPermission();
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission accordée! Redémarrage du suivi...'),
          duration: Duration(seconds: 2),
        ),
      );
      // Reload data after permission is granted
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);
        appUsageProvider.loadAppUsageData(authProvider.userModel!.uid);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission refusée. Veuillez l\'activer manuellement dans les paramètres.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildDeviceTrackingCard(AppUsageProvider appUsageProvider) {
    return FutureBuilder<bool>(
      future: _checkPermissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  Text(
                    'Vérification des permissions...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        final hasPermission = snapshot.data ?? false;
        
        if (hasPermission) {
          return ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suivi des applications activé',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Les données d\'utilisation sont collectées en temps réel',
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
          );
        }

        return ShadCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Activer le suivi des applications',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pour voir les données d\'utilisation, vous devez autoriser l\'accès aux statistiques d\'utilisation de l\'appareil.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions rapides :',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionStep('1.', 'Appuyez sur le bouton "Activer" ci-dessous'),
                      _buildInstructionStep('2.', 'Autorisez l\'accès aux statistiques d\'utilisation'),
                      _buildInstructionStep('3.', 'Retournez ici pour voir les données'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: _requestPermissions,
                    child: const Text('Activer le suivi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionStep(String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    final appUsageProvider = Provider.of<AppUsageProvider>(context);
    
    // Load screen time data when user changes
    if (authProvider.isLoggedIn && authProvider.userModel != null) {
      if (screenTimeProvider.screenTimeData == null) {
        screenTimeProvider.loadScreenTimeData(authProvider.userModel!.uid);
      }
      if (appUsageProvider.appUsageData.isEmpty) {
        appUsageProvider.loadAppUsageData(authProvider.userModel!.uid);
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisation des applications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Device tracking permission card
            _buildDeviceTrackingCard(appUsageProvider),
            const SizedBox(height: 16),
            // Weekly chart
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temps d\'écran hebdomadaire',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (screenTimeProvider.screenTimeData != null)
                      CustomLineChart(
                        data: screenTimeProvider.getWeeklyScreenTime().asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value);
                        }).toList(),
                        title: 'Heures d\'écran',
                        xAxisLabels: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
                        maxY: 12,
                      )
                    else
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App usage list
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applications les plus utilisées',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedAppUsageList(appUsageProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedAppUsageList(AppUsageProvider appUsageProvider) {
    if (appUsageProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (appUsageProvider.lastError != null) {
      return ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Erreur de chargement des données',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                appUsageProvider.lastError!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.userModel != null) {
                    appUsageProvider.loadAppUsageData(authProvider.userModel!.uid);
                  }
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Get real app usage data from provider
    final topApps = appUsageProvider.getTopAppsByUsage(limit: 7);
    
    if (topApps.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.phone_android_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune donnée d\'utilisation disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          if (!appUsageProvider.hasNativeTracking)
            Text(
              'Activez le suivi des applications sur l\'appareil de votre enfant',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      );
    }
    
    // Color palette for apps
    final colors = [
      Colors.red, Colors.pink, Colors.green, Colors.black, 
      Colors.blue, Colors.purple, Colors.orange,
    ];
    
    return Column(
      children: topApps.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> app = entry.value;
        final totalSeconds = app['totalUsageSeconds'] as int;
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final dailyAvg = (totalSeconds / 7 / 60).round(); // Average per day
        
        String timeText = '';
        if (hours > 0) {
          timeText = '${hours}h ${minutes}m';
        } else {
          timeText = '${minutes}m';
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  app['appName'] as String? ?? 'App inconnue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Moy: ${dailyAvg}m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}