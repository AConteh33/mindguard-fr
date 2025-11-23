import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/app_usage_provider.dart';
import '../../providers/focus_session_provider.dart';
import '../../services/focus_notification_service.dart';
import '../../widgets/visual/animated_background_visual.dart';
import '../../widgets/bottom_nav_bar.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  final CountDownController _countDownController = CountDownController();
  int _selectedDuration = 25; // Default 25 minutes
  bool _isFocusActive = false;
  bool _isPaused = false;
  bool _blockApps = false;
  List<Map<String, dynamic>> _distractingApps = [];

  @override
  void initState() {
    super.initState();
    // Load distracting apps when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDistractingApps();
    });
  }

  Future<void> _loadDistractingApps() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      await appUsageProvider.loadAppUsageData(authProvider.userModel!.uid);

      // For demo purposes, let's consider the top 3 apps as potentially distracting
      final topApps = appUsageProvider.getTopAppsByUsage(limit: 5);

      if (mounted) { // Check if widget is still mounted before setState
        setState(() {
          _distractingApps = topApps;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appUsageProvider = Provider.of<AppUsageProvider>(context);

    return Scaffold(
      body: AnimatedBackgroundVisual(
        enableAnimation: true, // Enable animations for visual appeal
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            if (!_isFocusActive) ...[
              Text(
                'Mode Focus',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Choisissez une durée',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildDurationButton(15),
                  _buildDurationButton(25),
                  _buildDurationButton(30),
                  _buildDurationButton(45),
                  _buildDurationButton(60),
                ],
              ),
              const SizedBox(height: 48),
              ShadButton(
                onPressed: _startFocusSession,
                child: const Text('Commencer'),
              ),
            ] else ...[
              // Focus active view - simplified and centered
              const SizedBox(height: 48),
              CircularCountDownTimer(
                duration: _selectedDuration * 60, // Convert to seconds
                initialDuration: 0,
                controller: _countDownController,
                width: 200,
                height: 200,
                ringColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                strokeWidth: 6.0,
                strokeCap: StrokeCap.round,
                textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                isReverse: true,
                isReverseAnimation: false,
                isTimerTextShown: true,
                autoStart: false, // Don't auto-start, we'll control it manually
                onComplete: () {
                  _focusSessionCompleted();
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Restez concentré',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ShadButton.outline(
                    onPressed: _pauseFocusSession,
                    child: Text(_isPaused ? 'Reprendre' : 'Pause'),
                  ),
                  ShadButton(
                    onPressed: _stopFocusSession,
                    child: const Text('Terminer'),
                  ),
                ],
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationButton(int minutes) {
    final isSelected = _selectedDuration == minutes;
    
    return isSelected 
        ? ShadButton(
            onPressed: () {
              print('Selected duration: $minutes minutes');
              setState(() {
                _selectedDuration = minutes;
              });
            },
            child: Text('$minutes min'),
          )
        : ShadButton.outline(
            onPressed: () {
              print('Selected duration: $minutes minutes');
              setState(() {
                _selectedDuration = minutes;
              });
            },
            child: Text('$minutes min'),
          );
  }

  void _startFocusSession() {
    print('Starting focus session with duration: $_selectedDuration minutes');
    setState(() {
      _isFocusActive = true;
      _isPaused = false;
    });

    // Restart the countdown timer
    print('Restarting timer...');
    _countDownController.restart();

    // In a complete implementation, this would trigger the app blocking functionality
    // which requires Device Admin permissions on Android
    if (_blockApps) {
      // This would call native Android code to activate the focus mode
      // with app blocking capabilities
      _enableAppBlocking();
    }
  }

  void _enableAppBlocking() {
    // Show a notification to remind the user to stay focused
    FocusNotificationService.showFocusReminder(
      'Mode Focus Activé',
      'Vous êtes maintenant en mode focus. Évitez d\'utiliser les applications distractrices.',
    );

    // Schedule periodic notifications during the focus session
    _schedulePeriodicFocusReminders();
  }

  void _schedulePeriodicFocusReminders() {
    // Schedule reminder notifications at intervals during the focus session
    final totalDuration = _selectedDuration * 60; // Convert to seconds
    const reminderInterval = 300; // 5 minutes in seconds

    for (int i = reminderInterval; i < totalDuration; i += reminderInterval) {
      final scheduledTime = DateTime.now().add(Duration(seconds: i));

      FocusNotificationService.scheduleFocusReminder(
        'Rappel de Focus',
        'Vous êtes toujours en mode focus. Concentrez-vous sur votre tâche.',
        scheduledTime,
      );
    }
  }

  void _stopFocusSession() {
    setState(() {
      _isFocusActive = false;
      _isPaused = false;
    });
    _countDownController.pause();

    // Disable app blocking when session ends
    _disableAppBlocking();
  }

  void _disableAppBlocking() {
    // Cancel all scheduled focus notifications when focus mode ends
    FocusNotificationService.cancelAllNotifications();

    // Show a notification that focus mode has ended
    FocusNotificationService.showFocusReminder(
      'Mode Focus Terminé',
      'Votre session de focus est terminée. Vous pouvez maintenant utiliser votre appareil librement.',
    );
  }

  void _pauseFocusSession() {
    if (_isPaused) {
      _countDownController.resume();
      setState(() {
        _isPaused = false;
      });
      // When resuming, ensure app blocking is still active if enabled
      if (_blockApps && _isFocusActive) {
        _enableAppBlocking();
      }
    } else {
      _countDownController.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _focusSessionCompleted() {
    print('Focus session completed!');
    if (mounted) {
      setState(() {
        _isFocusActive = false;
        _isPaused = false;
      });

      // Disable app blocking when session completes
      _disableAppBlocking();

      // Save focus session data
      _saveFocusSessionData();

      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session de focus terminée! Félicitations!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _saveFocusSessionData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      // Get the list of apps that were marked for blocking (distracting apps)
      List<String> blockedApps = _distractingApps.map((app) => app['appName'] as String).toList();

      // Create a focus session object
      final session = FocusSession(
        id: '', // Will be generated by Firestore
        userId: authProvider.userModel!.uid,
        startTime: DateTime.now().subtract(Duration(minutes: _selectedDuration)), // Approximate start time
        endTime: DateTime.now(),
        durationMinutes: _selectedDuration,
        completed: true,
        blockedApps: blockedApps,
        createdAt: DateTime.now(),
      );

      // Save to provider which will handle Firestore storage
      focusSessionProvider.addFocusSession(session);
    }
  }
}