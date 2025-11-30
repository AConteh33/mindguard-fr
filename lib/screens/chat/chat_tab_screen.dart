import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/user_model.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_grid.dart';
import '../../widgets/responsive/responsive_card.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/responsive/responsive_icon.dart';
import '../../widgets/visual/animated_background_visual.dart';
import 'chat_screen.dart';
import 'professional_chat_screen.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  Future<List<UserModel>> _getChatUsers(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role ?? '';
    final userId = authProvider.userModel?.uid ?? '';

    List<UserModel> users = [];

    if (userRole == 'parent') {
      // Parent can chat with their children's psychologists
      final children = childrenProvider.children;
      for (var child in children) {
        // Get consultations for this child
        QuerySnapshot consultationSnapshot = await FirebaseFirestore.instance
            .collection('consultations')
            .where('childId', isEqualTo: child.id)
            .where('status', isEqualTo: 'active')
            .get();

        for (var consultationDoc in consultationSnapshot.docs) {
          Map<String, dynamic> consultation = consultationDoc.data() as Map<String, dynamic>;
          String psychologistId = consultation['psychologistId'];
          
          // Get psychologist details
          DocumentSnapshot psychologistDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(psychologistId)
              .get();
          
          if (psychologistDoc.exists) {
            Map<String, dynamic> psychologistData = psychologistDoc.data() as Map<String, dynamic>;
            users.add(UserModel(
              uid: psychologistId,
              email: psychologistData['email'] ?? '',
              name: psychologistData['name'] ?? 'Psychologue',
              role: 'psychologist',
            ));
          }
        }
      }
    } else if (userRole == 'child' && childrenProvider.parent != null) {
      // Child can chat with their parent
      users = [childrenProvider.parent!];
    } else if (userRole == 'psychologist') {
      // Psychologist can chat with their clients
      QuerySnapshot consultationSnapshot = await FirebaseFirestore.instance
          .collection('consultations')
          .where('psychologistId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'pending'])
          .get();

      for (var consultationDoc in consultationSnapshot.docs) {
        Map<String, dynamic> consultation = consultationDoc.data() as Map<String, dynamic>;
        String parentId = consultation['parentId'];
        
        // Get parent details
        DocumentSnapshot parentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentId)
            .get();
        
        if (parentDoc.exists) {
          Map<String, dynamic> parentData = parentDoc.data() as Map<String, dynamic>;
          users.add(UserModel(
            uid: parentId,
            email: parentData['email'] ?? '',
            name: parentData['name'] ?? 'Parent',
            role: 'parent',
          ));
        }
      }
    }

    // Remove duplicates
    users = users.fold([], (list, user) {
      if (!list.any((u) => u.uid == user.uid)) {
        list.add(user);
      }
      return list;
    });

    return users;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final userRole = authProvider.userModel?.role ?? 'child';

    return FutureBuilder<List<UserModel>>(
      future: _getChatUsers(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final chatUsers = snapshot.data ?? [];

        if (chatUsers.isEmpty) {
          return ResponsiveLayout(
            mobile: _buildEmptyStateMobile(context, userRole),
            tablet: _buildEmptyStateTablet(context, userRole),
            desktop: _buildEmptyStateDesktop(context, userRole),
          );
        }

        return ResponsiveLayout(
          mobile: _buildMobileChatList(context, chatUsers),
          tablet: _buildTabletChatList(context, chatUsers),
          desktop: _buildDesktopChatList(context, chatUsers),
        );
      },
    );
  }

  Widget _buildEmptyStateMobile(BuildContext context, String userRole) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: AnimatedBackgroundVisual(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ResponsiveIcon(
                icon: Icons.chat_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              ResponsiveText(
                'Aucune conversation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              ResponsiveText(
                userRole == 'parent' 
                    ? 'Ajoutez des enfants ou contactez des psychologues pour commencer à discuter'
                    : userRole == 'psychologist'
                        ? 'Attendez que des clients vous contactent'
                        : 'Attendez que votre parent vous lie à son compte',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              if (userRole == 'parent')
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/psychologist-directory');
                        },
                        icon: const Icon(Icons.psychology),
                        label: const Text('Trouver un psychologue'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/children/add');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un enfant'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateTablet(BuildContext context, String userRole) {
    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: Center(
          child: ResponsiveContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveIcon(
                  icon: Icons.chat_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 24),
                ResponsiveText(
                  'Aucune conversation',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                ResponsiveText(
                  userRole == 'parent' 
                      ? 'Ajoutez des enfants ou contactez des psychologues pour commencer à discuter'
                      : userRole == 'psychologist'
                          ? 'Attendez que des clients vous contactent'
                          : 'Attendez que votre parent vous lie à son compte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (userRole == 'parent')
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/psychologist-directory');
                          },
                          icon: const Icon(Icons.psychology),
                          label: const Text('Trouver un psychologue'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/children/add');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un enfant'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateDesktop(BuildContext context, String userRole) {
    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: Center(
          child: ResponsiveContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveIcon(
                  icon: Icons.chat_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 32),
                ResponsiveText(
                  'Aucune conversation',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                ResponsiveText(
                  userRole == 'parent' 
                      ? 'Ajoutez des enfants ou contactez des psychologues pour commencer à discuter'
                      : userRole == 'psychologist'
                          ? 'Attendez que des clients vous contactent'
                          : 'Attendez que votre parent vous lie à son compte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (userRole == 'parent')
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/psychologist-directory');
                          },
                          icon: const Icon(Icons.psychology),
                          label: const Text('Trouver un psychologue'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/children/add');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un enfant'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileChatList(BuildContext context, List<UserModel> chatUsers) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ResponsiveContainer(
        child: ListView.builder(
          padding: ResponsiveHelper.getResponsivePadding(context),
          itemCount: chatUsers.length,
          itemBuilder: (context, index) {
            final user = chatUsers[index];
            return _buildUserTile(context, user);
          },
        ),
      ),
    );
  }

  Widget _buildTabletChatList(BuildContext context, List<UserModel> chatUsers) {
    return Scaffold(
      body: ResponsiveContainer(
        child: ResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 1,
          spacing: ResponsiveHelper.getResponsiveSpacing(context, 16),
          runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 16),
          children: chatUsers.map((user) => _buildUserCard(context, user)).toList(),
        ),
      ),
    );
  }

  Widget _buildDesktopChatList(BuildContext context, List<UserModel> chatUsers) {
    return Scaffold(
      body: ResponsiveContainer(
        child: ResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          spacing: ResponsiveHelper.getResponsiveSpacing(context, 20),
          runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 20),
          children: chatUsers.map((user) => _buildUserCard(context, user)).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return ResponsiveCard(
      onTap: () {
        if (user.role == 'psychologist') {
          // Navigate to professional chat
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfessionalChatScreen(
                psychologistId: user.uid,
                psychologistName: user.name ?? 'Psychologue',
              ),
            ),
          );
        } else {
          // Navigate to family chat
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FamilyChatScreen(
                chatUserId: user.uid,
                chatUserName: user.name ?? 'Utilisateur',
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: ResponsiveIcon(
                  icon: user.role == 'child' 
                      ? Icons.child_care 
                      : user.role == 'psychologist'
                          ? Icons.psychology
                          : Icons.supervisor_account,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      user.name ?? 'Utilisateur',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveText(
                      user.role == 'psychologist' ? 'Consultation professionnelle' : 'Appuyez pour ouvrir la conversation',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ResponsiveIcon(
                icon: Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          user.role == 'child' 
              ? Icons.child_care 
              : user.role == 'psychologist'
                  ? Icons.psychology
                  : Icons.supervisor_account,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(user.name ?? 'Utilisateur'),
      subtitle: Text(
        user.role == 'psychologist' ? 'Consultation professionnelle' : 'Appuyez pour ouvrir la conversation',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (user.role == 'psychologist') {
          // Navigate to professional chat
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfessionalChatScreen(
                psychologistId: user.uid,
                psychologistName: user.name ?? 'Psychologue',
              ),
            ),
          );
        } else {
          // Navigate to family chat
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FamilyChatScreen(
                chatUserId: user.uid,
                chatUserName: user.name ?? 'Utilisateur',
              ),
            ),
          );
        }
      },
    );
  }
}
