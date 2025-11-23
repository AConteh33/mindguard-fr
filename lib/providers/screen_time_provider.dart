import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScreenTimeProvider with ChangeNotifier {
  Map<String, dynamic>? _screenTimeData;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? get screenTimeData => _screenTimeData;
  bool get isLoading => _isLoading;

  Future<void> loadScreenTimeData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('screen_time').doc(userId).get();

      if (docSnapshot.exists) {
        _screenTimeData = docSnapshot.data() as Map<String, dynamic>?;
      } else {
        // Document doesn't exist, initialize with default structure
        _screenTimeData = {
          'daily': <String, dynamic>{},
          'weekly': <String, dynamic>{},
          'appUsage': <String, dynamic>{},
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }
    } catch (e) {
      // Handle error appropriately
      if (kDebugMode) print('Error loading screen time data: $e');
      _screenTimeData = {
        'daily': <String, dynamic>{},
        'weekly': <String, dynamic>{},
        'appUsage': <String, dynamic>{},
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateScreenTime(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('screen_time').doc(userId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Reload data to reflect changes
      await loadScreenTimeData(userId);
    } catch (e) {
      // Handle error appropriately
      if (kDebugMode) print('Error updating screen time: $e');
      rethrow;
    }
  }

  // Get today's screen time
  String getTodayScreenTime() {
    if (_screenTimeData == null) return '0h 0m';
    
    final dailyData = _screenTimeData!['daily'] as Map<String, dynamic>?;
    if (dailyData == null) return '0h 0m';
    
    final today = DateTime.now().toString().split(' ')[0];
    final todayData = dailyData[today] as Map<String, dynamic>?;
    
    if (todayData == null) return '0h 0m';
    
    final minutes = todayData['minutes'] as int? ?? 0;
    final hours = (minutes ~/ 60);
    final remainingMinutes = minutes % 60;
    
    return '${hours}h ${remainingMinutes}m';
  }

  // Get weekly average screen time
  double getWeeklyAverage() {
    if (_screenTimeData == null) return 0.0;
    
    final dailyData = _screenTimeData!['daily'] as Map<String, dynamic>?;
    if (dailyData == null) return 0.0;
    
    int totalMinutes = 0;
    int dayCount = 0;
    
    for (final entry in dailyData.entries) {
      final dayData = entry.value as Map<String, dynamic>?;
      if (dayData != null) {
        final minutes = dayData['minutes'] as int? ?? 0;
        totalMinutes += minutes;
        dayCount++;
      }
    }
    
    return dayCount > 0 ? (totalMinutes / dayCount) / 60.0 : 0.0; // Return in hours
  }

  // Get most used app
  String getMostUsedApp() {
    if (_screenTimeData == null) return 'Aucune donnée';

    final appUsage = _screenTimeData!['appUsage'] as Map<String, dynamic>?;
    if (appUsage == null || appUsage.isEmpty) return 'Aucune donnée';

    String mostUsedApp = '';
    int maxMinutes = 0;

    for (final entry in appUsage.entries) {
      final minutes = entry.value as int? ?? 0;
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
        mostUsedApp = entry.key;
      }
    }

    return mostUsedApp.isEmpty ? 'Aucune donnée' : mostUsedApp;
  }

  // Get app usage sorted by time
  List<Map<String, dynamic>> getTopAppsByUsage([int limit = 10]) {
    if (_screenTimeData == null) return [];

    final appUsage = _screenTimeData!['appUsage'] as Map<String, dynamic>?;
    if (appUsage == null || appUsage.isEmpty) return [];

    // Convert map to list of maps and sort by usage time
    final appList = <Map<String, dynamic>>[];
    appUsage.forEach((appName, minutes) {
      appList.add({
        'appName': appName,
        'minutes': minutes as int? ?? 0,
      });
    });

    // Sort by minutes in descending order
    appList.sort((a, b) => (b['minutes'] as int).compareTo(a['minutes'] as int));

    // Return the requested number of top apps
    return appList.length > limit ? appList.sublist(0, limit) : appList;
  }

  // Add a method to update app usage time
  Future<void> addAppUsageTime(String appId, String appName, int minutes) async {
    if (_screenTimeData == null) {
      await loadScreenTimeData('default_user_id'); // This would be the actual user ID
    }

    final updatedData = Map<String, dynamic>.from(_screenTimeData ?? {});

    // Initialize appUsage if it doesn't exist
    if (updatedData['appUsage'] == null) {
      updatedData['appUsage'] = <String, int>{};
    }

    final appUsage = updatedData['appUsage'] as Map<String, dynamic>;
    final currentMinutes = appUsage[appName] as int? ?? 0;
    appUsage[appName] = currentMinutes + minutes;

    // Update the provider
    _screenTimeData = updatedData;
    notifyListeners();

    // In a real implementation, we'd also update Firestore
    // await updateScreenTime(userId, updatedData);
  }

  // Get screen time for the last 7 days (for chart)
  List<double> getWeeklyScreenTime() {
    if (_screenTimeData == null) return List.filled(7, 0.0);
    
    final dailyData = _screenTimeData!['daily'] as Map<String, dynamic>?;
    if (dailyData == null) return List.filled(7, 0.0);
    
    final result = List.filled(7, 0.0);
    
    // Get the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final dayData = dailyData[dateStr] as Map<String, dynamic>?;
      if (dayData != null) {
        final minutes = dayData['minutes'] as int? ?? 0;
        result[6 - i] = minutes / 60.0; // Convert to hours
      }
    }
    
    return result;
  }
  
  // Update screen time for today
  Future<void> updateTodayScreenTime(int minutes) async {
    if (_screenTimeData == null) {
      await loadScreenTimeData('default_user_id');
    }
    
    final today = DateTime.now().toString().split(' ')[0];
    final updatedData = Map<String, dynamic>.from(_screenTimeData ?? {});
    
    if (updatedData['daily'] == null) {
      updatedData['daily'] = <String, dynamic>{};
    }
    
    final dailyData = updatedData['daily'] as Map<String, dynamic>;
    final todayData = dailyData[today] ?? <String, dynamic>{};
    
    // Update minutes for today
    final currentMinutes = todayData['minutes'] as int? ?? 0;
    todayData['minutes'] = currentMinutes + minutes;
    
    dailyData[today] = todayData;
    
    // Update the provider
    _screenTimeData = updatedData;
    notifyListeners();
  }
}