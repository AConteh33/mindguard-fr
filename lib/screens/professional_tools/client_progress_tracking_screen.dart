import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';

class ClientProgressTrackingScreen extends StatefulWidget {
  const ClientProgressTrackingScreen({super.key});

  @override
  State<ClientProgressTrackingScreen> createState() =>
      _ClientProgressTrackingScreenState();
}

class _ClientProgressTrackingScreenState
    extends State<ClientProgressTrackingScreen> {
  String _selectedPeriod = '7j';
  final List<String> _periods = ['7j', '30j', '90j', '1an'];

  @override
  void initState() {
    super.initState();
    // Load clients when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);

      if (authProvider.userModel != null && authProvider.userModel!.role == 'psychologist') {
        clientProvider.loadClientsForPsychologist(authProvider.userModel!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clientProvider = Provider.of<ClientProvider>(context);

    // Calculate overall statistics from loaded clients
    double totalEngagement = 0;
    double totalProgress = 0;
    double totalMood = 0;
    int validClients = 0;

    for (final client in clientProvider.clients) {
      final engagement = client['engagement'] as double? ?? 0;
      final progress = client['progress'] as double? ?? 0;
      final mood = client['averageMood'] as double? ?? 0;

      if (engagement > 0) {
        totalEngagement += engagement;
        validClients++;
      }
      if (progress > 0) totalProgress += progress;
      if (mood > 0) totalMood += mood;
    }

    final avgEngagement = validClients > 0 ? totalEngagement / validClients : 0;
    final avgProgress = validClients > 0 ? totalProgress / validClients : 0;
    final avgMood = validClients > 0 ? totalMood / validClients : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des progrès des clients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period selector
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  bool isSelected = _selectedPeriod == period;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: isSelected
                        ? ShadButton(
                            onPressed: () {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                            size: ShadButtonSize.sm,
                            child: Text(period),
                          )
                        : ShadButton.outline(
                            onPressed: () {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                            size: ShadButtonSize.sm,
                            child: Text(period),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Overall statistics
            clientProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${(avgEngagement * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Engagement moyen',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${(avgProgress * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Progression moyenne',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  avgMood > 0 ? avgMood.toStringAsFixed(1) : 'N/A',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                Text(
                                  'Humeur moyenne',
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
            const SizedBox(height: 24),

            // Client list with progress
            Expanded(
              child: clientProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: clientProvider.clients.length,
                      itemBuilder: (context, index) {
                        final client = clientProvider.clients[index];
                        return _buildClientCard(client);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final engagement = client['engagement'] as double? ?? 0;
    final progress = client['progress'] as double? ?? 0;
    final moodTrend = client['moodTrend'] as List<double>? ?? [];
    final lastSession = client['lastSession'] != null
        ? (client['lastSession'] as Timestamp).toDate()
        : DateTime.now();
    final averageMood = client['averageMood'] as double? ?? 0;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    (client['name'] as String?)?.split(' ')[0][0] ?? 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name'] ?? 'Client inconnu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Dernière session: ${_formatDate(lastSession)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                ShadButton.outline(
                  onPressed: () {
                    // Navigate to client details
                    context.push('/clients/${client['id']}');
                  },
                  size: ShadButtonSize.sm,
                  child: const Text('Détails'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        color: _getProgressColor(progress),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress > 0 ? '${(progress * 100).toInt()}%' : 'N/A',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engagement',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: engagement,
                        backgroundColor:
                            Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        color: _getProgressColor(engagement),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        engagement > 0 ? '${(engagement * 100).toInt()}%' : 'N/A',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tendance de l\'humeur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            moodTrend.isNotEmpty
                ? SizedBox(
                    height: 100,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: moodTrend.length.toDouble() - 1,
                        minY: 0,
                        maxY: 5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              moodTrend.length,
                              (index) => FlSpot(
                                index.toDouble(),
                                moodTrend[index],
                              ),
                            ),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Aucune donnée de tendance disponible',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.lightGreen;
    if (progress >= 0.4) return Colors.amber;
    if (progress >= 0.2) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}