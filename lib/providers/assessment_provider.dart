import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentProvider with ChangeNotifier {
  List<Map<String, dynamic>> _assessmentTools = [];
  List<Map<String, dynamic>> _assessmentResults = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get assessmentTools => _assessmentTools;
  List<Map<String, dynamic>> get assessmentResults => _assessmentResults;
  bool get isLoading => _isLoading;

  Future<void> loadAssessmentTools() async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('assessment_tools')
          .orderBy('createdAt', descending: true)
          .get();

      _assessmentTools = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading assessment tools: $e');
      _assessmentTools = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssessmentResults(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('assessment_results')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      _assessmentResults = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading assessment results: $e');
      _assessmentResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAssessmentResult(String userId, String toolId, int score, List<int> answers, Map<String, dynamic> metadata) async {
    try {
      await _firestore.collection('assessment_results').add({
        'userId': userId,
        'toolId': toolId,
        'score': score,
        'answers': answers,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reload results to include the new one
      await loadAssessmentResults(userId);
    } catch (e) {
      if (kDebugMode) print('Error saving assessment result: $e');
      rethrow;
    }
  }

  // Get an assessment tool by ID
  Map<String, dynamic>? getAssessmentToolById(String toolId) {
    try {
      return _assessmentTools.firstWhere((tool) => tool['id'] == toolId);
    } catch (e) {
      return null; // Return null if not found
    }
  }
}