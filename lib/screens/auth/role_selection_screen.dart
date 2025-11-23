import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.supervisor_account,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sélectionnez votre rôle',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez le rôle qui correspond le mieux à votre situation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildRoleOption(
                    context,
                    Icons.child_care,
                    'Enfant',
                    'Utilisez l\'application pour suivre votre bien-être numérique',
                    'child',
                  ),
                  const SizedBox(height: 16),
                  _buildRoleOption(
                    context,
                    Icons.supervisor_account,
                    'Parent',
                    'Gardez un œil sur le bien-être numérique de vos enfants',
                    'parent',
                  ),
                  const SizedBox(height: 16),
                  _buildRoleOption(
                    context,
                    Icons.psychology,
                    'Psychologue',
                    'Accédez aux outils professionnels pour vos patients',
                    'psychologist',
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: const Text('J\'ai déjà un compte ? Connexion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String role,
  ) {
    return ShadCard(
      child: InkWell(
        onTap: () {
          // Navigate to email registration screen with the selected role
          context.go('/register?role=$role');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
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
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}