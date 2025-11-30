import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/focus_session_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';
import '../../widgets/visual/enhanced_stat_card.dart';
import '../../services/connection_notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int _pendingRequestsCount = 0;
  bool _hasNewRequests = false;
  final ConnectionNotificationService _notificationService = ConnectionNotificationService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for pulsing effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
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
        
        // Start listening for connection requests if user is a child
        if (authProvider.userModel!.role == 'child') {
          _startListeningForRequests(userId);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notificationService.stopListening();
    _animationController.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
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
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('${_getActiveDays(screenTimeProvider)}',
                              style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text('Jours actif',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.mood, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('${moodProvider.moodEntries.length}',
                              style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text('Entrées humeur',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.do_not_disturb_on, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('${focusSessionProvider.sessions.length}',
                              style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text('Sessions focus',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.star, 
                              color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('${(_getCompletionRate(focusSessionProvider) * 100).round()}%',
                              style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Text('Taux de réussite',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Entrez votre nom complet',
                            border: OutlineInputBorder(),
                          ),
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
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Entrez votre adresse e-mail',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false, // Email shouldn't be editable here
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
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
                    Row(
                      children: [
                        Text(
                          'Lier à un parent',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_pendingRequestsCount > 0) ...[
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _hasNewRequests ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _hasNewRequests ? Colors.red : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _hasNewRequests ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ] : null,
                                  ),
                                  child: Text(
                                    '$_pendingRequestsCount demande${_pendingRequestsCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Show notification card if there are pending requests
                    if (_pendingRequestsCount > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _hasNewRequests ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasNewRequests ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: _hasNewRequests ? Colors.red : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hasNewRequests 
                                  ? 'Nouvelle demande de connexion reçue!'
                                  : 'Vous avez $_pendingRequestsCount demande${_pendingRequestsCount > 1 ? 's' : ''} en attente',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _hasNewRequests ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ShadButton.outline(
                              onPressed: () {
                                context.go('/connection-requests');
                                setState(() {
                                  _hasNewRequests = false;
                                });
                                // Stop the pulsing animation
                                _animationController.stop();
                                _animationController.reset();
                              },
                              child: const Text('Voir'),
                            ),
                          ],
                        ),
                      ),
                    
                    Card(
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
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to QR code display screen
                                context.go('/qr-code');
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
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to connection requests to see pending requests
                                context.go('/connection-requests');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.notifications),
                                  const SizedBox(width: 8),
                                  Text(_pendingRequestsCount > 0 
                                    ? 'Voir les demandes ($_pendingRequestsCount)'
                                    : 'Voir les demandes'),
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
                    OutlinedButton(
                      onPressed: () {
                        _showChangePasswordDialog(context);
                      },
                      child: const Text('Changer le mot de passe'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
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
                    ElevatedButton(
                      onPressed: () {
                        _showSignOutDialog(context);
                      },
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ), // This closes the Container
    ); // This closes the Scaffold
  }

  // Start listening for connection requests
  void _startListeningForRequests(String childId) {
    print('DEBUG: Setting context for notification service');
    // Set context for popup notifications
    _notificationService.setContext(context);
    
    print('DEBUG: Starting connection request listener');
    _notificationService.startListeningForConnectionRequests(childId, onNewRequest: () {
      if (mounted) {
        print('DEBUG: onNewRequest callback triggered');
        setState(() {
          _hasNewRequests = true;
        });
        // Start pulsing animation
        _animationController.repeat(reverse: true);
        // Auto-refresh the pending count
        _updatePendingRequestsCount();
        // Show prominent popup dialog
        _showInvitationDialog();
      }
    });
    
    // Also update the count initially
    _updatePendingRequestsCount();
  }

  // Update pending requests count
  Future<void> _updatePendingRequestsCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('DEBUG: Updating pending requests for user: ${authProvider.userModel?.uid}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('connection_requests')
          .where('childId', isEqualTo: authProvider.userModel!.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      print('DEBUG: Found ${snapshot.docs.length} pending requests');
      
      if (mounted) {
        setState(() {
          _pendingRequestsCount = snapshot.docs.length;
        });
        print('DEBUG: Updated pending count to: $_pendingRequestsCount');
      }
    } catch (e) {
      print('Error updating pending requests count: $e');
    }
  }

  // Show prominent invitation dialog
  void _showInvitationDialog() {
    print('DEBUG: Showing invitation dialog');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('DEBUG: Building invitation dialog');
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('🔔 Nouvelle demande de connexion!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quelqu\'un veut se connecter avec vous!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vous avez reçu une nouvelle demande de connexion d\'un parent. Vous pouvez l\'accepter ou la refuser dans la section des demandes de connexion.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vérifiez la section "Lier à un parent" dans votre profil pour voir la demande.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Plus tard'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/connection-requests');
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Voir la demande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
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
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmNewPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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