import 'package:flutter/foundation.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _focusModeNotifications = false;
  bool _moodReminderEnabled = true;
  bool _screenTimeAlerts = true;
  bool _dataSharingEnabled = false;
  bool _locationTracking = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get focusModeNotifications => _focusModeNotifications;
  bool get moodReminderEnabled => _moodReminderEnabled;
  bool get screenTimeAlerts => _screenTimeAlerts;
  bool get dataSharingEnabled => _dataSharingEnabled;
  bool get locationTracking => _locationTracking;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setFocusModeNotifications(bool value) {
    _focusModeNotifications = value;
    notifyListeners();
  }

  void setMoodReminderEnabled(bool value) {
    _moodReminderEnabled = value;
    notifyListeners();
  }

  void setScreenTimeAlerts(bool value) {
    _screenTimeAlerts = value;
    notifyListeners();
  }

  void setDataSharingEnabled(bool value) {
    _dataSharingEnabled = value;
    notifyListeners();
  }

  void setLocationTracking(bool value) {
    _locationTracking = value;
    notifyListeners();
  }
}