import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_nav_bar.dart';

class ResourcesLibraryScreen extends StatefulWidget {
  const ResourcesLibraryScreen({super.key});

  @override
  State<ResourcesLibraryScreen> createState() => _ResourcesLibraryScreenState();
}

class _ResourcesLibraryScreenState extends State<ResourcesLibraryScreen> {
  final List<String> _categories = ['Tous', 'Anxiété', 'Dépression', 'Stress', 'Sommeil', 'Estime de soi'];
  String _selectedCategory = 'Tous';
  
  final List<Map<String, dynamic>> _resources = [
    {
      'id': '1',
      'title': 'Gestion de l\'anxiété',
      'category': 'Anxiété',
      'type': 'Article',
      'readTime': '8 min',
      'isBookmarked': false,
    },
    {
      'id': '2',
      'title': 'Techniques de relaxation',
      'category': 'Stress',
      'type': 'Vidéo',
      'readTime': '12 min',
      'isBookmarked': true,
    },
    {
      'id': '3',
      'title': 'Améliorer la qualité du sommeil',
      'category': 'Sommeil',
      'type': 'Guide',
      'readTime': '15 min',
      'isBookmarked': false,
    },
    {
      'id': '4',
      'title': 'Exercices de pleine conscience',
      'category': 'Stress',
      'type': 'Exercice',
      'readTime': '10 min',
      'isBookmarked': false,
    },
    {
      'id': '5',
      'title': 'Renforcer l\'estime de soi',
      'category': 'Estime de soi',
      'type': 'Article',
      'readTime': '6 min',
      'isBookmarked': true,
    },
    {
      'id': '6',
      'title': 'Identifier les déclencheurs de dépression',
      'category': 'Dépression',
      'type': 'Fiche',
      'readTime': '5 min',
      'isBookmarked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque de ressources'),
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
                    child: ShadButton(
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
              placeholder: const Text('Rechercher des ressources...'),

            ),
            const SizedBox(height: 16),
            
            // Resources list
            Expanded(
              child: ListView.builder(
                itemCount: _resources.length,
                itemBuilder: (context, index) {
                  final resource = _resources[index];
                  // Filter by category if not "Tous"
                  if (_selectedCategory != 'Tous' && resource['category'] != _selectedCategory) {
                    return const SizedBox.shrink();
                  }
                  
                  return _buildResourceCard(resource);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
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
                          resource['type'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        resource['readTime'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resource['title'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource['category'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ShadButton.outline(
              onPressed: () {
                // Toggle bookmark
                setState(() {
                  resource['isBookmarked'] = !resource['isBookmarked'];
                });
              },


              child: Icon(
                resource['isBookmarked'] 
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}