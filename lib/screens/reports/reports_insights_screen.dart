import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_nav_bar.dart';

class ReportsInsightsScreen extends StatelessWidget {
  const ReportsInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports & Analyses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time period selector
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPeriodButton(context, 'Jour', true),
                      _buildPeriodButton(context, 'Semaine', false),
                      _buildPeriodButton(context, 'Mois', false),
                      _buildPeriodButton(context, 'Année', false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Screen time chart
              Text(
                'Temps d\'écran',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, _) {
                                switch (value.toInt()) {
                                  case 0: return Text('Lun');
                                  case 1: return Text('Mar');
                                  case 2: return Text('Mer');
                                  case 3: return Text('Jeu');
                                  case 4: return Text('Ven');
                                  case 5: return Text('Sam');
                                  case 6: return Text('Dim');
                                  default: return Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, _) {
                                return Text('${value.toInt()}h');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 4),
                              FlSpot(2, 3.5),
                              FlSpot(3, 5),
                              FlSpot(4, 4.5),
                              FlSpot(5, 6),
                              FlSpot(6, 4),
                            ],
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            //
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Mood trend chart
              Text(
                'Tendance de l\'humeur',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, _) {
                                switch (value.toInt()) {
                                  case 0: return Text('Lun');
                                  case 1: return Text('Mar');
                                  case 2: return Text('Mer');
                                  case 3: return Text('Jeu');
                                  case 4: return Text('Ven');
                                  case 5: return Text('Sam');
                                  case 6: return Text('Dim');
                                  default: return Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, _) {
                                return Text(value.toInt().toString());
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 4),
                              FlSpot(1, 3.5),
                              FlSpot(2, 4.2),
                              FlSpot(3, 2.8),
                              FlSpot(4, 4),
                              FlSpot(5, 4.5),
                              FlSpot(6, 3.8),
                            ],
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            //
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Weekly summary
              Text(
                'Résumé de la semaine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryItem(
                        context,
                        'Temps d\'écran moyen',
                        '3h 42m',
                        Icons.devices_other,
                        Theme.of(context).colorScheme.primary,
                      ),
                      const Divider(),
                      _buildSummaryItem(
                        context,
                        'Meilleure productivité',
                        'Mardi',
                        Icons.trending_up,
                        Theme.of(context).colorScheme.primary,
                      ),
                      const Divider(),
                      _buildSummaryItem(
                        context,
                        'Jour avec le plus d\'activité',
                        'Vendredi',
                        Icons.bar_chart,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Recommendations
              Text(
                'Recommandations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildRecommendation(
                        context,
                        'Essayez de réduire votre temps d\'écran de 30 minutes cette semaine',
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendation(
                        context,
                        'Passez plus de temps à l\'extérieur pour améliorer votre humeur',
                        Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendation(
                        context,
                        'Essayez la fonctionnalité de mode focus pour augmenter votre productivité',
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
  Widget _buildPeriodButton(BuildContext context, String label, bool isSelected) {
    return ShadButton(
      onPressed: () {
        // Handle period selection
      },

      size: ShadButtonSize.sm,
      child: Text(label),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}