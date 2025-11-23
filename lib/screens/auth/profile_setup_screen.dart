import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedRole = '';
  String _selectedGender = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  String? get phoneNumber {
    final phoneParam = GoRouter.of(context).routeInformationProvider.value.uri.queryParameters['phone'];
    return phoneParam;
  }

  Future<void> _handleCompleteProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that a role is selected
    if (_selectedRole.isEmpty) {
      if (mounted) {
        // Using maybeOf to avoid errors when ScaffoldMessenger is not available
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un rôle'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to phone verification screen with user details
      // The phone number was already captured on the previous screen
      context.go('/phone-verification?phone=${Uri.encodeComponent(phoneNumber!)}&name=${Uri.encodeComponent(_nameController.text.trim())}&role=${Uri.encodeComponent(_selectedRole)}&flowType=registration${_selectedGender.isNotEmpty ? '&gender=${Uri.encodeComponent(_selectedGender)}' : ''}');
    } catch (e) {
      if (mounted) {
        // Using maybeOf to avoid errors when ScaffoldMessenger is not available
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du profil: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Complétez votre profil',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veuillez entrer vos informations personnelles',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        hintText: 'Entrez votre nom complet',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole.isEmpty ? null : _selectedRole,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: Text('Sélectionnez votre rôle'),
                        items: [
                          DropdownMenuItem(value: 'child', child: Text('Enfant')),
                          DropdownMenuItem(value: 'parent', child: Text('Parent')),
                          DropdownMenuItem(value: 'psychologist', child: Text('Psychologue')),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedRole = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGender.isEmpty ? null : _selectedGender,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Sélectionnez votre genre'),
                        items: [
                          DropdownMenuItem(value: 'homme', child: Text('Homme')),
                          DropdownMenuItem(value: 'femme', child: Text('Femme')),
                          DropdownMenuItem(value: 'autre', child: Text('Autre')),
                          DropdownMenuItem(value: '', child: Text('Préfère ne pas répondre')),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedGender = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _isLoading ? null : _handleCompleteProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continuer'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.go('/phone-number');
                      },
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}