import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String childId;
  final String childName;
  final String parentId;
  final String? deviceId;
  final String? deviceName;
  final bool isActive;
  final DateTime? createdAt;

  ChildModel({
    required this.childId,
    required this.childName,
    required this.parentId,
    this.deviceId,
    this.deviceName,
    this.isActive = true,
    this.createdAt,
  });

  // Convert from Firestore document
  factory ChildModel.fromMap(Map<String, dynamic> data) {
    return ChildModel(
      childId: data['childId'] ?? data['id'] ?? '',
      childName: data['childName'] ?? data['name'] ?? '',
      parentId: data['parentId'] ?? data['parent_id'] ?? data['parentUid'] ?? '',
      deviceId: data['deviceId'],
      deviceName: data['deviceName'],
      isActive: data['isActive'] ?? data['active'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime?),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'childName': childName,
      'parentId': parentId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updates
  ChildModel copyWith({
    String? childId,
    String? childName,
    String? parentId,
    String? deviceId,
    String? deviceName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ChildModel(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      parentId: parentId ?? this.parentId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}