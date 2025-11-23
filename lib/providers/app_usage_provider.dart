import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUsageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _appUsageData = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get appUsageData => _appUsageData;
  bool get isLoading => _isLoading;

  Future<void> loadAppUsageData(String userId, {int daysBack = 7}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: daysBack));

      QuerySnapshot snapshot = await _firestore
          .collection('app_usage')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .orderBy('timestamp', descending: true)
          .get();

      _appUsageData = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading app usage data: $e');
      _appUsageData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppUsageEntry(String userId, String packageName, String appName, int usageTimeSeconds) async {
    try {
      await _firestore.collection('app_usage').add({
        'userId': userId,
        'packageName': packageName,
        'appName': appName,
        'usageTimeSeconds': usageTimeSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Reload data to reflect changes
      await loadAppUsageData(userId);
    } catch (e) {
      if (kDebugMode) print('Error adding app usage entry: $e');
      rethrow;
    }
  }

  // Get total usage time for a specific app
  int getTotalUsageTimeForApp(String appName) {
    return _appUsageData
        .where((entry) => entry['appName'] == appName)
        .fold(0, (sum, entry) => sum + (entry['usageTimeSeconds'] as int));
  }

  // Get top apps by usage time
  List<Map<String, dynamic>> getTopAppsByUsage({int limit = 10}) {
    final appTotals = <String, int>{};

    for (final entry in _appUsageData) {
      final appName = entry['appName'] as String;
      final usageTime = entry['usageTimeSeconds'] as int;
      
      appTotals[appName] = (appTotals[appName] ?? 0) + usageTime;
    }

    // Convert to list and sort by usage time
    final sortedApps = appTotals.entries
        .map((entry) => {
          'appName': entry.key,
          'totalUsageSeconds': entry.value,
        })
        .toList()
      ..sort((a, b) => (b['totalUsageSeconds'] as int).compareTo(a['totalUsageSeconds'] as int));

    return limit > 0 && sortedApps.length > limit
        ? sortedApps.sublist(0, limit)
        : sortedApps;
  }

  // Get app usage for a specific date
  List<Map<String, dynamic>> getAppUsageForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _appUsageData
        .where((entry) {
          final entryDate = (entry['timestamp'] as Timestamp).toDate();
          return entryDate.isAfter(startOfDay) && entryDate.isBefore(endOfDay);
        })
        .toList();
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    if (_appUsageData.isEmpty) {
      return {
        'totalApps': 0,
        'totalUsageTime': 0,
        'averageDailyUsage': 0,
        'mostUsedApp': '',
      };
    }

    final appTotals = <String, int>{};
    int totalTime = 0;

    for (final entry in _appUsageData) {
      final appName = entry['appName'] as String;
      final usageTime = entry['usageTimeSeconds'] as int;
      
      appTotals[appName] = (appTotals[appName] ?? 0) + usageTime;
      totalTime += usageTime;
    }

    final mostUsedAppEntry = appTotals.entries.firstWhere(
      (entry) => entry.value == appTotals.values.reduce((a, b) => a > b ? a : b),
      orElse: () => MapEntry('', 0),
    );

    return {
      'totalApps': appTotals.keys.length,
      'totalUsageTime': totalTime,
      'averageDailyUsage': totalTime ~/ appTotals.keys.length, // Simplified calculation
      'mostUsedApp': mostUsedAppEntry.key,
      'mostUsedAppTime': mostUsedAppEntry.value,
    };
  }
}