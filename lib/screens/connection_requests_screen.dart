import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../models/child_model.dart';

class ConnectionRequestsScreen extends StatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  State<ConnectionRequestsScreen> createState() => _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _getConnectionRequests() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return Stream.empty();
    
    // Use a single field query instead of composite index
    return _firestore
        .collection('connection_requests')
        .where('childId', isEqualTo: authProvider.userModel!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.userModel == null) {
      return const Scaffold(
        body: Center(
          child: Text('Aucun utilisateur connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de connexion'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getConnectionRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aucune demande de connexion trouvée'),
            );
          }

          // Filter pending requests in the UI instead of query
          final pendingRequests = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          if (pendingRequests.isEmpty) {
            return const Center(
              child: Text('Aucune demande de connexion en attente'),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              final requestData = request.data() as Map<String, dynamic>;
              final parentId = requestData['parentId'] as String;
              final parentName = requestData['parentName'] as String;
              final requestedAt = requestData['requestedAt'] as Timestamp;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ShadCard(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.supervisor_account,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parentName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID Parent: ${parentId.substring(0, 8)}...',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'En attente',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Demande envoyée le ${_formatDate(requestedAt.toDate())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ShadButton.outline(
                              onPressed: () => _rejectRequest(request.id),
                              child: const Text('Refuser'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShadButton(
                              onPressed: () => _approveRequest(request.id, parentId, parentName),
                              child: const Text('Accepter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveRequest(String requestId, String parentId, String parentName) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

      if (authProvider.userModel == null) return;

      // Create the child-parent link
      final childModel = ChildModel(
        childId: authProvider.userModel!.uid,
        childName: authProvider.userModel!.name ?? 'Enfant',
        parentId: parentId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await childrenProvider.addChild(childModel);

      // Update the connection request status
      await _firestore.collection('connection_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Connexion établie'),
            description: Text('Vous êtes maintenant lié avec $parentName!'),
          ),
        );
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Erreur'),
            description: Text('Erreur lors de l\'approbation: $e'),
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      // Update the connection request status
      await _firestore.collection('connection_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Demande refusée'),
            description: const Text('La demande de connexion a été refusée'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Erreur'),
            description: Text('Erreur lors du refus: $e'),
          ),
        );
      }
    }
  }
}
