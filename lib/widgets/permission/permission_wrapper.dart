import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/permission_service.dart';
import '../../utils/permission_manager.dart';

class PermissionWrapper extends StatefulWidget {
  final Widget child;
  final Permission permission;
  final String? title;
  final String? description;
  final Widget? fallback;
  final bool showPermissionDialog;

  const PermissionWrapper({
    super.key,
    required this.child,
    required this.permission,
    this.title,
    this.description,
    this.fallback,
    this.showPermissionDialog = true,
  });

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isLoading = true);
    
    final hasPermission = await PermissionManager.checkPermission(widget.permission);
    
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await PermissionManager.requestPermission(
      widget.permission, 
      context,
    );
    
    if (granted) {
      setState(() => _hasPermission = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasPermission) {
      return widget.child;
    }

    if (widget.fallback != null) {
      return widget.fallback!;
    }

    return PermissionRequestCard(
      permission: widget.permission,
      title: widget.title,
      description: widget.description,
      onRequestPermission: _requestPermission,
    );
  }
}

class PermissionRequestCard extends StatelessWidget {
  final Permission permission;
  final String? title;
  final String? description;
  final VoidCallback onRequestPermission;

  const PermissionRequestCard({
    super.key,
    required this.permission,
    this.title,
    this.description,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    final info = PermissionManager._permissionInfo[permission];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info?.icon ?? Icons.lock,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? info?.title ?? 'Permission requise',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description ?? info?.description ?? 'Cette permission est nécessaire pour utiliser cette fonctionnalité.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRequestPermission,
                  child: const Text('Autoriser'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => PermissionDialog(permissionInfo: info!),
              );
            },
            child: Text(
              'En savoir plus',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MultiPermissionWrapper extends StatefulWidget {
  final Widget child;
  final List<Permission> permissions;
  final Widget? fallback;

  const MultiPermissionWrapper({
    super.key,
    required this.child,
    required this.permissions,
    this.fallback,
  });

  @override
  State<MultiPermissionWrapper> createState() => _MultiPermissionWrapperState();
}

class _MultiPermissionWrapperState extends State<MultiPermissionWrapper> {
  bool _allPermissionsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    bool allGranted = true;
    for (final permission in widget.permissions) {
      final hasPermission = await PermissionManager.checkPermission(permission);
      if (!hasPermission) {
        allGranted = false;
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _allPermissionsGranted = allGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await PermissionManager.requestMultiplePermissions(
      widget.permissions, 
      context,
    );
    
    // Re-check permissions after request
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allPermissionsGranted) {
      return widget.child;
    }

    if (widget.fallback != null) {
      return widget.fallback!;
    }

    return MultiPermissionRequestCard(
      permissions: widget.permissions,
      onRequestPermissions: _requestPermissions,
    );
  }
}

class MultiPermissionRequestCard extends StatelessWidget {
  final List<Permission> permissions;
  final VoidCallback onRequestPermissions;

  const MultiPermissionRequestCard({
    super.key,
    required this.permissions,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_applications,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Permissions requises',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cette fonctionnalité nécessite plusieurs permissions pour fonctionner correctement.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...permissions.map((permission) {
            final info = PermissionManager._permissionInfo[permission];
            if (info == null) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    info.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRequestPermissions,
                  child: const Text('Autoriser tout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
