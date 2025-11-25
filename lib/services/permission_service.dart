import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_manager.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  // Camera permissions for video therapy sessions
  Future<bool> requestCameraPermission() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(
      Permission.camera, 
      _context!,
    );
  }

  // Microphone permissions for voice therapy
  Future<bool> requestMicrophonePermission() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(
      Permission.microphone, 
      _context!,
    );
  }

  // Storage permissions for saving therapy data
  Future<bool> requestStoragePermission() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(
      Permission.storage, 
      _context!,
    );
  }

  // Notification permissions for reminders
  Future<bool> requestNotificationPermission() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(
      Permission.notification, 
      _context!,
    );
  }

  // Location permissions for context-based therapy
  Future<bool> requestLocationPermission() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(
      Permission.location, 
      _context!,
    );
  }

  // Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    return await PermissionManager.checkPermission(Permission.camera);
  }

  // Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await PermissionManager.checkPermission(Permission.microphone);
  }

  // Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    return await PermissionManager.checkPermission(Permission.storage);
  }

  // Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    return await PermissionManager.checkPermission(Permission.notification);
  }

  // Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    return await PermissionManager.checkPermission(Permission.location);
  }

  // Request all permissions needed for the app
  Future<void> requestAllPermissions() async {
    if (_context == null) return;
    
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
      Permission.location,
    ];
    
    await PermissionManager.requestMultiplePermissions(permissions, _context!);
  }

  // Request permissions for video therapy session
  Future<bool> requestVideoTherapyPermissions() async {
    if (_context == null) return false;
    
    final permissions = [Permission.camera, Permission.microphone];
    bool allGranted = true;
    
    for (final permission in permissions) {
      final granted = await PermissionManager.requestPermission(permission, _context!);
      if (!granted) {
        allGranted = false;
      }
    }
    
    return allGranted;
  }

  // Request permissions for exercise recording
  Future<bool> requestExerciseRecordingPermissions() async {
    if (_context == null) return false;
    
    final permissions = [Permission.microphone, Permission.storage];
    bool allGranted = true;
    
    for (final permission in permissions) {
      final granted = await PermissionManager.requestPermission(permission, _context!);
      if (!granted) {
        allGranted = false;
      }
    }
    
    return allGranted;
  }

  // Request permissions for notifications and reminders
  Future<bool> requestNotificationPermissions() async {
    if (_context == null) return false;
    
    return await PermissionManager.requestPermission(Permission.notification, _context!);
  }

  // Show permission status dialog
  void showPermissionStatusDialog() async {
    if (_context == null) return;
    
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
      Permission.location,
    ];
    
    final Map<Permission, bool> statusMap = {};
    
    for (final permission in permissions) {
      statusMap[permission] = await PermissionManager.checkPermission(permission);
    }
    
    await showDialog(
      context: _context!,
      builder: (context) => PermissionStatusDialog(statusMap: statusMap),
    );
  }
}

class PermissionStatusDialog extends StatelessWidget {
  final Map<Permission, bool> statusMap;

  const PermissionStatusDialog({super.key, required this.statusMap});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('État des permissions'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voici l\'état actuel des permissions de MindGuard:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...statusMap.entries.map((entry) {
              final permission = entry.key;
              final isGranted = entry.value;
              final info = PermissionManager.permissionInfo[permission];
              
              if (info == null) return const SizedBox.shrink();
              
              return PermissionStatusItem(
                title: info.title,
                icon: info.icon,
                isGranted: isGranted,
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous pouvez modifier ces permissions à tout moment dans les paramètres de votre appareil.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          child: const Text('Ouvrir les paramètres'),
        ),
      ],
    );
  }
}

class PermissionStatusItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isGranted;

  const PermissionStatusItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted 
                ? Colors.green 
                : Theme.of(context).colorScheme.outline,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isGranted ? null : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle : Icons.error_outline,
            color: isGranted ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }
}
