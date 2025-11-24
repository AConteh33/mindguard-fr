import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mindguard_fr/providers/auth_provider.dart';
import 'package:mindguard_fr/providers/theme_provider.dart';
import 'package:mindguard_fr/providers/mood_provider.dart';
import 'package:mindguard_fr/providers/settings_provider.dart';
import 'package:mindguard_fr/providers/screen_time_provider.dart';
import 'package:mindguard_fr/providers/children_provider.dart';
import 'package:mindguard_fr/providers/app_usage_provider.dart';
import 'package:mindguard_fr/providers/focus_session_provider.dart';
import 'package:mindguard_fr/providers/assessment_provider.dart';
import 'package:mindguard_fr/providers/client_provider.dart';
import 'package:mindguard_fr/providers/appointments_provider.dart';
import 'package:mindguard_fr/providers/messages_provider.dart';
import 'package:mindguard_fr/providers/parental_controls_provider.dart';
import 'package:mindguard_fr/router/app_router.dart';
import 'package:mindguard_fr/services/focus_notification_service.dart';
import 'package:mindguard_fr/services/parental_notification_service.dart';
import 'package:mindguard_fr/services/realtime_parental_service.dart';
import 'package:mindguard_fr/services/app_blocking_service.dart';
import 'package:mindguard_fr/services/screen_time_monitoring_service.dart';
import 'package:mindguard_fr/services/app_usage_platform_service.dart';
import 'package:mindguard_fr/services/connection_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize focus notifications
  await FocusNotificationService.initialize();
  
  // Initialize parental controls services
  await ParentalNotificationService().initialize();
  
  // Initialize connection notifications
  await ConnectionNotificationService().initialize();

  // Check and initialize app usage tracking
  await _initializeAppUsageTracking();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => MoodProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ScreenTimeProvider()),
        ChangeNotifierProvider(create: (context) => ChildrenProvider()),
        ChangeNotifierProvider(create: (context) => AppUsageProvider()),
        ChangeNotifierProvider(create: (context) => FocusSessionProvider()),
        ChangeNotifierProvider(create: (context) => AssessmentProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
        ChangeNotifierProvider(create: (context) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (context) => MessagesProvider()),
        ChangeNotifierProvider(create: (context) => ParentalControlsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => MoodProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ScreenTimeProvider()),
        ChangeNotifierProvider(create: (context) => ChildrenProvider()),
        ChangeNotifierProvider(create: (context) => AppUsageProvider()),
        ChangeNotifierProvider(create: (context) => FocusSessionProvider()),
        ChangeNotifierProvider(create: (context) => AssessmentProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
        ChangeNotifierProvider(create: (context) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (context) => MessagesProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          // Update theme based on user role when user changes, but avoid rebuild during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authProvider.userModel != null && themeProvider.currentRole != authProvider.userModel!.role) {
              themeProvider.setRole(authProvider.userModel!.role);
            }
          });
          
          return ShadApp.router(
            routerConfig: appRouter,
            title: 'MindGuard FR',
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 0.8, // Reduced text size (10 instead of default ~12-14)
                ),
                child: child!,
              );
            },
            theme: ShadThemeData(
              brightness: Brightness.light,
              colorScheme: themeProvider.getRoleColorScheme(false),
            ),
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: themeProvider.getRoleColorScheme(true).copyWith(
                card: Colors.black,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Initialize app usage tracking
Future<void> _initializeAppUsageTracking() async {
  try {
    // Check if usage stats permission is available
    final hasPermission = await AppUsagePlatformService.hasUsageStatsPermission();
    
    if (!hasPermission) {
      print('App usage tracking permission not granted. Please enable Usage Stats permission in Settings.');
      return;
    }
    
    // Test if we can get usage data
    final canMonitor = await AppUsagePlatformService.canMonitorUsage();
    
    if (canMonitor) {
      print('App usage tracking initialized successfully');
    } else {
      print('App usage tracking initialization failed - permission or compatibility issue');
    }
  } catch (e) {
    print('Error initializing app usage tracking: $e');
  }
}