import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfessionalAssessmentToolsScreen extends StatefulWidget {
  const ProfessionalAssessmentToolsScreen({super.key});

  @override
  State<ProfessionalAssessmentToolsScreen> createState() =>
      _ProfessionalAssessmentToolsScreenState();
}

class _ProfessionalAssessmentToolsScreenState
    extends State<ProfessionalAssessmentToolsScreen> {
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  List<String> _categories = ['Tous'];

  @override
  void initState() {
    super.initState();
    // Load assessment tools when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
      assessmentProvider.loadAssessmentTools();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assessmentProvider = Provider.of<AssessmentProvider>(context);

    // Get unique categories from loaded assessment tools
    final allTools = assessmentProvider.assessmentTools;
    final uniqueCategories = {'Tous'};
    for (final tool in allTools) {
      uniqueCategories.add(tool['category'] as String? ?? 'Autre');
    }
    _categories = uniqueCategories.toList();

    // Filter tools based on category and search query
    List<Map<String, dynamic>> filteredTools = allTools.where((tool) {
      final matchesCategory = _selectedCategory == 'Tous' || 
          tool['category'] == _selectedCategory;
      final bool descriptionMatches = (tool['description'] as String?) != null
          ? (tool['description'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
          : false;
      final matchesSearch = _searchQuery.isEmpty ||
          (tool['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          descriptionMatches;
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outils d\'évaluation professionnels'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category filter
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  bool isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: isSelected
                        ? ShadButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            size: ShadButtonSize.sm,
                            child: Text(category),
                          )
                        : ShadButton.outline(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            size: ShadButtonSize.sm,
                            child: Text(category),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            ShadInput(
              placeholder: const Text('Rechercher des outils d\'évaluation...'),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Assessment tools list
            Expanded(
              child: assessmentProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = filteredTools[index];
                        return _buildAssessmentToolCard(tool);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentToolCard(Map<String, dynamic> tool) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tool['category'] ?? 'Autre',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tool['estimatedTime'] ?? 'N/A',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(tool['difficulty'] ?? 'Intermédiaire')
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tool['difficulty'] ?? 'Intermédiaire',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDifficultyColor(tool['difficulty'] ?? 'Intermédiaire'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tool['title'] ?? 'Outil sans titre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tool['description'] ?? 'Aucune description disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: () {
                // Navigate to assessment tool
                context.push('/professional-tools/assessment/${tool['id']}');
              },
              child: const Text('Commencer l\'évaluation'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Facile':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.amber;
      case 'Avancé':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
}