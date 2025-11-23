import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/parental_control_models.dart';
import '../providers/parental_controls_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import 'app_usage_platform_service.dart';

class ScreenTimeMonitoringService {
  static final ScreenTimeMonitoringService _instance = ScreenTimeMonitoringService._internal();
  factory ScreenTimeMonitoringService() => _instance;
  ScreenTimeMonitoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _monitoringTimer;
  Timer? _usageUpdateTimer;
  Timer? _realtimeDataSyncTimer;
  String? _currentChildId;
  String? _currentParentId;
  DateTime? _sessionStartTime;
  String? _currentAppName;
  bool _isMonitoring = false;
  Map<String, DateTime> _appStartTimes = {};
  Map<String, int> _dailyUsage = {};
  DateTime? _lastWarningSent;
  bool _isBlocked = false;
  bool _hasNativeTracking = false;

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get isBlocked => _isBlocked;
  String? get currentChildId => _currentChildId;

  // Start monitoring for a child
  Future<void> startMonitoring({
    required String childId,
    required String parentId,
    required ParentalControlsProvider parentalControlsProvider,
  }) async {
    if (_isMonitoring && _currentChildId == childId) return;

    _currentChildId = childId;
    _currentParentId = parentId;
    _isMonitoring = true;
    _isBlocked = false;
    _sessionStartTime = DateTime.now();
    _lastWarningSent = null;

    // Check if native tracking is available
    _hasNativeTracking = await AppUsagePlatformService.canMonitorUsage();
    if (kDebugMode) print('Native tracking available: $_hasNativeTracking');

    // Start native monitoring if available
    if (_hasNativeTracking) {
      await AppUsagePlatformService.startAppUsageMonitoring(childId);
    }

    // Load today's usage data
    await _loadTodayUsage(childId);

    // Start periodic monitoring (every 30 seconds)
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkLimitsAndNotify(parentalControlsProvider);
    });

    // Start usage tracking (every minute)
    _usageUpdateTimer?.cancel();
    _usageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateUsageData();
    });

    // Start real-time data sync (every 5 minutes)
    _realtimeDataSyncTimer?.cancel();
    _realtimeDataSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _syncRealtimeData();
    });

    if (kDebugMode) print('Started screen time monitoring for child: $childId');
  }

  // Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _usageUpdateTimer?.cancel();
    _realtimeDataSyncTimer?.cancel();
    _isMonitoring = false;
    _currentChildId = null;
    _currentParentId = null;
    _sessionStartTime = null;
    _currentAppName = null;
    _appStartTimes.clear();
    _dailyUsage.clear();
    _isBlocked = false;
    _hasNativeTracking = false;

    // Stop native monitoring
    AppUsagePlatformService.stopAppUsageMonitoring();

    if (kDebugMode) print('Stopped screen time monitoring');
  }

  // Track app usage
  void trackAppUsage(String appName, {bool isForeground = true}) {
    if (!_isMonitoring || _currentChildId == null) return;

    final now = DateTime.now();
    
    if (isForeground) {
      // App is coming to foreground
      if (_currentAppName != null && _currentAppName != appName) {
        // Previous app is going to background
        _recordAppSession(_currentAppName!, now);
      }
      
      _currentAppName = appName;
      _appStartTimes[appName] = now;
      
      if (kDebugMode) print('Started tracking app: $appName');
    } else {
      // App is going to background
      if (_currentAppName == appName) {
        _recordAppSession(appName, now);
        _currentAppName = null;
      }
    }
  }

  // Record app session
  void _recordAppSession(String appName, DateTime endTime) {
    final startTime = _appStartTimes[appName];
    if (startTime == null) return;

    final duration = endTime.difference(startTime);
    final minutes = duration.inMinutes;

    if (minutes > 0) {
      _dailyUsage[appName] = (_dailyUsage[appName] ?? 0) + minutes;
      
      // Save to Firestore
      _saveAppUsage(appName, minutes);
      
      if (kDebugMode) print('Recorded app session: $appName - $minutes minutes');
    }

    _appStartTimes.remove(appName);
  }

  // Load today's usage data
  Future<void> _loadTodayUsage(String childId) async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      DocumentSnapshot doc = await _firestore
          .collection('screen_time_usage')
          .doc('${childId}_$dateString')
          .get();

      if (doc.exists) {
        final usage = ScreenTimeUsage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _dailyUsage = Map<String, int>.from(usage.appUsage);
      } else {
        _dailyUsage = {};
      }
    } catch (e) {
      if (kDebugMode) print('Error loading today usage: $e');
      _dailyUsage = {};
    }
  }

  // Save app usage to Firestore
  Future<void> _saveAppUsage(String appName, int minutes) async {
    if (_currentChildId == null) return;

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${_currentChildId}_$dateString';

      DocumentReference docRef = _firestore.collection('screen_time_usage').doc(docId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot doc = await transaction.get(docRef);
        
        Map<String, int> appUsage = {};
        int totalMinutes = 0;

        if (doc.exists) {
          final usage = ScreenTimeUsage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          appUsage = Map<String, int>.from(usage.appUsage);
          totalMinutes = usage.totalMinutesUsed;
        }

        // Update app usage
        appUsage[appName] = (appUsage[appName] ?? 0) + minutes;
        totalMinutes += minutes;

        // Create time block
        final timeBlock = TimeBlock(
          appName: appName,
          startTime: DateTime.now().subtract(Duration(minutes: minutes)),
          endTime: DateTime.now(),
          durationMinutes: minutes,
        );

        final usageData = {
          'childId': _currentChildId,
          'date': dateString,
          'appUsage': appUsage,
          'totalMinutesUsed': totalMinutes,
          'lastUpdated': Timestamp.now(),
          'timeBlocks': FieldValue.arrayUnion([timeBlock.toMap()]),
        };

        if (doc.exists) {
          transaction.update(docRef, usageData);
        } else {
          transaction.set(docRef, usageData);
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error saving app usage: $e');
    }
  }

  // Check limits and send notifications
  Future<void> _checkLimitsAndNotify(ParentalControlsProvider parentalControlsProvider) async {
    if (!_isMonitoring || _currentChildId == null || _currentParentId == null) return;

    final limit = parentalControlsProvider.screenTimeLimit;
    if (limit == null || !limit.isActive) return;

    final totalUsage = _dailyUsage.values.fold(0, (sum, minutes) => sum + minutes);
    final now = DateTime.now();

    // Check daily limit
    if (totalUsage >= limit.dailyLimitMinutes) {
      if (!_isBlocked) {
        _isBlocked = true;
        await _sendNotification(
          type: 'limit_reached',
          title: 'Limite de temps d\'écran atteinte',
          message: 'L\'enfant a atteint sa limite quotidienne de ${limit.dailyLimitMinutes} minutes.',
          parentalControlsProvider: parentalControlsProvider,
        );
      }
    } else if (parentalControlsProvider.shouldShowDailyWarning(totalUsage)) {
      // Send warning
      if (_lastWarningSent == null || 
          now.difference(_lastWarningSent!).inMinutes > 15) {
        _lastWarningSent = now;
        await _sendNotification(
          type: 'warning',
          title: 'Alerte de temps d\'écran',
          message: 'L\'enfant a utilisé ${totalUsage} minutes sur ${limit.dailyLimitMinutes} minutes autorisées.',
          parentalControlsProvider: parentalControlsProvider,
        );
      }
    } else {
      _isBlocked = false;
    }

    // Check app-specific limits
    if (_currentAppName != null) {
      final appUsage = _dailyUsage[_currentAppName!] ?? 0;
      final appLimit = limit.appLimits[_currentAppName!];
      
      if (appLimit != null) {
        if (appUsage >= appLimit) {
          await _sendNotification(
            type: 'app_blocked',
            title: 'Application bloquée',
            message: 'L\'application $_currentAppName a atteint sa limite de temps.',
            appName: _currentAppName,
            parentalControlsProvider: parentalControlsProvider,
          );
        } else if (parentalControlsProvider.shouldShowAppWarning(_currentAppName!, appUsage)) {
          if (_lastWarningSent == null || 
              now.difference(_lastWarningSent!).inMinutes > 10) {
            _lastWarningSent = now;
            await _sendNotification(
              type: 'warning',
              title: 'Alerte de limite d\'application',
              message: 'L\'application $_currentAppName a utilisé $appUsage minutes sur $appLimit minutes autorisées.',
              appName: _currentAppName,
              parentalControlsProvider: parentalControlsProvider,
            );
          }
        }
      }
    }

    // Check blocked apps
    if (_currentAppName != null && limit.blockedApps.contains(_currentAppName!)) {
      await _sendNotification(
        type: 'app_blocked',
        title: 'Application bloquée',
        message: 'L\'application $_currentAppName est bloquée par les contrôles parentaux.',
        appName: _currentAppName,
        parentalControlsProvider: parentalControlsProvider,
      );
    }

    // Check allowed time ranges
    if (!parentalControlsProvider.isScreenTimeAllowed()) {
      await _sendNotification(
        type: 'time_restricted',
        title: 'Temps d\'écran non autorisé',
        message: 'Le temps d\'écran n\'est pas autorisé à cette heure.',
        parentalControlsProvider: parentalControlsProvider,
      );
    }
  }

  // Send notification
  Future<void> _sendNotification({
    required String type,
    required String title,
    required String message,
    String? appName,
    required ParentalControlsProvider parentalControlsProvider,
  }) async {
    await parentalControlsProvider.createNotification(
      childId: _currentChildId!,
      parentId: _currentParentId!,
      type: type,
      title: title,
      message: message,
      appName: appName,
      data: {
        'totalUsage': _dailyUsage.values.fold(0, (sum, minutes) => sum + minutes),
        'currentApp': _currentAppName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (kDebugMode) print('Sent notification: $title - $message');
  }

  // Update usage data periodically
  Future<void> _updateUsageData() async {
    if (!_isMonitoring || _currentAppName == null) return;

    final now = DateTime.now();
    final startTime = _appStartTimes[_currentAppName!];
    
    if (startTime != null) {
      final duration = now.difference(startTime);
      final minutes = duration.inMinutes;
      
      if (minutes > 0) {
        // Update current session usage
        _dailyUsage[_currentAppName!] = (_dailyUsage[_currentAppName!] ?? 0) + 1;
      }
    }
  }

  // Sync real-time data from native platform
  Future<void> _syncRealtimeData() async {
    if (!_isMonitoring || !_hasNativeTracking || _currentChildId == null) return;

    try {
      // Get today's usage from native platform
      final todayUsage = await AppUsagePlatformService.getTodayAppUsage();
      
      // Update local usage data with native data
      for (final app in todayUsage) {
        final appName = app['appName'] as String;
        final usageTimeSeconds = app['usageTimeSeconds'] as int;
        final usageTimeMinutes = (usageTimeSeconds / 60).round();
        
        if (usageTimeMinutes > 0) {
          _dailyUsage[appName] = usageTimeMinutes;
          
          // Save to Firestore
          await _saveAppUsage(appName, usageTimeMinutes);
        }
      }
      
      if (kDebugMode) print('Synced ${todayUsage.length} apps from native platform');
    } catch (e) {
      if (kDebugMode) print('Error syncing real-time data: $e');
    }
  }

  // Get current usage statistics
  Map<String, dynamic> getCurrentUsageStats() {
    final totalUsage = _dailyUsage.values.fold(0, (sum, minutes) => sum + minutes);
    
    return {
      'totalMinutes': totalUsage,
      'appUsage': Map<String, int>.from(_dailyUsage),
      'currentApp': _currentAppName,
      'sessionDuration': _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!).inMinutes 
          : 0,
      'isBlocked': _isBlocked,
    };
  }

  // Manually add usage (for testing or manual entry)
  Future<void> addManualUsage(String appName, int minutes) async {
    if (!_isMonitoring || _currentChildId == null) return;

    _dailyUsage[appName] = (_dailyUsage[appName] ?? 0) + minutes;
    await _saveAppUsage(appName, minutes);
    
    if (kDebugMode) print('Added manual usage: $appName - $minutes minutes');
  }

  // Reset daily usage (for testing or new day)
  Future<void> resetDailyUsage() async {
    _dailyUsage.clear();
    _appStartTimes.clear();
    _sessionStartTime = DateTime.now();
    _lastWarningSent = null;
    _isBlocked = false;
    
    if (kDebugMode) print('Reset daily usage');
  }

  // Check and request usage stats permission
  Future<bool> checkAndRequestUsageStatsPermission() async {
    try {
      final hasPermission = await AppUsagePlatformService.hasUsageStatsPermission();
      
      if (!hasPermission) {
        // Request permission (will open settings)
        await AppUsagePlatformService.requestUsageStatsPermission();
        
        // Wait a bit and check again
        await Future.delayed(const Duration(seconds: 3));
        final nowHasPermission = await AppUsagePlatformService.hasUsageStatsPermission();
        
        return nowHasPermission;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Error checking/requesting permission: $e');
      return false;
    }
  }

  // Get real-time usage summary
  Future<Map<String, dynamic>> getRealtimeUsageSummary() async {
    if (!_hasNativeTracking) {
      return {
        'hasNativeTracking': false,
        'totalMinutes': _dailyUsage.values.fold(0, (sum, minutes) => sum + minutes),
        'appUsage': Map<String, int>.from(_dailyUsage),
        'currentApp': _currentAppName,
        'isMonitoring': _isMonitoring,
      };
    }

    try {
      final nativeSummary = await AppUsagePlatformService.getUsageSummary();
      
      return {
        'hasNativeTracking': true,
        'totalMinutes': nativeSummary['todayTotalMinutes'] ?? 0,
        'weeklyTotalMinutes': nativeSummary['weeklyTotalMinutes'] ?? 0,
        'appsCount': nativeSummary['todayAppsCount'] ?? 0,
        'mostUsedApp': nativeSummary['mostUsedApp'] ?? '',
        'mostUsedAppMinutes': nativeSummary['mostUsedAppMinutes'] ?? 0,
        'topApps': nativeSummary['topApps'] ?? [],
        'canMonitor': nativeSummary['canMonitor'] ?? false,
        'currentApp': _currentAppName,
        'isMonitoring': _isMonitoring,
        'isBlocked': _isBlocked,
        'lastUpdated': nativeSummary['lastUpdated'],
      };
    } catch (e) {
      if (kDebugMode) print('Error getting real-time usage summary: $e');
      return {
        'hasNativeTracking': false,
        'error': e.toString(),
        'totalMinutes': _dailyUsage.values.fold(0, (sum, minutes) => sum + minutes),
        'appUsage': Map<String, int>.from(_dailyUsage),
        'currentApp': _currentAppName,
        'isMonitoring': _isMonitoring,
      };
    }
  }
}
