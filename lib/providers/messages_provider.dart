import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadMessagesForPsychologist(String psychologistId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: psychologistId)
          .orderBy('timestamp', descending: true)
          .get();

      _messages = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading messages: $e');
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessagesForUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .where(
            Filter.or(
              Filter('senderId', isEqualTo: userId),
              Filter('recipientId', isEqualTo: userId),
            ),
          )
          .orderBy('timestamp', descending: true)
          .get();

      _messages = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading messages for user: $e');
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String senderId, String recipientId, String message, String? childId) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'recipientId': recipientId,
        'message': message,
        'childId': childId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Refresh messages after sending
      await loadMessagesForUser(senderId);
    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error marking message as read: $e');
      rethrow;
    }
  }

  // Get messages between two users
  Future<List<Map<String, dynamic>>> getMessagesBetweenUsers(String userId1, String userId2) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .where(
            Filter.or(
              Filter.and(
                Filter('senderId', isEqualTo: userId1),
                Filter('recipientId', isEqualTo: userId2),
              ),
              Filter.and(
                Filter('senderId', isEqualTo: userId2),
                Filter('recipientId', isEqualTo: userId1),
              ),
            ),
          )
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting messages between users: $e');
      return [];
    }
  }
}