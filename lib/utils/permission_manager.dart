import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static final Map<Permission, PermissionInfo> permissionInfo = {
    Permission.camera: PermissionInfo(
      title: 'Accès à la caméra',
      description: 'MindGuard a besoin d\'accéder à votre caméra pour les sessions de thérapie vidéo et les exercices de reconnaissance faciale.',
      rationale: 'La caméra est utilisée pour:\n• Sessions de thérapie vidéo avec votre psychologue\n• Exercices de reconnaissance émotionnelle\n• Suivi des expressions faciales pendant les exercices',
      instructions: 'Pour activer l\'accès à la caméra:\n1. Allez dans Paramètres > Confidentialité > Caméra\n2. Trouvez MindGuard dans la liste\n3. Activez l\'accès à la caméra',
      icon: Icons.camera_alt,
    ),
    Permission.microphone: PermissionInfo(
      title: 'Accès au microphone',
      description: 'MindGuard a besoin d\'accéder à votre microphone pour les sessions de thérapie vocale et les exercices de parole.',
      rationale: 'Le microphone est utilisé pour:\n• Sessions de thérapie vocale\n• Exercices de respiration guidée\n• Analyse du ton de voix pendant les exercices',
      instructions: 'Pour activer l\'accès au microphone:\n1. Allez dans Paramètres > Confidentialité > Microphone\n2. Trouvez MindGuard dans la liste\n3. Activez l\'accès au microphone',
      icon: Icons.mic,
    ),
    Permission.storage: PermissionInfo(
      title: 'Accès au stockage',
      description: 'MindGuard a besoin d\'accéder à votre stockage pour sauvegarder vos données et fichiers thérapeutiques.',
      rationale: 'Le stockage est utilisé pour:\n• Sauvegarder vos exercices et progrès\n• Stocker les fichiers audio des sessions\n• Exporter vos rapports thérapeutiques',
      instructions: 'Pour activer l\'accès au stockage:\n1. Allez dans Paramètres > Applications > MindGuard\n2. Activez les permissions de stockage\n3. Autorisez l\'accès aux fichiers nécessaires',
      icon: Icons.storage,
    ),
    Permission.notification: PermissionInfo(
      title: 'Accès aux notifications',
      description: 'MindGuard a besoin d\'envoyer des notifications pour vous rappeler vos exercices et sessions.',
      rationale: 'Les notifications sont utilisées pour:\n• Rappels d\'exercices quotidiens\n• Alertes de sessions à venir\n• Messages de votre psychologue',
      instructions: 'Pour activer les notifications:\n1. Allez dans Paramètres > Notifications\n2. Trouvez MindGuard dans la liste\n3. Activez les notifications',
      icon: Icons.notifications,
    ),
    Permission.location: PermissionInfo(
      title: 'Accès à la localisation',
      description: 'MindGuard a besoin d\'accéder à votre localisation pour certaines thérapies basées sur le contexte.',
      rationale: 'La localisation est utilisée pour:\n• Thérapies basées sur l\'environnement\n• Suivi des lieux de stress/anxiété\n• Exercices de pleine conscience contextuels',
      instructions: 'Pour activer l\'accès à la localisation:\n1. Allez dans Paramètres > Confidentialité > Localisation\n2. Trouvez MindGuard dans la liste\n3. Choisissez "Pendant l\'utilisation de l\'application"',
      icon: Icons.location_on,
    ),
  };

  static Future<bool> requestPermission(Permission permission, BuildContext context) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final granted = await permission.request();
      if (granted.isGranted) {
        return true;
      }
    }
    
    if (status.isPermanentlyDenied) {
      await _showPermissionDialog(permission, context);
      return false;
    }
    
    return false;
  }

  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  static Future<void> requestMultiplePermissions(
    List<Permission> permissions, 
    BuildContext context
  ) async {
    final Map<Permission, bool> results = {};
    
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission, context);
    }
    
    final deniedPermissions = results.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (deniedPermissions.isNotEmpty) {
      await _showMultiplePermissionsDialog(deniedPermissions, context);
    }
  }

  static Future<void> _showPermissionDialog(Permission permission, BuildContext context) async {
    final info = permissionInfo[permission];
    if (info == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(permissionInfo: info),
    );
  }

  static Future<void> _showMultiplePermissionsDialog(
    List<Permission> permissions, 
    BuildContext context
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultiplePermissionsDialog(permissions: permissions),
    );
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

class PermissionInfo {
  final String title;
  final String description;
  final String rationale;
  final String instructions;
  final IconData icon;

  const PermissionInfo({
    required this.title,
    required this.description,
    required this.rationale,
    required this.instructions,
    required this.icon,
  });
}

class PermissionDialog extends StatelessWidget {
  final PermissionInfo permissionInfo;

  const PermissionDialog({super.key, required this.permissionInfo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            permissionInfo.icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permissionInfo.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permissionInfo.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pourquoi cette permission est nécessaire:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    permissionInfo.rationale,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comment activer cette permission:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    permissionInfo.instructions,
                    style: Theme.of(context).textTheme.bodySmall,
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
          child: const Text('Plus tard'),
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

class MultiplePermissionsDialog extends StatelessWidget {
  final List<Permission> permissions;

  const MultiplePermissionsDialog({super.key, required this.permissions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.settings_applications,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Permissions requises'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MindGuard a besoin des permissions suivantes pour fonctionner correctement:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...permissions.map((permission) {
              final info = PermissionManager.permissionInfo[permission];
              if (info == null) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      info.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        info.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous pouvez activer ces permissions dans les paramètres de votre appareil.',
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
          child: const Text('Plus tard'),
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
