import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get appointments => _appointments;
  bool get isLoading => _isLoading;

  Future<void> loadAppointmentsForPsychologist(String psychologistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('appointments')
          .where('psychologistId', isEqualTo: psychologistId)
          .orderBy('scheduledDate', descending: false)
          .get();

      _appointments = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading appointments: $e');
      _appointments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointmentsForClient(String clientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('appointments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('scheduledDate', descending: false)
          .get();

      _appointments = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading appointments for client: $e');
      _appointments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    try {
      DocumentReference docRef = await _firestore.collection('appointments').add({
        ...appointmentData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      if (appointmentData['psychologistId'] != null) {
        await loadAppointmentsForPsychologist(appointmentData['psychologistId']);
      }
    } catch (e) {
      if (kDebugMode) print('Error adding appointment: $e');
      rethrow;
    }
  }

  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update(updatedData);
      
      // We'd need to know the psychologist ID to refresh properly
      // For now, just notify listeners
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> cancelAppointment(String appointmentId, String psychologistId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh the list
      await loadAppointmentsForPsychologist(psychologistId);
    } catch (e) {
      if (kDebugMode) print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Get an appointment by ID
  Map<String, dynamic>? getAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((appointment) => appointment['id'] == appointmentId);
    } catch (e) {
      return null; // Return null if not found
    }
  }
}