import 'package:flutter/services.dart';

/// DNS Monitoring Service
/// Handles communication with the native Android DNS monitoring service
class DNSMonitoringService {
  static const platform = MethodChannel('com.example.mindguard_fr/dns_monitoring');

  bool _isDNSMonitoring = false;

  /// Start DNS monitoring
  Future<void> startDNSMonitoring(String userId) async {
    print('🔍 Starting DNS monitoring for user: $userId');

    try {
      await _startDNSMonitoring(userId);
      _isDNSMonitoring = true;
      print('✅ DNS monitoring started');
    } catch (e) {
      print('❌ Error starting DNS monitoring: $e');
      rethrow;
    }
  }

  /// Stop DNS monitoring
  Future<void> stopDNSMonitoring() async {
    print('🛑 Stopping DNS monitoring...');

    try {
      if (_isDNSMonitoring) {
        await _stopDNSMonitoring();
        _isDNSMonitoring = false;
        print('✅ DNS monitoring stopped');
      }
    } catch (e) {
      print('❌ Error stopping DNS monitoring: $e');
    }
  }

  /// Start DNS monitoring via native channel
  Future<void> _startDNSMonitoring(String userId) async {
    try {
      await platform.invokeMethod('startDNSMonitoring', {'userId': userId});
    } on PlatformException catch (e) {
      print('❌ Failed to start DNS monitoring: ${e.message}');
      rethrow;
    }
  }

  /// Stop DNS monitoring via native channel
  Future<void> _stopDNSMonitoring() async {
    try {
      await platform.invokeMethod('stopDNSMonitoring');
    } on PlatformException catch (e) {
      print('❌ Failed to stop DNS monitoring: ${e.message}');
    }
  }

  /// Get monitoring status
  Map<String, bool> getMonitoringStatus() {
    return {
      'dns_monitoring': _isDNSMonitoring,
    };
  }

  /// Check if monitoring is active
  bool get isMonitoringActive => _isDNSMonitoring;
}