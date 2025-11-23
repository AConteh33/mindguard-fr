import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/parental_controls_provider.dart';
import '../providers/auth_provider.dart';
import '../models/parental_control_models.dart';
import '../services/screen_time_monitoring_service.dart';

class ParentalNotificationService {
  static final ParentalNotificationService _instance = ParentalNotificationService._internal();
  factory ParentalNotificationService() => _instance;
  ParentalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // Show notification to child
  Future<void> showChildNotification({
    required String title,
    required String message,
    String? payload,
    NotificationType type = NotificationType.warning,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'parental_controls_channel',
      'Contrôles Parentaux',
      channelDescription: 'Notifications pour les contrôles parentaux',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: payload,
    );
  }

  // Show warning notification
  Future<void> showWarningNotification({
    required String appName,
    required int usedMinutes,
    required int limitMinutes,
    bool isDaily = false,
  }) async {
    final title = isDaily ? '⚠️ Limite de temps d\'écran proche' : '⚠️ Limite d\'application proche';
    final message = isDaily
        ? 'Vous avez utilisé $usedMinutes minutes sur $limitMinutes minutes autorisées aujourd\'hui.'
        : '$appName: $usedMinutes minutes utilisées sur $limitMinutes minutes autorisées.';

    await showChildNotification(
      title: title,
      message: message,
      payload: 'warning_${isDaily ? 'daily' : 'app'}',
      type: NotificationType.warning,
    );
  }

  // Show limit reached notification
  Future<void> showLimitReachedNotification({
    required String appName,
    required int limitMinutes,
    bool isDaily = false,
  }) async {
    final title = isDaily ? '🚫 Limite de temps d\'écran atteinte' : '🚫 Limite d\'application atteinte';
    final message = isDaily
        ? 'Vous avez atteint votre limite quotidienne de $limitMinutes minutes.'
        : 'Vous avez atteint la limite de temps pour $appName ($limitMinutes minutes).';

    await showChildNotification(
      title: title,
      message: message,
      payload: 'limit_${isDaily ? 'daily' : 'app'}',
      type: NotificationType.limitReached,
    );
  }

  // Show app blocked notification
  Future<void> showAppBlockedNotification({
    required String appName,
    String? reason,
  }) async {
    final title = '🚫 Application bloquée';
    final message = reason != null 
        ? '$appName est bloquée: $reason'
        : '$appName est bloquée par les contrôles parentaux.';

    await showChildNotification(
      title: title,
      message: message,
      payload: 'blocked_app',
      type: NotificationType.appBlocked,
    );
  }

  // Show time restriction notification
  Future<void> showTimeRestrictionNotification() async {
    await showChildNotification(
      title: '🚫 Temps d\'écran non autorisé',
      message: 'Le temps d\'écran n\'est pas autorisé à cette heure.',
      payload: 'time_restricted',
      type: NotificationType.timeRestricted,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation or actions when notification is tapped
    print('Notification tapped: ${response.payload}');
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

enum NotificationType {
  warning,
  limitReached,
  appBlocked,
  timeRestricted,
}

// Widget to display parental notifications to parents
class ParentalNotificationsWidget extends StatefulWidget {
  const ParentalNotificationsWidget({super.key});

  @override
  State<ParentalNotificationsWidget> createState() => _ParentalNotificationsWidgetState();
}

class _ParentalNotificationsWidgetState extends State<ParentalNotificationsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context, listen: false);
    
    if (authProvider.userModel?.role == 'parent') {
      await parentalControlsProvider.loadNotifications(authProvider.userModel!.uid);
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return '⚠️';
      case 'limit_reached':
        return '🚫';
      case 'app_blocked':
        return '📱';
      case 'time_restricted':
        return '⏰';
      default:
        return '📢';
    }
  }

  Color _getNotificationColor(String type, BuildContext context) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'limit_reached':
        return Colors.red;
      case 'app_blocked':
        return Colors.red;
      case 'time_restricted':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context);

    if (authProvider.userModel?.role != 'parent') {
      return const SizedBox.shrink();
    }

    final notifications = parentalControlsProvider.notifications;
    final unreadCount = parentalControlsProvider.unreadNotificationsCount;

    return Column(
      children: [
        // Header with unread count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Notifications list
        if (notifications.isEmpty)
          const Text('Aucune notification')
        else
          Column(
            children: notifications.map((notification) {
              return Card(
                color: notification.isRead 
                    ? Theme.of(context).colorScheme.surface
                    : _getNotificationColor(notification.type, context).withOpacity(0.1),
                child: ListTile(
                  leading: Text(
                    _getNotificationIcon(notification.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.message),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: !notification.isRead
                      ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            parentalControlsProvider.markNotificationAsRead(notification.id);
                          },
                        )
                      : null,
                  onTap: () {
                    if (!notification.isRead) {
                      parentalControlsProvider.markNotificationAsRead(notification.id);
                    }
                  },
                ),
              );
            }).toList(),
          ),

        // Mark all as read button
        if (unreadCount > 0) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              parentalControlsProvider.markAllNotificationsAsRead();
            },
            child: const Text('Marquer tout comme lu'),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
  }
}

// Service to monitor and send notifications automatically
class NotificationMonitoringService {
  static final NotificationMonitoringService _instance = NotificationMonitoringService._internal();
  factory NotificationMonitoringService() => _instance;
  NotificationMonitoringService._internal();

  final ParentalNotificationService _notificationService = ParentalNotificationService();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Start monitoring for notifications
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    
    // Check every minute for notification triggers
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndSendNotifications();
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
  }

  // Check conditions and send notifications
  Future<void> _checkAndSendNotifications() async {
    final monitoringService = ScreenTimeMonitoringService();
    
    if (!monitoringService.isMonitoring) return;

    final stats = monitoringService.getCurrentUsageStats();
    final totalUsage = stats['totalMinutes'] as int;
    final currentApp = stats['currentApp'] as String?;
    final appUsage = stats['appUsage'] as Map<String, int>;

    // This would integrate with the parental controls provider
    // to check limits and send appropriate notifications
  }

  // Send immediate notification based on type
  Future<void> sendNotification({
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    switch (type) {
      case NotificationType.warning:
        if (data != null) {
          await _notificationService.showWarningNotification(
            appName: data['appName'] ?? '',
            usedMinutes: data['usedMinutes'] ?? 0,
            limitMinutes: data['limitMinutes'] ?? 0,
            isDaily: data['isDaily'] ?? false,
          );
        }
        break;
        
      case NotificationType.limitReached:
        if (data != null) {
          await _notificationService.showLimitReachedNotification(
            appName: data['appName'] ?? '',
            limitMinutes: data['limitMinutes'] ?? 0,
            isDaily: data['isDaily'] ?? false,
          );
        }
        break;
        
      case NotificationType.appBlocked:
        if (data != null) {
          await _notificationService.showAppBlockedNotification(
            appName: data['appName'] ?? '',
            reason: data['reason'],
          );
        }
        break;
        
      case NotificationType.timeRestricted:
        await _notificationService.showTimeRestrictionNotification();
        break;
    }
  }
}
