import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class AppUsagePlatformService {
  static const platform = MethodChannel('com.example.mindguard_fr/app_usage');
  
  /// Check if usage stats permission is granted
  static Future<bool> hasUsageStatsPermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod('hasUsageStatsPermission');
      return hasPermission;
    } catch (e) {
      if (kDebugMode) print('Error checking usage stats permission: $e');
      return false;
    }
  }
  
  /// Request usage stats permission (opens settings)
  static Future<void> requestUsageStatsPermission() async {
    try {
      await platform.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      if (kDebugMode) print('Error requesting usage stats permission: $e');
    }
  }
  
  /// Get app usage statistics for the specified number of days
  static Future<List<Map<String, dynamic>>> getAppUsage({int daysBack = 7}) async {
    try {
      final String usageDataJson = await platform.invokeMethod('getAppUsage', {'daysBack': daysBack});
      final List<dynamic> usageData = jsonDecode(usageDataJson);
      
      return usageData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting app usage: $e');
      return [];
    }
  }
  
  /// Get top apps by usage time
  static Future<List<Map<String, dynamic>>> getTopApps({int limit = 10}) async {
    try {
      final String topAppsJson = await platform.invokeMethod('getTopApps', {'limit': limit});
      final List<dynamic> topApps = jsonDecode(topAppsJson);
      
      return topApps.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting top apps: $e');
      return [];
    }
  }
  
  /// Start app usage monitoring service
  static Future<void> startAppUsageMonitoring(String userId) async {
    try {
      await platform.invokeMethod('startAppUsageMonitoring', {'userId': userId});
      if (kDebugMode) print('App usage monitoring started for user: $userId');
    } catch (e) {
      if (kDebugMode) print('Error starting app usage monitoring: $e');
    }
  }
  
  /// Stop app usage monitoring service
  static Future<void> stopAppUsageMonitoring() async {
    try {
      await platform.invokeMethod('stopAppUsageMonitoring');
      if (kDebugMode) print('App usage monitoring stopped');
    } catch (e) {
      if (kDebugMode) print('Error stopping app usage monitoring: $e');
    }
  }
  
  /// Get today's app usage data
  static Future<List<Map<String, dynamic>>> getTodayAppUsage() async {
    return await getAppUsage(daysBack: 1);
  }
  
  /// Get weekly app usage data
  static Future<List<Map<String, dynamic>>> getWeeklyAppUsage() async {
    return await getAppUsage(daysBack: 7);
  }
  
  /// Get monthly app usage data
  static Future<List<Map<String, dynamic>>> getMonthlyAppUsage() async {
    return await getAppUsage(daysBack: 30);
  }
  
  /// Get total screen time for today in minutes
  static Future<int> getTodayScreenTimeMinutes() async {
    try {
      final usageData = await getTodayAppUsage();
      final totalSeconds = usageData.fold<int>(0, (sum, app) => sum + (app['usageTimeSeconds'] as int? ?? 0));
      return (totalSeconds / 60).round();
    } catch (e) {
      if (kDebugMode) print('Error getting today screen time: $e');
      return 0;
    }
  }
  
  /// Get total screen time for this week in minutes
  static Future<int> getWeeklyScreenTimeMinutes() async {
    try {
      final usageData = await getWeeklyAppUsage();
      final totalSeconds = usageData.fold<int>(0, (sum, app) => sum + (app['usageTimeSeconds'] as int? ?? 0));
      return (totalSeconds / 60).round();
    } catch (e) {
      if (kDebugMode) print('Error getting weekly screen time: $e');
      return 0;
    }
  }
  
  /// Get app usage for a specific app
  static Future<Map<String, dynamic>?> getAppUsageForPackage(String packageName) async {
    try {
      final usageData = await getAppUsage(daysBack: 7);
      for (final app in usageData) {
        if (app['packageName'] == packageName) {
          return app;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting app usage for package: $e');
      return null;
    }
  }
  
  /// Check if the app can monitor usage (permission + compatibility)
  static Future<bool> canMonitorUsage() async {
    try {
      // Check if we're on Android
      if (defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      
      // Check permission
      final hasPermission = await hasUsageStatsPermission();
      if (!hasPermission) {
        return false;
      }
      
      // Try to get some data to verify functionality
      final testData = await getAppUsage(daysBack: 1);
      return testData.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Error checking monitoring capability: $e');
      return false;
    }
  }
  
  /// Get usage summary for dashboard
  static Future<Map<String, dynamic>> getUsageSummary() async {
    try {
      final todayUsage = await getTodayAppUsage();
      final weeklyUsage = await getWeeklyAppUsage();
      final topApps = await getTopApps(limit: 5);
      
      // Calculate total times
      final todayTotalSeconds = todayUsage.fold<int>(0, (sum, app) => sum + (app['usageTimeSeconds'] as int? ?? 0));
      final weeklyTotalSeconds = weeklyUsage.fold<int>(0, (sum, app) => sum + (app['usageTimeSeconds'] as int? ?? 0));
      
      // Get most used app
      String mostUsedApp = '';
      int mostUsedTime = 0;
      if (topApps.isNotEmpty) {
        mostUsedApp = topApps.first['appName'] as String? ?? '';
        mostUsedTime = topApps.first['usageTimeSeconds'] as int? ?? 0;
      }
      
      return {
        'todayTotalMinutes': (todayTotalSeconds / 60).round(),
        'weeklyTotalMinutes': (weeklyTotalSeconds / 60).round(),
        'todayAppsCount': todayUsage.length,
        'weeklyAppsCount': weeklyUsage.length,
        'mostUsedApp': mostUsedApp,
        'mostUsedAppMinutes': (mostUsedTime / 60).round(),
        'topApps': topApps,
        'canMonitor': await canMonitorUsage(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('Error getting usage summary: $e');
      return {
        'todayTotalMinutes': 0,
        'weeklyTotalMinutes': 0,
        'todayAppsCount': 0,
        'weeklyAppsCount': 0,
        'mostUsedApp': '',
        'mostUsedAppMinutes': 0,
        'topApps': <Map<String, dynamic>>[],
        'canMonitor': false,
        'lastUpdated': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}
