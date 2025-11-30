import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodProvider with ChangeNotifier {
  List<Map<String, dynamic>> _moodEntries = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;

  Future<void> loadMoodEntries(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .get();

      _moodEntries = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });
    } catch (e) {
      // Handle error appropriately
      if (kDebugMode) print('Error loading mood entries: $e');
      _moodEntries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMoodEntry(String userId, int moodValue, String notes) async {
    try {
      await _firestore.collection('mood_entries').add({
        'userId': userId,
        'moodValue': moodValue,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Reload entries to include the new one
      await loadMoodEntries(userId);
    } catch (e) {
      // Handle error appropriately
      if (kDebugMode) print('Error adding mood entry: $e');
      rethrow;
    }
  }

  // Calculate mood statistics
  double get averageMood {
    if (_moodEntries.isEmpty) return 0.0;
    final sum = _moodEntries.fold(0, (prev, entry) => prev + (entry['moodValue'] as int));
    return sum / _moodEntries.length;
  }

  int get positiveMoodCount {
    return _moodEntries.where((entry) => (entry['moodValue'] as int) >= 4).length;
  }

  int get negativeMoodCount {
    return _moodEntries.where((entry) => (entry['moodValue'] as int) <= 2).length;
  }
  
  int get neutralMoodCount {
    return _moodEntries.where((entry) => (entry['moodValue'] as int) == 3).length;
  }
  
  // Get mood entries for the last 7 days
  List<Map<String, dynamic>> getWeeklyMoodEntries() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _moodEntries
        .where((entry) =>
            entry['timestamp'] != null &&
            (entry['timestamp'] as Timestamp).toDate().isAfter(sevenDaysAgo))
        .toList();
  }

  // Get mood entries for a specific date range
  List<Map<String, dynamic>> getMoodEntriesForDateRange(DateTime start, DateTime end) {
    return _moodEntries
        .where((entry) =>
            entry['timestamp'] != null &&
            (entry['timestamp'] as Timestamp).toDate().isAfter(start) &&
            (entry['timestamp'] as Timestamp).toDate().isBefore(end))
        .toList();
  }

  // Get average mood for a specific period
  double getAverageMoodForPeriod(DateTime start, DateTime end) {
    final entries = getMoodEntriesForDateRange(start, end);
    if (entries.isEmpty) return 0.0;

    final sum = entries.fold(0, (prev, entry) => prev + (entry['moodValue'] as int));
    return sum / entries.length;
  }

  // Get the most recent mood entry
  Map<String, dynamic>? getMostRecentMoodEntry() {
    return _moodEntries.isNotEmpty ? _moodEntries.first : null;
  }
  
  // Get mood trend (improving, declining, stable)
  String getMoodTrend() {
    if (_moodEntries.length < 2) return 'insuffisant';
    
    // Calculate the trend based on the last few entries
    final recentEntries = _moodEntries.take(5).toList();
    if (recentEntries.length < 2) return 'insuffisant';
    
    final initialMood = recentEntries.last['moodValue'] as int;
    final finalMood = recentEntries.first['moodValue'] as int;
    
    if (finalMood > initialMood) return 'amélioration';
    if (finalMood < initialMood) return 'déclin';
    return 'stable';
  }
  
  // Get mood statistics for the week
  Map<String, dynamic> getWeeklyMoodStats() {
    final weeklyEntries = getWeeklyMoodEntries();
    
    if (weeklyEntries.isEmpty) {
      return {
        'average': 0.0,
        'positiveCount': 0,
        'negativeCount': 0,
        'neutralCount': 0,
      };
    }
    
    int sum = 0;
    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;
    
    for (final entry in weeklyEntries) {
      final moodValue = entry['moodValue'] as int;
      sum += moodValue;
      
      if (moodValue >= 4) {
        positiveCount++;
      } else if (moodValue <= 2) {
        negativeCount++;
      } else {
        neutralCount++;
      }
    }
    
    return {
      'average': sum / weeklyEntries.length,
      'positiveCount': positiveCount,
      'negativeCount': negativeCount,
      'neutralCount': neutralCount,
    };
  }
}