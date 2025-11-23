import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FocusNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'focus_mode_channel',
    'Focus Mode Notifications',
    description: 'Notifications for focus mode reminders',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);
    
    // Create notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> showFocusReminder(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'focus_mode_channel',
      'Focus Mode Notifications',
      channelDescription: 'Notifications for focus mode reminders',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New notification to stay focused',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notifications.show(
      1, // Unique ID for the notification
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> scheduleFocusReminder(
      String title, String body, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'focus_mode_channel',
      'Focus Mode Notifications',
      channelDescription: 'Notifications for focus mode reminders',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Convert scheduled time to local timezone
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      scheduledDate.millisecondsSinceEpoch ~/ 1000, // Use timestamp as unique ID
      title,
      body,
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}