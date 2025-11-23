import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_nav_bar.dart';

class SessionManagementScreen extends StatefulWidget {
  const SessionManagementScreen({super.key});

  @override
  State<SessionManagementScreen> createState() => _SessionManagementScreenState();
}

class _SessionManagementScreenState extends State<SessionManagementScreen> {
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': '1',
      'clientName': 'Marie Dubois',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'duration': '1h 30m',
      'status': 'Completed',
      'notes': 'Bonne progression sur les techniques de relaxation',
    },
    {
      'id': '2',
      'clientName': 'Jean Petit',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'duration': '45m',
      'status': 'Completed',
      'notes': 'Discuté des déclencheurs de stress',
    },
    {
      'id': '3',
      'clientName': 'Sophie Martin',
      'date': DateTime.now().add(const Duration(days: 1)),
      'duration': '1h',
      'status': 'Scheduled',
      'notes': '',
    },
    {
      'id': '4',
      'clientName': 'Pierre Lambert',
      'date': DateTime.now().add(const Duration(days: 3)),
      'duration': '1h 15m',
      'status': 'Scheduled',
      'notes': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des séances'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Upcoming sessions card
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Prochaine séance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        ShadButton(
                          onPressed: () {
                            // Schedule new session
                          },
                          size: ShadButtonSize.sm,
                          child: const Text('+ Nouvelle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUpcomingSessionCard(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Session list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique des séances',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ShadButton.link(
                  onPressed: () {
                    // Filter options
                  },
                  child: const Text('Filtrer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: _sessions.isEmpty
                  ? ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Aucune séance planifiée ou terminée',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return _buildSessionCard(session);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
  Widget _buildUpcomingSessionCard() {
    // Find next scheduled session
    final nextSession = _sessions.firstWhere(
      (s) => s['status'] == 'Scheduled',
      orElse: () => _sessions.first,
    );

    return ShadCard(

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    nextSession['clientName'].split(' ')[0][0],
                    style: const TextStyle(
                      fontSize: 16,
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
                        nextSession['clientName'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_formatDate(nextSession['date'])} à ${_formatTime(nextSession['date'])}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    nextSession['status'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShadButton(
              onPressed: () {
                // Start session
              },
              child: const Text('Démarrer la séance'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    session['clientName'].split(' ')[0][0],
                    style: const TextStyle(
                      fontSize: 16,
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
                        session['clientName'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_formatDate(session['date'])} • ${session['duration']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session['status'] == 'Completed'
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session['status'],
                    style: TextStyle(
                      color: session['status'] == 'Completed'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (session['notes'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session['notes'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () {
                      // View session details
                    },
                    child: const Text('Détails'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () {
                      // Add notes
                    },
                    child: const Text('Notes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}