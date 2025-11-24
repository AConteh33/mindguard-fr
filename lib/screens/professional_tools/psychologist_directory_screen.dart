import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';
import 'psychologist_profile_screen.dart';

class PsychologistDirectoryScreen extends StatefulWidget {
  const PsychologistDirectoryScreen({super.key});

  @override
  State<PsychologistDirectoryScreen> createState() => _PsychologistDirectoryScreenState();
}

class _PsychologistDirectoryScreenState extends State<PsychologistDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _psychologists = [];
  List<Map<String, dynamic>> _filteredPsychologists = [];
  bool _isLoading = true;
  String _selectedSpecialty = 'Tous';

  // Mock data for psychologists - in real app, this would come from Firestore
  final List<Map<String, dynamic>> _mockPsychologists = [
    {
      'id': 'psych1',
      'name': 'Dr. Marie Laurent',
      'specialty': 'Enfants et Adolescents',
      'experience': 15,
      'rating': 4.8,
      'languages': ['Français', 'Anglais'],
      'availability': 'Lun-Ven',
      'consultationPrice': 80,
      'description': 'Spécialisée dans le développement enfantin et les troubles de l\'apprentissage.',
      'photo': 'assets/psychologists/psych1.jpg',
      'verified': true,
    },
    {
      'id': 'psych2',
      'name': 'Dr. Jean-Pierre Martin',
      'specialty': 'Anxiété et Stress',
      'experience': 12,
      'rating': 4.9,
      'languages': ['Français'],
      'availability': 'Lun-Sam',
      'consultationPrice': 75,
      'description': 'Expert en gestion du stress et des troubles anxieux chez les jeunes.',
      'photo': 'assets/psychologists/psych2.jpg',
      'verified': true,
    },
    {
      'id': 'psych3',
      'name': 'Dr. Sophie Bernard',
      'specialty': 'Développement Personnel',
      'experience': 8,
      'rating': 4.7,
      'languages': ['Français', 'Espagnol'],
      'availability': 'Mar-Mer',
      'consultationPrice': 70,
      'description': 'Accompagnement des jeunes dans leur développement personnel et scolaire.',
      'photo': 'assets/psychologists/psych3.jpg',
      'verified': false,
    },
  ];

  final List<String> _specialties = [
    'Tous',
    'Enfants et Adolescents',
    'Anxiété et Stress',
    'Développement Personnel',
    'Troubles de l\'apprentissage',
    'Addiction',
    'Dépression',
  ];

  @override
  void initState() {
    super.initState();
    _loadPsychologists();
    _searchController.addListener(_filterPsychologists);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPsychologists() async {
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _psychologists = _mockPsychologists;
      _filteredPsychologists = _mockPsychologists;
      _isLoading = false;
    });
  }

  void _filterPsychologists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPsychologists = _psychologists.where((psychologist) {
        final matchesSearch = psychologist['name'].toString().toLowerCase().contains(query) ||
            psychologist['specialty'].toString().toLowerCase().contains(query);
        final matchesSpecialty = _selectedSpecialty == 'Tous' ||
            psychologist['specialty'] == _selectedSpecialty;
        return matchesSearch && matchesSpecialty;
      }).toList();
    });
  }

  void _onSpecialtyChanged(String specialty) {
    setState(() {
      _selectedSpecialty = specialty;
    });
    _filterPsychologists();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Only allow parents to access this screen
    if (authProvider.userModel?.role != 'parent') {
      return Scaffold(
        appBar: AppBar(title: const Text('Annuaire')),
        body: const Center(
          child: Text('Accès réservé aux parents'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un psychologue'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
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
                    placeholder: const Text('Rechercher par nom ou spécialité...'),
                    prefix: const Icon(Icons.search),
                  ),
                  const SizedBox(height: 16),
                  
                  // Specialty filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _specialties.length,
                      itemBuilder: (context, index) {
                        final specialty = _specialties[index];
                        final isSelected = specialty == _selectedSpecialty;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(specialty),
                            selected: isSelected,
                            onSelected: (_) => _onSpecialtyChanged(specialty),
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
            
            // Results section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPsychologists.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPsychologists.length,
                          itemBuilder: (context, index) {
                            final psychologist = _filteredPsychologists[index];
                            return _buildPsychologistCard(psychologist);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun psychologue trouvé',
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

  Widget _buildPsychologistCard(Map<String, dynamic> psychologist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PsychologistProfileScreen(
                psychologistData: psychologist,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and verified badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      psychologist['name'],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (psychologist['verified'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vérifié',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Specialty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  psychologist['specialty'],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                psychologist['description'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        psychologist['rating'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Experience
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${psychologist['experience']} ans',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Availability
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        psychologist['availability'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Price and languages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${psychologist['consultationPrice']}€/consultation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  // Languages
                  Row(
                    children: (psychologist['languages'] as List<String>).take(2).map((lang) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
