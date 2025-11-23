import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';
import '../../widgets/bottom_nav_bar.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _selectedMood = -1;
  String _notes = '';

  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😄', 'label': 'Excellent', 'value': 5},
    {'emoji': '🙂', 'label': 'Bien', 'value': 4},
    {'emoji': '😐', 'label': 'Normal', 'value': 3},
    {'emoji': '😔', 'label': 'Triste', 'value': 2},
    {'emoji': '😫', 'label': 'Épuisé', 'value': 1},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de l\'humeur'),
        actions: [
          ShadButton.link(
            onPressed: () {
              context.push('/mood/history');
            },
            child: const Text('Historique'),
          ),
        ],
      ),
      body: AnimatedBackgroundVisual(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            Text(
              'Comment vous sentez-vous aujourd\'hui?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez votre humeur actuelle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Mood selection grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _moodOptions.length,
              itemBuilder: (context, index) {
                final mood = _moodOptions[index];
                final isSelected = _selectedMood == mood['value'];
                
                return ShadCard(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['value'];
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood['emoji'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood['label'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Notes section
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes (optionnel)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ShadInput(
                      placeholder: const Text('Comment s\'est passée votre journée?'),
                      maxLines: 4,
                      onChanged: (value) {
                        setState(() {
                          _notes = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Submit button
            ShadButton(
              onPressed: _selectedMood != -1
                  ? () {
                      // Save mood entry
                      _saveMoodEntry();
                    }
                  : null,
              child: const Text('Enregistrer l\'humeur'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  void _saveMoodEntry() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    
    if (authProvider.userModel != null) {
      // Save to mock data service
      moodProvider.addMoodEntry(
        authProvider.userModel!.uid, 
        _selectedMood, 
        _notes
      ).then((_) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Humeur enregistrée avec succès!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Reset selection after saving
        setState(() {
          _selectedMood = -1;
          _notes = '';
        });
      }).catchError((error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      });
    }
  }
}