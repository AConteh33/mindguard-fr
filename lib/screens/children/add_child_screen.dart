import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  String _invitationCode = '';
  bool _showCodeInput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un enfant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBackgroundVisual(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Choisissez une méthode de connexion',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez la manière dont vous souhaitez connecter avec votre enfant',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 32),
              
              // Connection Options
              Expanded(
                child: Column(
                  children: [
                    // QR Code Option
                    _buildConnectionOption(
                      context,
                      title: 'Scanner un QR Code',
                      description: 'Utilisez la caméra pour scanner le QR code de votre enfant',
                      icon: Icons.qr_code_scanner,
                      onTap: () {
                        context.push('/qr-scanner');
                      },
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Invitation Code Option
                    _buildConnectionOption(
                      context,
                      title: 'Utiliser un code d\'invitation',
                      description: 'Entrez manuellement le code d\'invitation unique de votre enfant',
                      icon: Icons.code,
                      onTap: () {
                        setState(() {
                          _showCodeInput = !_showCodeInput;
                        });
                      },
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    
                    // Code Input Section (expands when option is selected)
                    if (_showCodeInput) ...[
                      const SizedBox(height: 24),
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entrez le code d\'invitation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ShadInput(
                                placeholder: const Text('Code d\'invitation de votre enfant'),
                                onChanged: (value) {
                                  setState(() {
                                    _invitationCode = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ShadButton(
                                  onPressed: _invitationCode.isNotEmpty
                                    ? () => _connectWithCode()
                                    : null,
                                  child: const Text('Connecter avec le code'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Help Section
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Comment obtenir le code de votre enfant?',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Demandez à votre enfant d\'ouvrir son application MindGuard\n2. Allez dans la section "Profil" ou "Paramètres"\n3. Trouvez l\'option "Code de liaison" ou "QR Code"\n4. Votre enfant peut vous montrer son QR code ou vous donner son code d\'invitation',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectWithCode() async {
    if (_invitationCode.isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userModel?.role != 'parent') {
        _showError('Seuls les parents peuvent lier des enfants.');
        return;
      }

      // Parse the invitation code (format: childId_timestamp or just childId)
      String childId = _invitationCode.trim();
      if (childId.contains('_')) {
        childId = childId.split('_')[0];
      }

      // Verify the child exists by checking their user document
      final childDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .get();

      if (!childDoc.exists) {
        _showError('Code d\'invitation invalide. Enfant non trouvé.');
        return;
      }

      final childData = childDoc.data() as Map<String, dynamic>;
      if (childData['role'] != 'child') {
        _showError('Ce code n\'appartient pas à un compte enfant.');
        return;
      }

      // Check if already linked
      final existingLink = await FirebaseFirestore.instance
          .collection('parent_child_links')
          .where('parentId', isEqualTo: authProvider.userModel!.uid)
          .where('childId', isEqualTo: childId)
          .get();

      if (existingLink.docs.isNotEmpty) {
        _showError('Cet enfant est déjà lié à votre compte.');
        return;
      }

      // Create connection request
      await FirebaseFirestore.instance.collection('connection_requests').add({
        'parentId': authProvider.userModel!.uid,
        'childId': childId,
        'parentName': authProvider.userModel!.name ?? 'Parent',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'connectionMethod': 'invitation_code',
      });

      // Clear the input and show success
      setState(() {
        _invitationCode = '';
        _showCodeInput = false;
      });

      _showSuccess('Demande de connexion envoyée! L\'enfant doit approuver la demande.');
      
      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      _showError('Erreur lors de la connexion: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
