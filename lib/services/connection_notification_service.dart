import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/auth_provider.dart';

class ConnectionNotificationService {
  static final ConnectionNotificationService _instance = ConnectionNotificationService._internal();
  factory ConnectionNotificationService() => _instance;
  ConnectionNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _connectionRequestsSubscription;
  BuildContext? _context;
  Set<String> _notifiedRequests = <String>{}; // Track already notified requests

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions for Android
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'connection_requests',
        'Connection Requests',
        description: 'Notifications for parent-child connection requests',
        importance: Importance.high,
      ),
    );
  }

  void startListeningForConnectionRequests(String childId, {VoidCallback? onNewRequest}) {
    print('DEBUG: Starting to listen for connection requests for childId: $childId');
    
    if (_connectionRequestsSubscription != null) {
      _connectionRequestsSubscription!.cancel();
    }

    _connectionRequestsSubscription = _firestore
        .collection('connection_requests')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      print('DEBUG: Received snapshot with ${snapshot.docChanges.length} changes');
      
      // Check for new requests (simple implementation)
      if (snapshot.docChanges.isNotEmpty) {
        for (final change in snapshot.docChanges) {
          print('DEBUG: Document change type: ${change.type}');
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final requestId = change.doc.id;
            
            print('DEBUG: New request detected - requestId: $requestId, data: $data');
            
            // Only show notification if we haven't notified for this request yet
            if (!_notifiedRequests.contains(requestId)) {
              print('DEBUG: Showing notifications for new request');
              _notifiedRequests.add(requestId);
              _showConnectionNotification(data);
              _showPopupNotification(data);
              onNewRequest?.call();
            } else {
              print('DEBUG: Request already notified, skipping');
            }
          }
        }
      }
    });
  }

  void stopListening() {
    _connectionRequestsSubscription?.cancel();
    _connectionRequestsSubscription = null;
    _notifiedRequests.clear();
  }

  void _showPopupNotification(Map<String, dynamic> requestData) {
    print('DEBUG: Attempting to show popup notification');
    print('DEBUG: Context is available: ${_context != null}');
    
    if (_context == null) {
      print('DEBUG: No context available for popup notification');
      return;
    }
    
    final parentName = requestData['parentName'] as String? ?? 'Un parent';
    print('DEBUG: Showing popup notification for parent: $parentName');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context != null && _context!.mounted) {
        print('DEBUG: Context is mounted, showing toast');
        ShadToaster.of(_context!).show(
          ShadToast(
            title: const Text('🔔 Nouvelle demande de connexion!'),
            description: Text('$parentName veut se connecter avec vous'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        print('DEBUG: Context is null or not mounted');
      }
    });
  }

  Future<void> _showConnectionNotification(Map<String, dynamic> requestData) async {
    final parentName = requestData['parentName'] as String? ?? 'Un parent';
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'connection_requests',
      'Connection Requests',
      channelDescription: 'Notifications for parent-child connection requests',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '$parentName veut se connecter avec vous',
        htmlFormatBigText: false,
        contentTitle: 'Nouvelle demande de connexion',
        htmlFormatContentTitle: false,
        summaryText: 'Appuyez pour voir la demande',
        htmlFormatSummaryText: false,
      ),
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Nouvelle demande de connexion',
      '$parentName veut se connecter avec vous',
      platformDetails,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to connection requests
    // This would typically be handled by the app's navigation system
    print('Connection notification tapped!');
  }

  Future<void> showApprovalNotification(String parentName) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'connection_requests',
      'Connection Requests',
      channelDescription: 'Notifications for parent-child connection requests',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.green,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Connexion établie!',
      'Vous êtes maintenant lié avec $parentName',
      platformDetails,
    );
  }
}
