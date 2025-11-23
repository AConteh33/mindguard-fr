import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/child_model.dart';
import '../../widgets/visual/animated_background_visual.dart';
import 'add_child_screen.dart';

class ChildrenManagementScreen extends StatefulWidget {
  const ChildrenManagementScreen({super.key});

  @override
  State<ChildrenManagementScreen> createState() => _ChildrenManagementScreenState();
}

class _ChildrenManagementScreenState extends State<ChildrenManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load children when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
        childrenProvider.loadChildrenForParent(authProvider.userModel!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);

    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.supervisor_account, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Ajouter un enfant',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(
                        onPressed: () {
                          // Navigate to the dedicated add child screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddChildScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text('Ajouter un enfant'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choisissez entre scanner un QR code ou utiliser un code d\'invitation',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes enfants',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ShadButton.link(
                  onPressed: () {
                    // Show more options or filter
                  },
                  child: const Text('Trier'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: childrenProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : childrenProvider.children.isEmpty
                      ? ShadCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'Aucun enfant lié à votre compte',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: childrenProvider.children.length,
                          itemBuilder: (context, index) {
                            final child = childrenProvider.children[index];
                            return _buildChildCard(child);
                          },
                        ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    child.childName.split(' ')[0][0],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.childName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Écran aujourd\'hui: 2h 15m', // This would come from screen time provider
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                ShadButton.outline(
                  onPressed: () {
                    // Navigate to child details
                    context.push('/children/${child.childId}');
                  },
                  size: ShadButtonSize.sm,
                  child: const Text('Voir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildStatChip(
                    'Productivité',
                    '85%', // This would come from actual data
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildStatChip(
                    'Humeur',
                    '4.2', // This would come from actual mood data
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: child.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: child.isActive
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          child.isActive ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: child.isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          child.isActive ? 'En ligne' : 'Hors ligne',
                          style: TextStyle(
                            fontSize: 10,
                            color: child.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick actions row
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () {
                      context.push('/network-activity/${child.childId}');
                    },
                    size: ShadButtonSize.sm,
                    child: const Text('Activité réseau'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () {
                      // Send message to child
                    },
                    size: ShadButtonSize.sm,
                    child: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () {
                      // Set screen time limit
                    },
                    size: ShadButtonSize.sm,
                    child: const Text('Limite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}