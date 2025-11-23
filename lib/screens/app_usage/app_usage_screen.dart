import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../widgets/visual/custom_line_chart.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    
    // Load screen time data when user changes
    if (authProvider.isLoggedIn && authProvider.userModel != null) {
      if (screenTimeProvider.screenTimeData == null) {
        screenTimeProvider.loadScreenTimeData(authProvider.userModel!.uid);
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
                    _buildDetailedAppUsageList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedAppUsageList() {
    // Sample app usage data
    final apps = [
      {'name': 'YouTube', 'time': '1h 23m', 'color': Colors.red, 'dailyAvg': '14m'},
      {'name': 'Instagram', 'time': '52m', 'color': Colors.pink, 'dailyAvg': '9m'},
      {'name': 'WhatsApp', 'time': '38m', 'color': Colors.green, 'dailyAvg': '6m'},
      {'name': 'TikTok', 'time': '27m', 'color': Colors.black, 'dailyAvg': '4m'},
      {'name': 'Twitter', 'time': '15m', 'color': Colors.blue, 'dailyAvg': '3m'},
      {'name': 'Discord', 'time': '12m', 'color': Colors.purple, 'dailyAvg': '2m'},
      {'name': 'Netflix', 'time': '8m', 'color': Colors.red, 'dailyAvg': '1m'},
    ];
    
    return Column(
      children: apps.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> app = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: app['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  app['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  app['time'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Moy: ${app['dailyAvg']}',
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