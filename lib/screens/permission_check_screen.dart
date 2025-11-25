import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../utils/permission_manager.dart';
import '../widgets/permission/permission_wrapper.dart';

class PermissionCheckScreen extends StatefulWidget {
  final List<Permission> requiredPermissions;
  final String? title;
  final String? description;
  final Widget? child;
  final bool showOnStartup;

  const PermissionCheckScreen({
    super.key,
    this.requiredPermissions = const [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
    ],
    this.title,
    this.description,
    this.child,
    this.showOnStartup = false,
  });

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  final PermissionService _permissionService = PermissionService();
  Map<Permission, bool> _permissionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _permissionService.setContext(context);
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isLoading = true);
    
    final Map<Permission, bool> statusMap = {};
    
    for (final permission in widget.requiredPermissions) {
      statusMap[permission] = await PermissionManager.checkPermission(permission);
    }
    
    if (mounted) {
      setState(() {
        _permissionStatus = statusMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    await _permissionService.requestAllPermissions();
    await _checkAllPermissions();
  }

  Future<void> _requestPermission(Permission permission) async {
    await PermissionManager.requestPermission(permission, context);
    await _checkAllPermissions();
  }

  bool _allPermissionsGranted() {
    return _permissionStatus.values.every((granted) => granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Vérification des permissions...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_allPermissionsGranted() && widget.child != null) {
      return widget.child!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Permissions MindGuard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.description ?? 
                    'MindGuard a besoin de certaines permissions pour vous offrir la meilleure expérience thérapeutique.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Permission List
            Text(
              'Permissions requises:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...widget.requiredPermissions.map((permission) {
              final isGranted = _permissionStatus[permission] ?? false;
              final info = PermissionManager._permissionInfo[permission];
              
              if (info == null) return const SizedBox.shrink();
              
              return PermissionCard(
                permission: permission,
                info: info,
                isGranted: isGranted,
                onRequestPermission: () => _requestPermission(permission),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (!_allPermissionsGranted()) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Certaines permissions sont nécessaires pour accéder à toutes les fonctionnalités de MindGuard.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestAllPermissions,
                        child: const Text('Autoriser tout'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toutes les permissions sont accordées!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.child != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => widget.child!),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Continuer'),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Footer
            Center(
              child: TextButton(
                onPressed: () {
                  _permissionService.showPermissionStatusDialog();
                },
                child: Text(
                  'Voir l\'état des permissions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  final Permission permission;
  final PermissionInfo info;
  final bool isGranted;
  final VoidCallback onRequestPermission;

  const PermissionCard({
    super.key,
    required this.permission,
    required this.info,
    required this.isGranted,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGranted 
              ? Colors.green.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.icon,
                color: isGranted 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGranted ? Colors.green : null,
                  ),
                ),
              ),
              Icon(
                isGranted ? Icons.check_circle : Icons.error_outline,
                color: isGranted ? Colors.green : Colors.orange,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRequestPermission,
                child: const Text('Autoriser'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
