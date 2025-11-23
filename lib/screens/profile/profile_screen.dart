import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/focus_session_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../widgets/visual/enhanced_stat_card.dart';
import '../../widgets/visual/animated_background_visual.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load real data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final userId = authProvider.userModel!.uid;
        
        // Load real data from providers
        final moodProvider = Provider.of<MoodProvider>(context, listen: false);
        final focusSessionProvider = Provider.of<FocusSessionProvider>(context, listen: false);
        final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
        
        moodProvider.loadMoodEntries(userId);
        focusSessionProvider.loadFocusSessions(userId);
        screenTimeProvider.loadScreenTimeData(userId);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    final userModel = authProvider.userModel;

    if (userModel == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    _nameController.text = userModel.name ?? '';
    _emailController.text = userModel.email ?? '';

    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User info
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      userModel.name ?? 'Utilisateur',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userModel.email ?? userModel.phone ?? 'Aucune information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(context, userModel.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRoleColor(context, userModel.role),
                        ),
                      ),
                      child: Text(
                        _getRoleLabel(userModel.role),
                        style: TextStyle(
                          color: _getRoleColor(context, userModel.role),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats summary
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: EnhancedStatCard(
                      value: '${_getActiveDays(screenTimeProvider)}',
                      label: 'Jours actif',
                      icon: Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: EnhancedStatCard(
                      value: '${moodProvider.moodEntries.length}',
                      label: 'Entrées humeur',
                      icon: Icons.mood,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: EnhancedStatCard(
                      value: '${focusSessionProvider.sessions.length}',
                      label: 'Sessions focus',
                      icon: Icons.do_not_disturb_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: EnhancedStatCard(
                      value: '${(_getCompletionRate(focusSessionProvider) * 100).round()}%',
                      label: 'Taux de réussite',
                      icon: Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Edit profile form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations personnelles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nom complet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShadInput(
                          controller: _nameController,
                          placeholder: const Text('Entrez votre nom complet'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adresse e-mail',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShadInput(
                          controller: _emailController,
                          placeholder: const Text('Entrez votre adresse e-mail'),
                          enabled: false, // Email shouldn't be editable in this mock
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _updateProfile(authProvider);
                        }
                      },
                      child: const Text('Mettre à jour le profil'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Parent invitation section for children
              if (authProvider.userModel?.role == 'child') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lier à un parent',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Partagez ce code QR avec votre parent pour qu\'il puisse surveiller votre bien-être numérique',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ShadButton(
                              onPressed: () {
                                // Navigate to QR code display screen
                                context.push('/qr-code');
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code),
                                  SizedBox(width: 8),
                                  Text('Afficher le QR Code'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'MDGRD-${userModel.uid.substring(0, math.min(6, userModel.uid.length))}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      // Copy to clipboard functionality would go here
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Code copié dans le presse-papiers'),
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShadButton(
                              onPressed: () {
                                // Share functionality would go here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Fonctionnalité de partage à implémenter'),
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share),
                                  SizedBox(width: 8),
                                  Text('Partager le code'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
              // Account actions
              SizedBox(
                width: double.infinity,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions du compte',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ShadButton.outline(
                    onPressed: () {
                      _showChangePasswordDialog(context);
                    },
                    child: const Text('Changer le mot de passe'),
                  ),
                  const SizedBox(height: 12),
                  ShadButton.outline(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    child: Text(
                      'Supprimer le compte',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShadButton(
                    onPressed: () {
                      _showSignOutDialog(context);
                    },
                    child: const Text('Se déconnecter'),
                  ),
                ],
              ),),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role) {
      case 'child':
        return Colors.green;
      case 'parent':
        return Colors.blue;
      case 'psychologist':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'child':
        return 'Enfant';
      case 'parent':
        return 'Parent';
      case 'psychologist':
        return 'Psychologue';
      default:
        return 'Inconnu';
    }
  }

  Future<void> _updateProfile(AuthProvider authProvider) async {
    try {
      await authProvider.updateProfile(name: _nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour avec succès!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final newPasswordController = TextEditingController();
        final confirmNewPasswordController = TextEditingController();

        return AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadInput(
                controller: newPasswordController,
                placeholder: const Text('Nouveau mot de passe'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: confirmNewPasswordController,
                placeholder: const Text('Confirmer le mot de passe'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ShadButton(
              onPressed: () {
                // In a real app, this would call the change password API
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe changé avec succès!'),
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible et toutes vos données seront perdues.',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ShadButton(
              onPressed: () {
                // In a real app, this would call the delete account API
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte supprimé!'),
                    ),
                  );
                  // In a real app, this would log out the user and navigate to login
                }
              },
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter?',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ShadButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.signOut();
                context.go('/');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for real stats
  int _getActiveDays(ScreenTimeProvider screenTimeProvider) {
    // Calculate active days based on screen time data
    // For now, return the number of days with any screen time data
    // This could be enhanced to track actual active days from the data
    final weeklyData = screenTimeProvider.getWeeklyScreenTime();
    return weeklyData.where((minutes) => minutes > 0).length;
  }

  double _getCompletionRate(FocusSessionProvider focusSessionProvider) {
    final stats = focusSessionProvider.getFocusStats();
    return stats['completionRate'] as double;
  }
}