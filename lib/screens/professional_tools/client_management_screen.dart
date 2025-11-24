import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

  // Mock data for clients
  final List<Map<String, dynamic>> _mockClients = [
    {
      'id': 'client1',
      'parentId': 'parent1',
      'parentName': 'Marie Dupont',
      'parentEmail': 'marie.dupont@email.com',
      'parentPhone': '+33 6 12 34 56 78',
      'childName': 'Thomas Dupont',
      'childAge': 12,
      'childGender': 'Garçon',
      'consultationReason': 'Anxiété scolaire',
      'status': 'active',
      'startDate': DateTime.now().subtract(const Duration(days: 30)),
      'lastSession': DateTime.now().subtract(const Duration(days: 3)),
      'nextSession': DateTime.now().add(const Duration(days: 4)),
      'totalSessions': 8,
      'upcomingSessions': 2,
      'notes': 'Thomas montre des signes d\'amélioration. Continuez avec les techniques de relaxation.',
      'emergencyContact': '+33 6 98 76 54 32',
      'address': '123 Rue de la Paix, 75001 Paris',
      'consultationType': 'Visioconférence',
      'paymentStatus': 'paid',
    },
    {
      'id': 'client2',
      'parentId': 'parent2',
      'parentName': 'Jean Martin',
      'parentEmail': 'jean.martin@email.com',
      'parentPhone': '+33 6 23 45 67 89',
      'childName': 'Sophie Martin',
      'childAge': 15,
      'childGender': 'Fille',
      'consultationReason': 'Dépression adolescente',
      'status': 'active',
      'startDate': DateTime.now().subtract(const Duration(days: 15)),
      'lastSession': DateTime.now().subtract(const Duration(days: 7)),
      'nextSession': DateTime.now().add(const Duration(days: 2)),
      'totalSessions': 4,
      'upcomingSessions': 3,
      'notes': 'Sophie est plus ouverte à la communication. Explorer les relations sociales.',
      'emergencyContact': '+33 6 87 65 43 21',
      'address': '456 Avenue des Champs-Élysées, 75008 Paris',
      'consultationType': 'En cabinet',
      'paymentStatus': 'pending',
    },
    {
      'id': 'client3',
      'parentId': 'parent3',
      'parentName': 'Claire Bernard',
      'parentEmail': 'claire.bernard@email.com',
      'parentPhone': '+33 6 34 56 78 90',
      'childName': 'Lucas Bernard',
      'childAge': 8,
      'childGender': 'Garçon',
      'consultationReason': 'Troubles du sommeil',
      'status': 'inactive',
      'startDate': DateTime.now().subtract(const Duration(days: 90)),
      'lastSession': DateTime.now().subtract(const Duration(days: 30)),
      'nextSession': null,
      'totalSessions': 12,
      'upcomingSessions': 0,
      'notes': 'Lucas a montré une amélioration significative. Parents satisfaits.',
      'emergencyContact': '+33 6 76 54 32 10',
      'address': '789 Boulevard Saint-Germain, 75006 Paris',
      'consultationType': 'Visioconférence',
      'paymentStatus': 'paid',
    },
  ];

  final List<String> _statusOptions = [
    'Tous',
    'Actifs',
    'Inactifs',
    'Nouveaux',
  ];

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
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _clients = _mockClients;
      _filteredClients = _mockClients;
      _isLoading = false;
    });
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((client) {
        final matchesSearch = client['parentName'].toString().toLowerCase().contains(query) ||
            client['childName'].toString().toLowerCase().contains(query) ||
            client['consultationReason'].toString().toLowerCase().contains(query);
        final matchesStatus = _selectedStatus == 'Tous' || _getStatusFilter(client['status']) == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _getStatusFilter(String status) {
    switch (status) {
      case 'active':
        return 'Actifs';
      case 'inactive':
        return 'Inactifs';
      case 'new':
        return 'Nouveaux';
      default:
        return 'Tous';
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterClients();
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
