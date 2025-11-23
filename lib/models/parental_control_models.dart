import 'package:cloud_firestore/cloud_firestore.dart';

class ScreenTimeLimit {
  final String id;
  final String childId;
  final String parentId;
  final int dailyLimitMinutes; // Daily screen time limit in minutes
  final Map<String, int> appLimits; // Per-app limits in minutes
  final List<String> blockedApps; // Completely blocked apps
  final List<String> allowedTimeRanges; // Time ranges when screen time is allowed
  final bool notificationsEnabled;
  final int warningThresholdMinutes; // Minutes before limit to show warning
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ScreenTimeLimit({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.dailyLimitMinutes,
    this.appLimits = const {},
    this.blockedApps = const [],
    this.allowedTimeRanges = const [],
    this.notificationsEnabled = true,
    this.warningThresholdMinutes = 15,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Create ScreenTimeLimit from Firestore document
  factory ScreenTimeLimit.fromMap(Map<String, dynamic> map, String id) {
    return ScreenTimeLimit(
      id: id,
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      dailyLimitMinutes: map['dailyLimitMinutes'] ?? 120, // Default 2 hours
      appLimits: Map<String, int>.from(map['appLimits'] ?? {}),
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      allowedTimeRanges: List<String>.from(map['allowedTimeRanges'] ?? []),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      warningThresholdMinutes: map['warningThresholdMinutes'] ?? 15,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert ScreenTimeLimit to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'parentId': parentId,
      'dailyLimitMinutes': dailyLimitMinutes,
      'appLimits': appLimits,
      'blockedApps': blockedApps,
      'allowedTimeRanges': allowedTimeRanges,
      'notificationsEnabled': notificationsEnabled,
      'warningThresholdMinutes': warningThresholdMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create copy with updated values
  ScreenTimeLimit copyWith({
    String? id,
    String? childId,
    String? parentId,
    int? dailyLimitMinutes,
    Map<String, int>? appLimits,
    List<String>? blockedApps,
    List<String>? allowedTimeRanges,
    bool? notificationsEnabled,
    int? warningThresholdMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ScreenTimeLimit(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      appLimits: appLimits ?? this.appLimits,
      blockedApps: blockedApps ?? this.blockedApps,
      allowedTimeRanges: allowedTimeRanges ?? this.allowedTimeRanges,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      warningThresholdMinutes: warningThresholdMinutes ?? this.warningThresholdMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ScreenTimeLimit(id: $id, childId: $childId, dailyLimitMinutes: $dailyLimitMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenTimeLimit &&
        other.id == id &&
        other.childId == childId &&
        other.parentId == parentId &&
        other.dailyLimitMinutes == dailyLimitMinutes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        childId.hashCode ^
        parentId.hashCode ^
        dailyLimitMinutes.hashCode;
  }
}

class ScreenTimeUsage {
  final String id;
  final String childId;
  final String date; // Format: YYYY-MM-DD
  final Map<String, int> appUsage; // App name -> minutes used
  final int totalMinutesUsed;
  final DateTime lastUpdated;
  final List<TimeBlock> timeBlocks; // Detailed usage blocks

  ScreenTimeUsage({
    required this.id,
    required this.childId,
    required this.date,
    required this.appUsage,
    required this.totalMinutesUsed,
    required this.lastUpdated,
    this.timeBlocks = const [],
  });

  factory ScreenTimeUsage.fromMap(Map<String, dynamic> map, String id) {
    return ScreenTimeUsage(
      id: id,
      childId: map['childId'] ?? '',
      date: map['date'] ?? '',
      appUsage: Map<String, int>.from(map['appUsage'] ?? {}),
      totalMinutesUsed: map['totalMinutesUsed'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeBlocks: (map['timeBlocks'] as List<dynamic>?)
          ?.map((block) => TimeBlock.fromMap(block))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'date': date,
      'appUsage': appUsage,
      'totalMinutesUsed': totalMinutesUsed,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'timeBlocks': timeBlocks.map((block) => block.toMap()).toList(),
    };
  }
}

class TimeBlock {
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  TimeBlock({
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  factory TimeBlock.fromMap(Map<String, dynamic> map) {
    return TimeBlock(
      appName: map['appName'] ?? '',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
    };
  }
}

class ParentalControlNotification {
  final String id;
  final String childId;
  final String parentId;
  final String type; // 'warning', 'limit_reached', 'app_blocked'
  final String title;
  final String message;
  final String? appName; // Specific app if applicable
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data; // Additional data

  ParentalControlNotification({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.type,
    required this.title,
    required this.message,
    this.appName,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  factory ParentalControlNotification.fromMap(Map<String, dynamic> map, String id) {
    return ParentalControlNotification(
      id: id,
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      appName: map['appName'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'parentId': parentId,
      'type': type,
      'title': title,
      'message': message,
      'appName': appName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
    };
  }

  // Create copy with updated values
  ParentalControlNotification copyWith({
    String? id,
    String? childId,
    String? parentId,
    String? type,
    String? title,
    String? message,
    String? appName,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return ParentalControlNotification(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      appName: appName ?? this.appName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}
