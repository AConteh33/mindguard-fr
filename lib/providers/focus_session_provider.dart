import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final bool completed;
  final List<String> blockedApps; // Apps that were blocked during the session
  final DateTime createdAt;

  FocusSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.completed = false,
    this.blockedApps = const [],
    required this.createdAt,
  });

  // Create FocusSession from Firestore document
  factory FocusSession.fromMap(Map<String, dynamic> map, String id) {
    return FocusSession(
      id: id,
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      durationMinutes: map['durationMinutes'] ?? 0,
      completed: map['completed'] ?? false,
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert FocusSession to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'completed': completed,
      'blockedApps': blockedApps,
      'createdAt': createdAt,
    };
  }
}

class FocusSessionProvider with ChangeNotifier {
  List<FocusSession> _sessions = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FocusSession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> loadFocusSessions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      _sessions = snapshot.docs
          .map((doc) => FocusSession.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading focus sessions: $e');
      
      // Check if it's an index error
      if (e.toString().contains('requires an index')) {
        _sessions = [];
        // Show user-friendly message about index setup
        throw Exception(
          'Database index required. Please create the focus_sessions index:\n'
          'Collection: focus_sessions\n'
          'Fields: userId (Ascending), startTime (Descending)\n'
          'Or visit: https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=Clpwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9mb2N1c19zZXNzaW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoNCglzdGFydFRpbWUQAhoMCghfX25hbWVfXxAC'
        );
      }
      
      _sessions = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFocusSession(FocusSession session) async {
    try {
      DocumentReference docRef = await _firestore.collection('focus_sessions').add(session.toMap());

      // Reload sessions to include the new one
      await loadFocusSessions(session.userId);
    } catch (e) {
      if (kDebugMode) print('Error adding focus session: $e');
      rethrow;
    }
  }

  Future<void> updateFocusSession(String sessionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('focus_sessions').doc(sessionId).update(data);
      
      // Reload sessions to reflect changes
      await loadFocusSessions(data['userId'] as String);
    } catch (e) {
      if (kDebugMode) print('Error updating focus session: $e');
      rethrow;
    }
  }

  // Get statistics
  Map<String, dynamic> getFocusStats() {
    if (_sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'completedSessions': 0,
        'totalMinutes': 0,
        'averageDuration': 0,
        'completionRate': 0.0,
      };
    }

    final completedSessions = _sessions.where((session) => session.completed);
    final totalMinutes = _sessions.fold(0, (sum, session) => sum + session.durationMinutes);

    return {
      'totalSessions': _sessions.length,
      'completedSessions': completedSessions.length,
      'totalMinutes': totalMinutes,
      'averageDuration': (totalMinutes / _sessions.length).round(),
      'completionRate': _sessions.length > 0 ? completedSessions.length / _sessions.length : 0.0,
    };
  }

  // Get sessions for a specific date range
  List<FocusSession> getSessionsForDateRange(DateTime start, DateTime end) {
    return _sessions
        .where((session) => 
            session.startTime.isAfter(start) && 
            session.startTime.isBefore(end))
        .toList();
  }

  // Get the most recent session
  FocusSession? getMostRecentSession() {
    return _sessions.isNotEmpty ? _sessions.first : null;
  }
}