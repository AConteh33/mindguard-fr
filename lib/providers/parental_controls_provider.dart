import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parental_control_models.dart';
import '../providers/auth_provider.dart';

class ParentalControlsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  ScreenTimeLimit? _screenTimeLimit;
  List<ParentalControlNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  ScreenTimeLimit? get screenTimeLimit => _screenTimeLimit;
  List<ParentalControlNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get unread notifications count
  int get unreadNotificationsCount => 
      _notifications.where((notification) => !notification.isRead).length;

  // Load screen time limits for a child
  Future<void> loadScreenTimeLimit(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('screen_time_limits')
          .where('childId', isEqualTo: childId)
          .get();

      // Filter active limits in UI instead of query
      final activeLimits = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }).toList();

      if (activeLimits.isNotEmpty) {
        final doc = activeLimits.first;
        _screenTimeLimit = ScreenTimeLimit.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      } else {
        _screenTimeLimit = null;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des limites: $e';
      if (kDebugMode) print('Error loading screen time limit: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or update screen time limits
  Future<void> saveScreenTimeLimit(ScreenTimeLimit limit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (limit.id.isEmpty) {
        // Create new limit
        DocumentReference docRef = await _firestore
            .collection('screen_time_limits')
            .add(limit.toMap());
        
        final newLimit = limit.copyWith(id: docRef.id);
        _screenTimeLimit = newLimit;
      } else {
        // Update existing limit
        await _firestore
            .collection('screen_time_limits')
            .doc(limit.id)
            .update(limit.copyWith(updatedAt: DateTime.now()).toMap());
        
        _screenTimeLimit = limit;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la sauvegarde des limites: $e';
      if (kDebugMode) print('Error saving screen time limit: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete screen time limit
  Future<void> deleteScreenTimeLimit(String limitId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore
          .collection('screen_time_limits')
          .doc(limitId)
          .update({'isActive': false});
      
      if (_screenTimeLimit?.id == limitId) {
        _screenTimeLimit = null;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression des limites: $e';
      if (kDebugMode) print('Error deleting screen time limit: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notifications for parent
  Future<void> loadNotifications(String parentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('parental_notifications')
          .where('parentId', isEqualTo: parentId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => ParentalControlNotification.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des notifications: $e';
      if (kDebugMode) print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('parental_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final unreadNotifications = _notifications.where((n) => !n.isRead);
    
    for (final notification in unreadNotifications) {
      await markNotificationAsRead(notification.id);
    }
  }

  // Create notification
  Future<void> createNotification({
    required String childId,
    required String parentId,
    required String type,
    required String title,
    required String message,
    String? appName,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = ParentalControlNotification(
        id: '', // Will be assigned by Firestore
        childId: childId,
        parentId: parentId,
        type: type,
        title: title,
        message: message,
        appName: appName,
        timestamp: DateTime.now(),
        data: data ?? {},
      );

      await _firestore
          .collection('parental_notifications')
          .add(notification.toMap());
    } catch (e) {
      if (kDebugMode) print('Error creating notification: $e');
    }
  }

  // Check if app is blocked
  bool isAppBlocked(String appName) {
    if (_screenTimeLimit == null) return false;
    return _screenTimeLimit!.blockedApps.contains(appName);
  }

  // Check if app limit is exceeded
  bool isAppLimitExceeded(String appName, int currentUsageMinutes) {
    if (_screenTimeLimit == null) return false;
    
    final appLimit = _screenTimeLimit!.appLimits[appName];
    if (appLimit == null) return false;
    
    return currentUsageMinutes >= appLimit;
  }

  // Check if daily limit is exceeded
  bool isDailyLimitExceeded(int totalUsageMinutes) {
    if (_screenTimeLimit == null) return false;
    return totalUsageMinutes >= _screenTimeLimit!.dailyLimitMinutes;
  }

  // Get warning threshold for daily limit
  int getDailyWarningThreshold() {
    if (_screenTimeLimit == null) return 15;
    return _screenTimeLimit!.warningThresholdMinutes;
  }

  // Check if should show warning for daily limit
  bool shouldShowDailyWarning(int totalUsageMinutes) {
    if (_screenTimeLimit == null) return false;
    
    final threshold = _screenTimeLimit!.dailyLimitMinutes - _screenTimeLimit!.warningThresholdMinutes;
    return totalUsageMinutes >= threshold && totalUsageMinutes < _screenTimeLimit!.dailyLimitMinutes;
  }

  // Check if should show warning for app limit
  bool shouldShowAppWarning(String appName, int currentUsageMinutes) {
    if (_screenTimeLimit == null) return false;
    
    final appLimit = _screenTimeLimit!.appLimits[appName];
    if (appLimit == null) return false;
    
    final threshold = appLimit - _screenTimeLimit!.warningThresholdMinutes;
    return currentUsageMinutes >= threshold && currentUsageMinutes < appLimit;
  }

  // Check if screen time is allowed at current time
  bool isScreenTimeAllowed() {
    if (_screenTimeLimit == null || _screenTimeLimit!.allowedTimeRanges.isEmpty) {
      return true; // No time restrictions
    }

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final range in _screenTimeLimit!.allowedTimeRanges) {
      if (range.contains('-')) {
        final parts = range.split('-');
        if (parts.length == 2) {
          final startTime = parts[0].trim();
          final endTime = parts[1].trim();
          
          if (_isTimeInRange(currentTime, startTime, endTime)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }

  // Helper method to check if time is in range
  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    final current = _parseTime(currentTime);
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start <= end) {
      return current >= start && current <= end;
    } else {
      // Overnight range (e.g., 22:00-06:00)
      return current >= start || current <= end;
    }
  }

  // Helper method to parse time string to minutes
  int _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _screenTimeLimit = null;
    _notifications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
