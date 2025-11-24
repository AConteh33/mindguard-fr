import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../providers/parental_controls_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../services/parental_notification_service.dart';
import '../services/app_blocking_service.dart';
import '../services/screen_time_monitoring_service.dart';
import '../models/parental_control_models.dart';

class RealtimeParentalService {
  static final RealtimeParentalService _instance = RealtimeParentalService._internal();
  factory RealtimeParentalService() => _instance;
  RealtimeParentalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, StreamSubscription> _subscriptions = {};
  bool _isInitialized = false;

  // Initialize real-time updates
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    if (kDebugMode) print('Realtime parental service initialized');
  }

  // Start listening to parental control updates for a child
  void startListeningToChildControls({
    required String childId,
    required Function(ScreenTimeLimit) onControlsUpdated,
  }) {
    // Stop existing subscription for this child
    stopListeningToChildControls(childId);

    _subscriptions[childId] = _firestore
        .collection('screen_time_limits')
        .where('childId', isEqualTo: childId)
        .snapshots()
        .listen((snapshot) {
      // Filter active limits in UI instead of query
      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }).toList();
      
      if (activeDocs.isNotEmpty) {
        final doc = activeDocs.first;
        final limit = ScreenTimeLimit.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        onControlsUpdated(limit);
        
        if (kDebugMode) print('Child controls updated for: $childId');
      }
    });
  }

  // Stop listening to child controls
  void stopListeningToChildControls(String childId) {
    final subscription = _subscriptions.remove(childId);
    subscription?.cancel();
  }

  // Start listening to notifications for parent
  void startListeningToNotifications({
    required String parentId,
    required Function(List<ParentalControlNotification>) onNotificationsUpdated,
  }) {
    final subscriptionKey = 'notifications_$parentId';
    
    // Stop existing subscription
    _subscriptions[subscriptionKey]?.cancel();

    _subscriptions[subscriptionKey] = _firestore
        .collection('parental_notifications')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => ParentalControlNotification.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
      
      onNotificationsUpdated(notifications);
      
      if (kDebugMode) print('Notifications updated for parent: $parentId');
    });
  }

  // Stop listening to notifications
  void stopListeningToNotifications(String parentId) {
    final subscriptionKey = 'notifications_$parentId';
    final subscription = _subscriptions.remove(subscriptionKey);
    subscription?.cancel();
  }

  // Start listening to screen time usage for child
  void startListeningToUsage({
    required String childId,
    required Function(Map<String, dynamic>) onUsageUpdated,
  }) {
    final subscriptionKey = 'usage_$childId';
    
    // Stop existing subscription
    _subscriptions[subscriptionKey]?.cancel();

    // Listen to today's usage data
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docId = '${childId}_$dateString';

    _subscriptions[subscriptionKey] = _firestore
        .collection('screen_time_usage')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final usage = ScreenTimeUsage.fromMap(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
        
        onUsageUpdated({
          'totalMinutes': usage.totalMinutesUsed,
          'appUsage': usage.appUsage,
          'lastUpdated': usage.lastUpdated,
          'timeBlocks': usage.timeBlocks,
        });
        
        if (kDebugMode) print('Usage updated for child: $childId');
      }
    });
  }

  // Stop listening to usage
  void stopListeningToUsage(String childId) {
    final subscriptionKey = 'usage_$childId';
    final subscription = _subscriptions.remove(subscriptionKey);
    subscription?.cancel();
  }

  // Send real-time update to parent when child reaches limit
  Future<void> sendLimitReachedUpdate({
    required String childId,
    required String parentId,
    required String type, // 'daily' or 'app'
    required String? appName,
    required int usedMinutes,
    required int limitMinutes,
  }) async {
    try {
      // Create notification
      await _firestore.collection('parental_notifications').add({
        'childId': childId,
        'parentId': parentId,
        'type': type == 'daily' ? 'limit_reached' : 'app_limit_reached',
        'title': type == 'daily' 
            ? 'Limite quotidienne atteinte'
            : 'Limite d\'application atteinte',
        'message': type == 'daily'
            ? 'L\'enfant a atteint sa limite quotidienne de $limitMinutes minutes.'
            : '$appName: Limite de $limitMinutes minutes atteinte.',
        'appName': appName,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'data': {
          'usedMinutes': usedMinutes,
          'limitMinutes': limitMinutes,
          'type': type,
        },
      });

      // Send instant notification to parent's device
      await _sendPushNotification(
        parentId: parentId,
        title: type == 'daily' 
            ? '🚫 Limite quotidienne atteinte'
            : '🚫 Limite d\'application atteinte',
        message: type == 'daily'
            ? 'Votre enfant a atteint sa limite de temps d\'écran aujourd\'hui.'
            : 'Votre enfant a atteint la limite pour $appName.',
      );

      if (kDebugMode) print('Sent limit reached update to parent: $parentId');
    } catch (e) {
      if (kDebugMode) print('Error sending limit reached update: $e');
    }
  }

  // Send real-time warning to parent
  Future<void> sendWarningUpdate({
    required String childId,
    required String parentId,
    required String type, // 'daily' or 'app'
    required String? appName,
    required int usedMinutes,
    required int limitMinutes,
  }) async {
    try {
      // Create notification
      await _firestore.collection('parental_notifications').add({
        'childId': childId,
        'parentId': parentId,
        'type': 'warning',
        'title': '⚠️ Alertes de temps d\'écran',
        'message': type == 'daily'
            ? 'L\'enfant a utilisé $usedMinutes minutes sur $limitMinutes minutes autorisées.'
            : '$appName: $usedMinutes minutes utilisées sur $limitMinutes minutes autorisées.',
        'appName': appName,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'data': {
          'usedMinutes': usedMinutes,
          'limitMinutes': limitMinutes,
          'type': type,
        },
      });

      // Send instant notification to parent's device
      await _sendPushNotification(
        parentId: parentId,
        title: '⚠️ Alerte de temps d\'écran',
        message: type == 'daily'
            ? 'Votre enfant approche de sa limite quotidienne.'
            : 'Votre enfant approche de la limite pour $appName.',
      );

      if (kDebugMode) print('Sent warning update to parent: $parentId');
    } catch (e) {
      if (kDebugMode) print('Error sending warning update: $e');
    }
  }

  // Send real-time app blocked update
  Future<void> sendAppBlockedUpdate({
    required String childId,
    required String parentId,
    required String appName,
    required String reason,
  }) async {
    try {
      // Create notification
      await _firestore.collection('parental_notifications').add({
        'childId': childId,
        'parentId': parentId,
        'type': 'app_blocked',
        'title': '🚫 Application bloquée',
        'message': '$appName a été bloquée: $reason',
        'appName': appName,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'data': {
          'appName': appName,
          'reason': reason,
        },
      });

      // Send instant notification to parent's device
      await _sendPushNotification(
        parentId: parentId,
        title: '🚫 Application bloquée',
        message: '$appName a été bloquée sur l\'appareil de votre enfant.',
      );

      if (kDebugMode) print('Sent app blocked update to parent: $parentId');
    } catch (e) {
      if (kDebugMode) print('Error sending app blocked update: $e');
    }
  }

  // Send push notification (mock implementation)
  Future<void> _sendPushNotification({
    required String parentId,
    required String title,
    required String message,
  }) async {
    // In a real implementation, this would use Firebase Cloud Messaging (FCM)
    // For now, we'll just log it
    if (kDebugMode) {
      print('Push notification to $parentId: $title - $message');
    }

    // You could integrate with FCM here:
    // await FirebaseMessaging.instance.sendMessage(
    //   to: getParentDeviceToken(parentId),
    //   data: {
    //     'title': title,
    //     'body': message,
    //     'type': 'parental_control',
    //   },
    // );
  }

  // Send real-time update to child when parent changes controls
  Future<void> sendControlUpdateToChild({
    required String childId,
    required ScreenTimeLimit newLimit,
  }) async {
    try {
      // Update child's device with new controls
      await _firestore.collection('child_control_updates').add({
        'childId': childId,
        'limit': newLimit.toMap(),
        'timestamp': Timestamp.now(),
        'type': 'control_update',
      });

      // This would trigger a real-time update on the child's device
      if (kDebugMode) print('Sent control update to child: $childId');
    } catch (e) {
      if (kDebugMode) print('Error sending control update to child: $e');
    }
  }

  // Child listens for control updates
  void startListeningToControlUpdates({
    required String childId,
    required Function(ScreenTimeLimit) onControlUpdate,
  }) {
    final subscriptionKey = 'control_updates_$childId';
    
    // Stop existing subscription
    _subscriptions[subscriptionKey]?.cancel();

    _subscriptions[subscriptionKey] = _firestore
        .collection('child_control_updates')
        .where('childId', isEqualTo: childId)
        .orderBy('timestamp', descending: true)
        .limit(10) // Get more docs to filter in UI
        .snapshots()
        .listen((snapshot) {
      // Filter by type in UI instead of query
      final controlUpdates = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['type'] == 'control_update';
      }).toList();
      
      if (controlUpdates.isNotEmpty) {
        final doc = controlUpdates.first;
        final limitData = doc['limit'] as Map<String, dynamic>;
        final limit = ScreenTimeLimit.fromMap(limitData, doc.id);
        onControlUpdate(limit);
        
        if (kDebugMode) print('Received control update for child: $childId');
      }
    });
  }

  // Stop listening to control updates
  void stopListeningToControlUpdates(String childId) {
    final subscriptionKey = 'control_updates_$childId';
    final subscription = _subscriptions.remove(subscriptionKey);
    subscription?.cancel();
  }

  // Get real-time connection status
  Stream<bool> getConnectionStatus() {
    return Stream.periodic(const Duration(seconds: 5), (_) => true);
  }

  // Dispose all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isInitialized = false;
    
    if (kDebugMode) print('Realtime parental service disposed');
  }
}

