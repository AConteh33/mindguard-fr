import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/visual/animated_background_visual.dart';
import 'chat_screen.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final userRole = authProvider.userModel?.role ?? 'child';
    final currentUserId = authProvider.userModel?.uid ?? '';

    // Get available chat partners based on user role
    List<UserModel> chatUsers = [];
    
    if (userRole == 'parent' && childrenProvider.children.isNotEmpty) {
      // Parent can chat with their children
      chatUsers = childrenProvider.children.map((child) => UserModel(
        uid: child.childId,
        name: child.childName,
        role: 'child',
      )).toList();
    } else if (userRole == 'child' && childrenProvider.parent != null) {
      // Child can chat with their parent
      chatUsers = [childrenProvider.parent!];
    }

    if (chatUsers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: AnimatedBackgroundVisual(
          child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune conversation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                userRole == 'parent' 
                    ? 'Ajoutez des enfants pour commencer à discuter'
                    : 'Attendez que votre parent vous lie à son compte',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              if (userRole == 'parent')
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/children/add');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un enfant'),
                  ),
                ),
            ],
          ),
        ),
      ),
      );
    }

    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: chatUsers.length,
        itemBuilder: (context, index) {
          final user = chatUsers[index];
          return _buildUserTile(context, user);
        },
      ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          user.role == 'child' ? Icons.child_care : Icons.supervisor_account,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(user.name ?? 'Utilisateur'),
      subtitle: const Text('Appuyez pour ouvrir la conversation'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FamilyChatScreen(
              chatUserId: user.uid,
              chatUserName: user.name,
            ),
          ),
        );
      },
    );
  }
}
