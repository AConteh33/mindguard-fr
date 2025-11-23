import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../providers/parental_controls_provider.dart';
import '../services/parental_notification_service.dart';
import '../services/screen_time_monitoring_service.dart';
import '../models/parental_control_models.dart';

class AppBlockingService {
  static final AppBlockingService _instance = AppBlockingService._internal();
  factory AppBlockingService() => _instance;
  AppBlockingService._internal();

  final ParentalNotificationService _notificationService = ParentalNotificationService();
  Timer? _blockingCheckTimer;
  bool _isBlockingActive = false;
  OverlayEntry? _blockingOverlay;
  BuildContext? _appContext;
  String? _blockedAppName;
  String? _blockedReason;

  // Initialize app blocking
  void initialize(BuildContext context) {
    _appContext = context;
    _startBlockingChecks();
  }

  // Start periodic blocking checks
  void _startBlockingChecks() {
    _blockingCheckTimer?.cancel();
    _blockingCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkBlockingConditions();
    });
  }

  // Check if app should be blocked
  Future<void> _checkBlockingConditions() async {
    if (_appContext == null) return;

    final monitoringService = ScreenTimeMonitoringService();
    if (!monitoringService.isMonitoring) return;

    final stats = monitoringService.getCurrentUsageStats();
    final currentApp = stats['currentApp'] as String?;
    final isBlocked = stats['isBlocked'] as bool;

    if (currentApp != null && (isBlocked || _shouldBlockApp(currentApp))) {
      await _blockApp(currentApp, _getBlockReason(currentApp));
    } else if (_isBlockingActive && currentApp == null) {
      _unblockApp();
    }
  }

  // Check if specific app should be blocked
  bool _shouldBlockApp(String appName) {
    // This would integrate with ParentalControlsProvider
    // For now, return false (no blocking)
    return false;
  }

  // Get blocking reason for app
  String _getBlockReason(String appName) {
    // This would check the specific reason for blocking
    return 'Limite de temps atteinte';
  }

  // Block an app
  Future<void> _blockApp(String appName, String reason) async {
    if (_isBlockingActive && _blockedAppName == appName) return;

    _blockedAppName = appName;
    _blockedReason = reason;
    _isBlockingActive = true;

    // Show blocking overlay
    _showBlockingOverlay();

    // Send notification
    await _notificationService.showAppBlockedNotification(
      appName: appName,
      reason: reason,
    );

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  // Unblock app
  void _unblockApp() {
    if (!_isBlockingActive) return;

    _hideBlockingOverlay();
    _isBlockingActive = false;
    _blockedAppName = null;
    _blockedReason = null;
  }

  // Show blocking overlay
  void _showBlockingOverlay() {
    if (_appContext == null || _blockingOverlay != null) return;

    _blockingOverlay = OverlayEntry(
      builder: (context) => _AppBlockingOverlay(
        appName: _blockedAppName ?? '',
        reason: _blockedReason ?? '',
        onDismiss: () => _unblockApp(),
        onRequestMoreTime: () => _requestMoreTime(),
      ),
    );

    Overlay.of(_appContext!).insert(_blockingOverlay!);
  }

  // Hide blocking overlay
  void _hideBlockingOverlay() {
    _blockingOverlay?.remove();
    _blockingOverlay = null;
  }

  // Request more time (parent approval needed)
  Future<void> _requestMoreTime() async {
    // This would send a request to parent for approval
    // For now, just show a message
    if (_appContext != null) {
      ScaffoldMessenger.of(_appContext!).showSnackBar(
        const SnackBar(
          content: Text('Demande de temps supplémentaire envoyée aux parents'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Stop blocking service
  void dispose() {
    _blockingCheckTimer?.cancel();
    _hideBlockingOverlay();
    _isBlockingActive = false;
  }
}

// Widget for the blocking overlay
class _AppBlockingOverlay extends StatefulWidget {
  final String appName;
  final String reason;
  final VoidCallback onDismiss;
  final VoidCallback onRequestMoreTime;

  const _AppBlockingOverlay({
    required this.appName,
    required this.reason,
    required this.onDismiss,
    required this.onRequestMoreTime,
  });

  @override
  State<_AppBlockingOverlay> createState() => _AppBlockingOverlayState();
}

class _AppBlockingOverlayState extends State<_AppBlockingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Blocked icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Application bloquée',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // App name
                      Text(
                        widget.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Reason
                      Text(
                        widget.reason,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onRequestMoreTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Demander plus de temps'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.onDismiss,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Fermer'),
                            ),
                          ),
                        ],
                      ),

                      // Info text
                      const SizedBox(height: 16),
                      Text(
                        'Vos parents ont été notifiés',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget to show current blocking status
class AppBlockingStatusWidget extends StatelessWidget {
  const AppBlockingStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final monitoringService = ScreenTimeMonitoringService();
    
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getBlockingStatusStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final isBlocked = stats['isBlocked'] as bool;
        final currentApp = stats['currentApp'] as String?;

        if (!isBlocked && currentApp == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: isBlocked ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  isBlocked ? Icons.block : Icons.warning,
                  color: isBlocked ? Colors.red : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBlocked ? 'Application bloquée' : 'Limite proche',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? Colors.red : Colors.orange,
                        ),
                      ),
                      if (currentApp != null)
                        Text(
                          currentApp!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (isBlocked)
                  IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () => _showBlockingInfo(context),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>> _getBlockingStatusStream() {
    // This would stream real-time blocking status
    // For now, return a mock stream
    return Stream.periodic(const Duration(seconds: 5), (_) {
      final monitoringService = ScreenTimeMonitoringService();
      return monitoringService.getCurrentUsageStats();
    });
  }

  void _showBlockingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contrôle parental actif'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('L\'application actuelle est bloquée par les contrôles parentaux.'),
            SizedBox(height: 8),
            Text('Vous pouvez demander plus de temps à vos parents.'),
            SizedBox(height: 8),
            Text('Vos parents ont été notifiés de cette action.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

// Service to manage app blocking based on parental controls
class ParentalBlockingManager {
  static final ParentalBlockingManager _instance = ParentalBlockingManager._internal();
  factory ParentalBlockingManager() => _instance;
  ParentalBlockingManager._internal();

  final AppBlockingService _blockingService = AppBlockingService();
  bool _isInitialized = false;

  // Initialize blocking manager
  void initialize(BuildContext context) {
    if (_isInitialized) return;
    
    _blockingService.initialize(context);
    _isInitialized = true;
  }

  // Check if current app should be blocked
  Future<bool> shouldBlockCurrentApp({
    required String appName,
    required ParentalControlsProvider parentalControlsProvider,
  }) async {
    final limit = parentalControlsProvider.screenTimeLimit;
    if (limit == null || !limit.isActive) return false;

    // Check if app is in blocked list
    if (limit.blockedApps.contains(appName)) {
      return true;
    }

    // Check time restrictions
    if (!parentalControlsProvider.isScreenTimeAllowed()) {
      return true;
    }

    // Check app-specific limits
    final monitoringService = ScreenTimeMonitoringService();
    final stats = monitoringService.getCurrentUsageStats();
    final appUsage = stats['appUsage'] as Map<String, int>;
    final currentAppUsage = appUsage[appName] ?? 0;

    final appLimit = limit.appLimits[appName];
    if (appLimit != null && currentAppUsage >= appLimit) {
      return true;
    }

    // Check daily limit
    final totalUsage = stats['totalMinutes'] as int;
    if (totalUsage >= limit.dailyLimitMinutes) {
      return true;
    }

    return false;
  }

  // Get blocking reason
  String getBlockingReason({
    required String appName,
    required ParentalControlsProvider parentalControlsProvider,
  }) {
    final limit = parentalControlsProvider.screenTimeLimit;
    if (limit == null) return 'Contrôle parental actif';

    if (limit.blockedApps.contains(appName)) {
      return 'Application bloquée par les parents';
    }

    if (!parentalControlsProvider.isScreenTimeAllowed()) {
      return 'Temps d\'écran non autorisé à cette heure';
    }

    final monitoringService = ScreenTimeMonitoringService();
    final stats = monitoringService.getCurrentUsageStats();
    final appUsage = stats['appUsage'] as Map<String, int>;
    final currentAppUsage = appUsage[appName] ?? 0;

    final appLimit = limit.appLimits[appName];
    if (appLimit != null && currentAppUsage >= appLimit) {
      return 'Limite de temps pour cette application atteinte';
    }

    final totalUsage = stats['totalMinutes'] as int;
    if (totalUsage >= limit.dailyLimitMinutes) {
      return 'Limite quotidienne de temps d\'écran atteinte';
    }

    return 'Contrôle parental actif';
  }

  // Dispose blocking manager
  void dispose() {
    _blockingService.dispose();
    _isInitialized = false;
  }
}
