import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/mood_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/mood_visualization.dart';
import '../../widgets/visual/custom_line_chart.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load mood entries when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      
      if (authProvider.userModel != null) {
        moodProvider.loadMoodEntries(authProvider.userModel!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    List<FlSpot> moodData = [];
    if (moodProvider.moodEntries.isNotEmpty) {
      // Get mood entries for the last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentEntries = moodProvider.moodEntries
          .where((entry) =>
              entry['timestamp'] != null &&
              (entry['timestamp'] as Timestamp).toDate().isAfter(sevenDaysAgo))
          .toList();

      // Map to chart data
      moodData = recentEntries.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> moodEntry = entry.value;
        return FlSpot(index.toDouble(), (moodEntry['moodValue'] as int).toDouble());
      }).toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de l\'humeur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mood statistics cards
            SizedBox(
              height: 120,
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
                              moodProvider.averageMood.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Moyenne',
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
                              moodProvider.moodEntries.length.toString(),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Entrées',
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
            SizedBox(
              height: 120,
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
                              moodProvider.positiveMoodCount.toString(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Positives',
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
                              moodProvider.negativeMoodCount.toString(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Négatives',
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
            const SizedBox(height: 24),
            // Mood trend chart
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
                          'Tendance hebdomadaire',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          moodProvider.getMoodTrend() == 'amélioration' ? 'En hausse' : 
                          moodProvider.getMoodTrend() == 'déclin' ? 'En baisse' : 'Stable',
                          style: TextStyle(
                            color: moodProvider.getMoodTrend() == 'amélioration' ? Colors.green :
                                   moodProvider.getMoodTrend() == 'déclin' ? Colors.red :
                                   Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (moodProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        height: 180,
                        child: moodData.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucune donnée disponible',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, _) {
                                          // Map index to day of week
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
                                  maxX: moodData.length > 0 ? moodData.length - 1 : 1,
                                  minY: 0,
                                  maxY: 5,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: moodData,
                                      isCurved: true,
                                      color: Theme.of(context).colorScheme.primary,
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
            const SizedBox(height: 24),
            // Mood entries list
            Expanded(
              child: ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dernières entrées',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (moodProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (moodProvider.moodEntries.isEmpty)
                        const Center(
                          child: Text(
                            'Aucune entrée d\'humeur enregistrée',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: moodProvider.moodEntries.length,
                            itemBuilder: (context, index) {
                              final entry = moodProvider.moodEntries[index];
                              final moodValue = entry['moodValue'] as int;
                              final timestamp = entry['timestamp'] as Timestamp?;
                              final notes = entry['notes'] as String?;
                              final date = timestamp?.toDate() ?? DateTime.now();

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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        MoodVisualization(moodValue: moodValue, size: 32),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_getMoodLabel(moodValue)} - ${_formatDate(date)}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (notes != null && notes.isNotEmpty)
                                                Text(
                                                  notes,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.outline,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
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
    );
  }
  
  String _getMoodLabel(int moodValue) {
    switch (moodValue) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Bien';
      case 3:
        return 'Normal';
      case 2:
        return 'Triste';
      case 1:
        return 'Épuisé';
      default:
        return 'Inconnu';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}