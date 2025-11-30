import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';
import 'professional_chat_screen.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tous';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final psychologistId = authProvider.userModel?.uid;

      if (psychologistId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load real clients from Firestore - clients assigned to this psychologist
      QuerySnapshot snapshot = await _firestore
          .collection('consultations')
          .where('psychologistId', isEqualTo: psychologistId)
          .where('status', whereIn: ['active', 'pending', 'completed'])
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> clients = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> consultation = doc.data() as Map<String, dynamic>;
        
        // Get parent details
        DocumentSnapshot parentDoc = await _firestore
            .collection('users')
            .doc(consultation['parentId'])
            .get();
        
        if (parentDoc.exists) {
          Map<String, dynamic> parentData = parentDoc.data() as Map<String, dynamic>;
          
          // Get child details
          DocumentSnapshot childDoc = await _firestore
              .collection('children')
              .doc(consultation['childId'])
              .get();
          
          if (childDoc.exists) {
            Map<String, dynamic> childData = childDoc.data() as Map<String, dynamic>;
            
            clients.add({
              'id': doc.id,
              'consultationId': doc.id,
              'parentId': consultation['parentId'],
              'parentName': parentData['name'] ?? 'Parent inconnu',
              'parentEmail': parentData['email'] ?? '',
              'parentPhone': parentData['phone'] ?? '',
              'childName': childData['name'] ?? 'Enfant inconnu',
              'childAge': childData['age'] ?? 0,
              'childGender': childData['gender'] ?? '',
              'consultationReason': consultation['reason'] ?? '',
              'status': consultation['status'],
              'startDate': (consultation['createdAt'] as Timestamp?)?.toDate(),
              'lastSession': (consultation['lastSession'] as Timestamp?)?.toDate(),
              'nextSession': (consultation['nextSession'] as Timestamp?)?.toDate(),
              'totalSessions': consultation['totalSessions'] ?? 0,
              'upcomingSessions': consultation['upcomingSessions'] ?? 0,
              'notes': consultation['notes'] ?? '',
              'emergencyContact': parentData['phone'] ?? '',
              'address': parentData['address'] ?? '',
              'consultationType': consultation['consultationType'] ?? 'Visioconférence',
              'paymentStatus': consultation['paymentStatus'] ?? 'pending',
            });
          }
        }
      }

      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clients: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterClients() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredClients = _clients.where((client) {
        final matchesSearch = 
            client['parentName']?.toString().toLowerCase().contains(query) == true ||
            client['childName']?.toString().toLowerCase().contains(query) == true ||
            client['consultationReason']?.toString().toLowerCase().contains(query) == true;
        final matchesStatus = _selectedStatus == 'Tous' ||
            client['status'] == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterClients();
  }

  List<String> get _statusOptions {
    Set<String> statuses = {'Tous'};
    for (var client in _clients) {
      if (client['status'] != null) {
        String status = client['status'].toString();
        if (status == 'active') statuses.add('Actifs');
        else if (status == 'inactive') statuses.add('Inactifs');
        else if (status == 'pending') statuses.add('Nouveaux');
        else statuses.add(status);
      }
    }
    return statuses.toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Only allow psychologists to access this screen
    if (authProvider.userModel?.role != 'psychologist') {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestion des clients')),
        body: const Center(
          child: Text('Accès réservé aux psychologues'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes clients'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddClientDialog,
            icon: const Icon(Icons.person_add),
            tooltip: 'Ajouter un client',
          ),
        ],
      ),
      body: AnimatedBackgroundVisual(
        child: Column(
          children: [
            // Search and filter section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  ShadInput(
                    controller: _searchController,
                    placeholder: const Text('Rechercher par nom, enfant, ou raison...'),
                    prefix: const Icon(Icons.search),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      itemBuilder: (context, index) {
                        final status = _statusOptions[index];
                        final isSelected = status == _selectedStatus;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (_) => _onStatusChanged(status),
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats cards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Clients actifs',
                      _clients.where((c) => c['status'] == 'active').length.toString(),
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Séances ce mois',
                      _getMonthlySessionsCount().toString(),
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Nouveaux clients',
                      _getNewClientsCount().toString(),
                      Icons.person_add,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Clients list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredClients.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return _buildClientCard(client);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun client trouvé',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier votre recherche ou vos filtres',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final isActive = client['status'] == 'active';
    final nextSession = client['nextSession'] as DateTime?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showClientDetails(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['parentName'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${client['childName']}, ${client['childAge']} ans',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(client['status']),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Consultation info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      client['consultationReason'],
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
                      client['consultationType'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Session info
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${client['totalSessions']} séances',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.event_upcoming,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    nextSession != null
                        ? 'Prochaine: ${_formatDate(nextSession)}'
                        : 'Aucune séance prévue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startChat(client),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Discuter'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scheduleSession(client),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Planifier'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showClientDetails(client),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Plus d\'options',
                  ),
                ],
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
      case 'active':
        color = Colors.green;
        label = 'Actif';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Inactif';
        break;
      case 'new':
        color = Colors.orange;
        label = 'Nouveau';
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

  void _showClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du client'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Parent', client['parentName']),
              _buildDetailRow('Email', client['parentEmail']),
              _buildDetailRow('Téléphone', client['parentPhone']),
              _buildDetailRow('Enfant', '${client['childName']}, ${client['childAge']} ans (${client['childGender']})'),
              _buildDetailRow('Raison', client['consultationReason']),
              _buildDetailRow('Type de consultation', client['consultationType']),
              _buildDetailRow('Début', _formatDate(client['startDate'])),
              _buildDetailRow('Dernière séance', _formatDate(client['lastSession'])),
              _buildDetailRow('Prochaine séance', client['nextSession'] != null ? _formatDate(client['nextSession']) : 'Non planifiée'),
              _buildDetailRow('Total séances', client['totalSessions'].toString()),
              _buildDetailRow('Contact d\'urgence', client['emergencyContact']),
              _buildDetailRow('Adresse', client['address']),
              const SizedBox(height: 12),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(client['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startChat(client);
            },
            child: const Text('Discuter'),
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

  void _startChat(Map<String, dynamic> client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfessionalChatScreen(
          psychologistId: 'current_psychologist',
          psychologistName: 'Dr. Marie Laurent',
          consultationId: client['id'],
        ),
      ),
    );
  }

  void _scheduleSession(Map<String, dynamic> client) {
    ShadToaster.of(context).show(
      ShadToast(
        title: Text('Planification de séance'),
        description: Text('Planification d\'une séance avec ${client['parentName']}'),
      ),
    );
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un client'),
        content: const Text('Cette fonctionnalité sera bientôt disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int _getMonthlySessionsCount() {
    final now = DateTime.now();
    return _clients.where((client) {
      final nextSession = client['nextSession'] as DateTime?;
      return nextSession != null &&
          nextSession.month == now.month &&
          nextSession.year == now.year;
    }).length;
  }

  int _getNewClientsCount() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _clients.where((client) {
      final startDate = client['startDate'] as DateTime;
      return startDate.isAfter(thirtyDaysAgo);
    }).length;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
