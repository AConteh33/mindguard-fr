import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientProvider with ChangeNotifier {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get clients => _clients;
  bool get isLoading => _isLoading;

  Future<void> loadClientsForPsychologist(String psychologistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('clients')
          .where('psychologistId', isEqualTo: psychologistId)
          .get();

      _clients = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading clients: $e');
      _clients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(String psychologistId, Map<String, dynamic> clientData) async {
    try {
      DocumentReference docRef = await _firestore.collection('clients').add({
        ...clientData,
        'psychologistId': psychologistId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await loadClientsForPsychologist(psychologistId);
    } catch (e) {
      if (kDebugMode) print('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('clients').doc(clientId).update(updatedData);
      
      // Refresh the list - we'd need to know the psychologist ID to reload
      // For now, we'll just notify listeners
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> removeClient(String clientId, String psychologistId) async {
    try {
      await _firestore.collection('clients').doc(clientId).delete();
      
      // Refresh the list
      await loadClientsForPsychologist(psychologistId);
    } catch (e) {
      if (kDebugMode) print('Error removing client: $e');
      rethrow;
    }
  }

  // Get a client by ID
  Map<String, dynamic>? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client['id'] == clientId);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  // Get client progress data (this might come from a separate collection)
  Future<Map<String, dynamic>?> getClientProgress(String clientId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('client_progress').doc(clientId).get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading client progress: $e');
      return null;
    }
  }
}