import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';

class PsychologistRequestsScreen extends StatefulWidget {
  const PsychologistRequestsScreen({super.key});

  @override
  State<PsychologistRequestsScreen> createState() => _PsychologistRequestsScreenState();
}

class _PsychologistRequestsScreenState extends State<PsychologistRequestsScreen> {
  // Mock data for consultation requests
  List<Map<String, dynamic>> _requests = [
    {
      'id': 'req1',
      'parentId': 'parent1',
      'parentName': 'Marie Dupont',
      'parentEmail': 'marie.dupont@email.com',
      'childName': 'Thomas Dupont',
      'childAge': 12,
      'topic': 'Anxiété',
      'urgency': 'Normal',
      'format': 'Visioconférence',
      'reason': 'Mon fils présente des signes d\'anxiété scolaire depuis le début de l\'année.',
      'additionalInfo': 'Il a du mal à s\'endormir et se plaint de maux de ventre avant l\'école.',
      'timeSlots': ['Mardi après-midi', 'Jeudi matin'],
      'status': 'pending',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      'consultationPrice': 80,
    },
    {
      'id': 'req2',
      'parentId': 'parent2',
      'parentName': 'Jean Martin',
      'parentEmail': 'jean.martin@email.com',
      'childName': 'Sophie Martin',
      'childAge': 15,
      'topic': 'Dépression',
      'urgency': 'Urgent',
      'format': 'En cabinet',
      'reason': 'Ma fille s\'est isolée socialement et montre peu d\'intérêt pour ses activités habituelles.',
      'additionalInfo': 'Ses notes ont baissé et elle passe beaucoup de temps seule dans sa chambre.',
      'timeSlots': ['Lundi matin', 'Mercredi après-midi', 'Vendredi matin'],
      'status': 'pending',
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
      'consultationPrice': 80,
    },
    {
      'id': 'req3',
      'parentId': 'parent3',
      'parentName': 'Claire Bernard',
      'parentEmail': 'claire.bernard@email.com',
      'childName': 'Lucas Bernard',
      'childAge': 8,
      'topic': 'Troubles du sommeil',
      'urgency': 'Normal',
      'format': 'Visioconférence',
      'reason': 'Mon fils a des difficultés à s\'endormir et fait fréquemment des cauchemars.',
      'additionalInfo': '',
      'timeSlots': ['Lundi après-midi', 'Mercredi matin'],
      'status': 'approved',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'consultationPrice': 80,
      'approvedAt': DateTime.now().subtract(const Duration(hours: 12)),
      'firstSessionDate': DateTime.now().add(const Duration(days: 3)),
    },
  ];

  String _selectedStatus = 'Tous';

  final List<String> _statusOptions = [
    'Tous',
    'En attente',
    'Approuvées',
    'Refusées',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Only allow psychologists to access this screen
    if (authProvider.userModel?.role != 'psychologist') {
      return Scaffold(
        appBar: AppBar(title: const Text('Demandes de consultation')),
        body: const Center(
          child: Text('Accès réservé aux psychologues'),
        ),
      );
    }

    final filteredRequests = _getFilteredRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de consultation'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Status filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _selectedStatus = status;
              });
            },
            itemBuilder: (context) => _statusOptions.map((status) {
              return PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      status == _selectedStatus ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(status),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: AnimatedBackgroundVisual(
        child: Column(
          children: [
            // Status filter chips
            if (_selectedStatus != 'Tous')
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_selectedStatus),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'Tous';
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      '${filteredRequests.length} demande${filteredRequests.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Requests list
            Expanded(
              child: filteredRequests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        final request = filteredRequests[index];
                        return _buildRequestCard(request);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    if (_selectedStatus == 'Tous') {
      return _requests;
    }
    
    switch (_selectedStatus) {
      case 'En attente':
        return _requests.where((r) => r['status'] == 'pending').toList();
      case 'Approuvées':
        return _requests.where((r) => r['status'] == 'approved').toList();
      case 'Refusées':
        return _requests.where((r) => r['status'] == 'rejected').toList();
      default:
        return _requests;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune demande',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez aucune demande de consultation pour le moment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final isPending = request['status'] == 'pending';
    final isApproved = request['status'] == 'approved';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and urgency
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['parentName'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pour ${request['childName']}, ${request['childAge']} ans',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(request['status']),
                      const SizedBox(height: 4),
                      _buildUrgencyChip(request['urgency']),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Topic and format
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request['topic'],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request['format'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${request['consultationPrice']}€',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Reason preview
              Text(
                request['reason'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Time slots
              if (request['timeSlots'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créneaux souhaités:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (request['timeSlots'] as List<String>).take(3).map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            slot,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Action buttons for pending requests
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(request),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Refuser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(request),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Approved request info
              if (isApproved)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Approuvée le ${_formatDate(request['approvedAt'])}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approuvée';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Refusée';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    Color color;
    
    switch (urgency) {
      case 'Urgent':
        color = Colors.orange;
        break;
      case 'Très urgent':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        urgency,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la demande'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Parent', request['parentName']),
              _buildDetailRow('Email', request['parentEmail']),
              _buildDetailRow('Enfant', '${request['childName']}, ${request['childAge']} ans'),
              _buildDetailRow('Sujet', request['topic']),
              _buildDetailRow('Urgence', request['urgency']),
              _buildDetailRow('Format', request['format']),
              _buildDetailRow('Date de demande', _formatDate(request['createdAt'])),
              const SizedBox(height: 12),
              Text(
                'Raison:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(request['reason']),
              if (request['additionalInfo'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Informations complémentaires:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(request['additionalInfo']),
              ],
              const SizedBox(height: 12),
              Text(
                'Créneaux souhaités:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...request['timeSlots'].map((slot) => Text('• $slot')),
            ],
          ),
        ),
        actions: [
          if (request['status'] == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectRequest(request);
              },
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveRequest(request);
              },
              child: const Text('Approuver'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _approveRequest(Map<String, dynamic> request) {
    setState(() {
      final index = _requests.indexWhere((r) => r['id'] == request['id']);
      if (index != -1) {
        _requests[index]['status'] = 'approved';
        _requests[index]['approvedAt'] = DateTime.now();
        _requests[index]['firstSessionDate'] = DateTime.now().add(const Duration(days: 3));
      }
    });

    ShadToaster.of(context).show(
      ShadToast(
        title: const Text('Demande approuvée'),
        description: Text('La demande de ${request['parentName']} a été approuvée.'),
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    setState(() {
      final index = _requests.indexWhere((r) => r['id'] == request['id']);
      if (index != -1) {
        _requests[index]['status'] = 'rejected';
      }
    });

    ShadToaster.of(context).show(
      const ShadToast.destructive(
        title: Text('Demande refusée'),
        description: Text('La demande a été refusée et le parent en sera notifié.'),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
