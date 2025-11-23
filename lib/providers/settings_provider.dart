import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _focusModeNotifications = false;
  bool _moodReminderEnabled = true;
  bool _screenTimeAlerts = true;
  bool _dataSharingEnabled = false;
  bool _locationTracking = false;

  // SharedPreferences keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _focusModeNotificationsKey = 'focus_mode_notifications';
  static const String _moodReminderEnabledKey = 'mood_reminder_enabled';
  static const String _screenTimeAlertsKey = 'screen_time_alerts';
  static const String _dataSharingEnabledKey = 'data_sharing_enabled';
  static const String _locationTrackingKey = 'location_tracking';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get focusModeNotifications => _focusModeNotifications;
  bool get moodReminderEnabled => _moodReminderEnabled;
  bool get screenTimeAlerts => _screenTimeAlerts;
  bool get dataSharingEnabled => _dataSharingEnabled;
  bool get locationTracking => _locationTracking;

  SettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _focusModeNotifications = prefs.getBool(_focusModeNotificationsKey) ?? false;
      _moodReminderEnabled = prefs.getBool(_moodReminderEnabledKey) ?? true;
      _screenTimeAlerts = prefs.getBool(_screenTimeAlertsKey) ?? true;
      _dataSharingEnabled = prefs.getBool(_dataSharingEnabledKey) ?? false;
      _locationTracking = prefs.getBool(_locationTrackingKey) ?? false;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading settings: $e');
    }
  }

  // Save all settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setBool(_focusModeNotificationsKey, _focusModeNotifications);
      await prefs.setBool(_moodReminderEnabledKey, _moodReminderEnabled);
      await prefs.setBool(_screenTimeAlertsKey, _screenTimeAlerts);
      await prefs.setBool(_dataSharingEnabledKey, _dataSharingEnabled);
      await prefs.setBool(_locationTrackingKey, _locationTracking);
    } catch (e) {
      if (kDebugMode) print('Error saving settings: $e');
    }
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setFocusModeNotifications(bool value) {
    _focusModeNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setMoodReminderEnabled(bool value) {
    _moodReminderEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setScreenTimeAlerts(bool value) {
    _screenTimeAlerts = value;
    _saveSettings();
    notifyListeners();
  }

  void setDataSharingEnabled(bool value) {
    _dataSharingEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setLocationTracking(bool value) {
    _locationTracking = value;
    _saveSettings();
    notifyListeners();
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _notificationsEnabled = true;
    _focusModeNotifications = false;
    _moodReminderEnabled = true;
    _screenTimeAlerts = true;
    _dataSharingEnabled = false;
    _locationTracking = false;
    
    await _saveSettings();
    notifyListeners();
  }

  // Export settings as Map
  Map<String, bool> exportSettings() {
    return {
      _notificationsEnabledKey: _notificationsEnabled,
      _focusModeNotificationsKey: _focusModeNotifications,
      _moodReminderEnabledKey: _moodReminderEnabled,
      _screenTimeAlertsKey: _screenTimeAlerts,
      _dataSharingEnabledKey: _dataSharingEnabled,
      _locationTrackingKey: _locationTracking,
    };
  }

  // Import settings from Map
  Future<void> importSettings(Map<String, bool> settings) async {
    try {
      _notificationsEnabled = settings[_notificationsEnabledKey] ?? true;
      _focusModeNotifications = settings[_focusModeNotificationsKey] ?? false;
      _moodReminderEnabled = settings[_moodReminderEnabledKey] ?? true;
      _screenTimeAlerts = settings[_screenTimeAlertsKey] ?? true;
      _dataSharingEnabled = settings[_dataSharingEnabledKey] ?? false;
      _locationTracking = settings[_locationTrackingKey] ?? false;
      
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error importing settings: $e');
    }
  }
}