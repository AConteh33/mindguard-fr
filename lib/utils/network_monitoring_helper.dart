import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class NetworkMonitoringHelper {
  static const platform = MethodChannel('com.example.mindguard_fr/dns_monitoring');

  /// Start DNS monitoring service
  static Future<bool> startDNSMonitoring(String userId) async {
    if (!Platform.isAndroid || kIsWeb) {
      print('DNS monitoring only available on Android');
      return false;
    }

    try {
      final result = await platform.invokeMethod<bool>(
        'startDNSMonitoring',
        {'userId': userId},
      );
      print('DNS monitoring started for user: $userId');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error starting DNS monitoring: ${e.message}');
      return false;
    }
  }

  /// Stop DNS monitoring service
  static Future<bool> stopDNSMonitoring() async {
    if (!Platform.isAndroid || kIsWeb) {
      print('DNS monitoring only available on Android');
      return false;
    }

    try {
      final result = await platform.invokeMethod<bool>('stopDNSMonitoring');
      print('DNS monitoring stopped');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error stopping DNS monitoring: ${e.message}');
      return false;
    }
  }
}