// Widget to display real-time status
class RealtimeStatusWidget extends StatefulWidget {
  const RealtimeStatusWidget({super.key});

  @override
  State<RealtimeStatusWidget> createState() => _RealtimeStatusWidgetState();
}

class _RealtimeStatusWidgetState extends State<RealtimeStatusWidget> {
  bool _isConnected = false;
  final RealtimeParentalService _realtimeService = RealtimeParentalService();

  @override
  void initState() {
    super.initState();
    _realtimeService.initialize();
    _listenToConnectionStatus();
  }

  void _listenToConnectionStatus() {
    _realtimeService.getConnectionStatus().listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Connecté en temps réel' : 'Hors ligne',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}

// Service to manage real-time updates for the entire app
class AppRealtimeManager {
  static final AppRealtimeManager _instance = AppRealtimeManager._internal();
  factory AppRealtimeManager() => _instance;
  AppRealtimeManager._internal();

  final RealtimeParentalService _realtimeService = RealtimeParentalService();
  bool _isInitialized = false;

  // Initialize for parent
  void initializeForParent({
    required String parentId,
    required Function(List<ParentalControlNotification>) onNotificationsUpdated,
  }) {
    if (_isInitialized) return;
    
    _realtimeService.initialize();
    _realtimeService.startListeningToNotifications(
      parentId: parentId,
      onNotificationsUpdated: onNotificationsUpdated,
    );
    
    _isInitialized = true;
  }

  // Initialize for child
  void initializeForChild({
    required String childId,
    required String parentId,
    required Function(ScreenTimeLimit) onControlsUpdated,
    required Function(Map<String, dynamic>) onUsageUpdated,
  }) {
    if (_isInitialized) return;
    
    _realtimeService.initialize();
    _realtimeService.startListeningToChildControls(
      childId: childId,
      onControlsUpdated: onControlsUpdated,
    );
    _realtimeService.startListeningToUsage(
      childId: childId,
      onUsageUpdated: onUsageUpdated,
    );
    _realtimeService.startListeningToControlUpdates(
      childId: childId,
      onControlUpdate: onControlsUpdated,
    );
    
    _isInitialized = true;
  }

  // Send updates from child to parent
  Future<void> sendChildUpdateToParent({
    required String childId,
    required String parentId,
    required String updateType,
    Map<String, dynamic>? data,
  }) async {
    switch (updateType) {
      case 'warning':
        await _realtimeService.sendWarningUpdate(
          childId: childId,
          parentId: parentId,
          type: data?['type'] ?? 'daily',
          appName: data?['appName'],
          usedMinutes: data?['usedMinutes'] ?? 0,
          limitMinutes: data?['limitMinutes'] ?? 0,
        );
        break;
        
      case 'limit_reached':
        await _realtimeService.sendLimitReachedUpdate(
          childId: childId,
          parentId: parentId,
          type: data?['type'] ?? 'daily',
          appName: data?['appName'],
          usedMinutes: data?['usedMinutes'] ?? 0,
          limitMinutes: data?['limitMinutes'] ?? 0,
        );
        break;
        
      case 'app_blocked':
        await _realtimeService.sendAppBlockedUpdate(
          childId: childId,
          parentId: parentId,
          appName: data?['appName'] ?? '',
          reason: data?['reason'] ?? '',
        );
        break;
    }
  }

  // Send updates from parent to child
  Future<void> sendParentUpdateToChild({
    required String childId,
    required ScreenTimeLimit newLimit,
  }) async {
    await _realtimeService.sendControlUpdateToChild(
      childId: childId,
      newLimit: newLimit,
    );
  }

  // Dispose
  void dispose() {
    _realtimeService.dispose();
    _isInitialized = false;
  }
}
