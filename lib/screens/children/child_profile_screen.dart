import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/mood_provider.dart';
import '../../models/child_model.dart';
import '../../widgets/visual/animated_background_visual.dart';
import '../../widgets/visual/mood_visualization.dart';
import '../../widgets/visual/glass_button.dart';

class ChildProfileScreen extends StatefulWidget {
  final String childId;

  const ChildProfileScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
      screenTimeProvider.loadScreenTimeData(widget.childId);

      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      moodProvider.loadMoodEntries(widget.childId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);

    // Find the child from the provider
    final child = childrenProvider.getChildById(widget.childId);

    if (child == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil de l\'enfant'),
        ),
        body: const Center(
          child: Text('Enfant non trouvé'),
        ),
      );
    }

    // Get screen time data
    final screenTimeToday = screenTimeProvider.getTodayScreenTime();

    // Get weekly screen time data
    final weeklyScreenTime = screenTimeProvider.getWeeklyScreenTime();
    final screenTimeData = weeklyScreenTime.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    // Get mood data for chart
    final weeklyMoodEntries = moodProvider.getWeeklyMoodEntries();
    final moodValues = List<double>.filled(7, 0.0);
    for (int i = 0; i < weeklyMoodEntries.length && i < 7; i++) {
      final entry = weeklyMoodEntries[i];
      moodValues[6 - i] = (entry['moodValue'] as int).toDouble(); // Fill from the end (most recent)
    }

    final moodData = moodValues.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(child.childName),
      ),
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Child summary card
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          child: Text(
                            child.childName.split(' ')[0][0],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.childName,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Connexion: ${child.isActive ? 'En ligne' : 'Hors ligne'}',
                                style: TextStyle(
                                  color: child.isActive ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                SizedBox(
                  height: 150,
                  child: Row(
                    children: [
                      Expanded(
                        child: ShadCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  screenTimeToday,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Écran aujourd\'hui',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '85%', // This would come from actual productivity data
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Productivité',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
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
                const SizedBox(height: 16),
                // Mood chart
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Évolution de l\'humeur',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, _) {
                                      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                                      final index = value.toInt();
                                      if (index >= 0 && index < days.length) {
                                        return Text(days[index]);
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, _) {
                                      return Text(value.toInt().toString());
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: 5,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: moodData,
                                  isCurved: true,
                                  color: Colors.amber,
                                  barWidth: 2,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      // Color the dots based on mood value
                                      Color dotColor;
                                      final moodValue = spot.y.toInt();
                                      switch (moodValue) {
                                        case 5:
                                          dotColor = Colors.green;
                                        case 4:
                                          dotColor = Colors.lightGreen;
                                        case 3:
                                          dotColor = Colors.amber;
                                        case 2:
                                          dotColor = Colors.orange;
                                        case 1:
                                          dotColor = Colors.red;
                                        default:
                                          dotColor = Theme.of(context).colorScheme.outline;
                                      }
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: dotColor,
                                        strokeWidth: 2,
                                        strokeColor: Theme.of(context).scaffoldBackgroundColor,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.amber.withOpacity(0.1),
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
                const SizedBox(height: 16),
                // Screen time chart
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
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, _) {
                                      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                                      final index = value.toInt();
                                      if (index >= 0 && index < days.length) {
                                        return Text(days[index]);
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, _) {
                                      return Text(value.toInt().toString());
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: 6,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: screenTimeData,
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                const SizedBox(height: 16),
                // App usage
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Applications les plus utilisées',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              children: [
                                ShadButton.link(
                                  onPressed: () {
                                    context.push('/network-activity/${widget.childId}');
                                  },
                                  child: const Text('Activité réseau'),
                                ),
                                const SizedBox(width: 8),
                                GlassButton(
                                  onPressed: () {
                                    // Navigate to detailed app usage
                                  },
                                  child: const Text('Voir tout'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Display top apps by usage from screen time provider
                        if (screenTimeProvider.screenTimeData == null ||
                            screenTimeProvider.getTopAppsByUsage().isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Aucune donnée d\'utilisation d\'application disponible',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...screenTimeProvider.getTopAppsByUsage().map((app) {
                            final appName = app['appName'] as String;
                            final minutes = app['minutes'] as int;
                            final hours = (minutes ~/ 60);
                            final remainingMinutes = minutes % 60;
                            final timeString = '${hours}h ${remainingMinutes}m';

                            // Generate a simple color based on the app name for consistent display
                            final colorIndex = appName.hashCode % 10;
                            final appColors = [
                              Colors.red, Colors.pink, Colors.purple,
                              Colors.deepPurple, Colors.indigo, Colors.blue,
                              Colors.lightBlue, Colors.teal, Colors.green,
                              Colors.amber
                            ];
                            final appColor = appColors[colorIndex];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: appColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      appName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    timeString,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Recent activities
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activités récentes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        // TODO: Replace with actual recent activities from Firestore
                        // For now, showing recent mood entries
                        if (moodProvider.moodEntries.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
                              'Aucune activité récente',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...moodProvider.moodEntries.take(4).map((activity) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  MoodVisualization(moodValue: activity['moodValue'], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Humeur enregistrée: ${activity['moodValue']}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          activity['timestamp'] != null
                                            ? (activity['timestamp'] as Timestamp).toDate().toString().split(' ')[0]
                                            : 'Date inconnue',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
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
}