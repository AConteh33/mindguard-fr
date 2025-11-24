import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_usage_platform_service.dart';

class AppUsageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _appUsageData = [];
  bool _isLoading = false;
  bool _hasNativeTracking = false;
  String? _lastError;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get appUsageData => _appUsageData;
  bool get isLoading => _isLoading;
  bool get hasNativeTracking => _hasNativeTracking;
  String? get lastError => _lastError;

  Future<void> loadAppUsageData(String userId, {int daysBack = 7}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Try to get native data first
      final canMonitor = await AppUsagePlatformService.canMonitorUsage();
      _hasNativeTracking = canMonitor;

      if (canMonitor) {
        // Get data from native platform
        final nativeUsage = await AppUsagePlatformService.getAppUsage(daysBack: daysBack);
        
        // Convert to expected format and save to Firestore
        for (final app in nativeUsage) {
          await addAppUsageEntry(
            userId,
            app['packageName'] as String? ?? '',
            app['appName'] as String? ?? '',
            app['usageTimeSeconds'] as int? ?? 0,
          );
        }
        
        // Load from Firestore to get consistent data
        await _loadFromFirestore(userId, daysBack);
      } else {
        // Fallback to Firestore only
        await _loadFromFirestore(userId, daysBack);
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) print('Error loading app usage data: $e');
      _appUsageData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFirestore(String userId, int daysBack) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: daysBack));

    QuerySnapshot snapshot = await _firestore
        .collection('app_usage')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    // Filter by date range in UI instead of query
    final filteredDocs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      return timestamp >= startDate.millisecondsSinceEpoch;
    }).toList();

    _appUsageData = filteredDocs
        .map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
        .toList();
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
        'hasNativeTracking': _hasNativeTracking,
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
      'hasNativeTracking': _hasNativeTracking,
    };
  }

  // Check and request usage stats permission
  Future<bool> checkAndRequestUsageStatsPermission() async {
    try {
      final hasPermission = await AppUsagePlatformService.hasUsageStatsPermission();
      
      if (!hasPermission) {
        await AppUsagePlatformService.requestUsageStatsPermission();
        
        // Wait a bit and check again
        await Future.delayed(const Duration(seconds: 3));
        final nowHasPermission = await AppUsagePlatformService.hasUsageStatsPermission();
        return nowHasPermission;
      }
      
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get real-time usage summary
  Future<Map<String, dynamic>> getRealtimeUsageSummary() async {
    try {
      final summary = await AppUsagePlatformService.getUsageSummary();
      _hasNativeTracking = summary['canMonitor'] == true;
      notifyListeners();
      return summary;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return {
        'hasNativeTracking': false,
        'error': e.toString(),
        ...getUsageStats(),
      };
    }
  }

  // Get top apps from native platform
  Future<List<Map<String, dynamic>>> getTopApps({int limit = 10}) async {
    try {
      if (_hasNativeTracking) {
        return await AppUsagePlatformService.getTopApps(limit: limit);
      } else {
        // Fallback to Firestore data
        return getTopAppsByUsage(limit: limit);
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return getTopAppsByUsage(limit: limit);
    }
  }

  // Refresh data with native integration
  Future<void> refreshWithNativeData(String userId, {int daysBack = 7}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if native tracking is available
      final canMonitor = await AppUsagePlatformService.canMonitorUsage();
      _hasNativeTracking = canMonitor;

      if (canMonitor) {
        // Get fresh data from native platform
        final nativeUsage = await AppUsagePlatformService.getAppUsage(daysBack: daysBack);
        
        // Clear existing data and add fresh data
        _appUsageData.clear();
        
        for (final app in nativeUsage) {
          await addAppUsageEntry(
            userId,
            app['packageName'] as String? ?? '',
            app['appName'] as String? ?? '',
            app['usageTimeSeconds'] as int? ?? 0,
          );
        }
        
        // Reload from Firestore to get consistent data
        await _loadFromFirestore(userId, daysBack);
      } else {
        // Fallback to existing method
        await loadAppUsageData(userId, daysBack: daysBack);
      }
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) print('Error refreshing with native data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}