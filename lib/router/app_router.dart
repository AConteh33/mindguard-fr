import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/intro/intro_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/phone_number_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/main_tab_screen.dart';
import '../screens/children/child_profile_screen.dart';
import '../screens/mood/mood_history_screen.dart';
import '../screens/professional_tools/assessment_tool_screen.dart';
import '../screens/professional_tools/client_progress_tracking_screen.dart';
import '../screens/professional_tools/professional_assessment_tools_screen.dart';
import '../screens/network_activity_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../models/child_model.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/qr_code_display_screen.dart';
import '../screens/connection_requests_screen.dart';

// Define app routes using GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Authentication and onboarding
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/intro',
      name: 'intro',
      builder: (context, state) => const IntroScreen(),
    ),
    GoRoute(
      path: '/phone-number',
      name: 'phone_number',
      builder: (context, state) => const PhoneNumberScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      name: 'profile_setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/phone-verification',
      name: 'phone_verification',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        final name = state.uri.queryParameters['name'] ?? '';
        final role = state.uri.queryParameters['role'] ?? 'child';
        final gender = state.uri.queryParameters['gender'];
        final flowType = state.uri.queryParameters['flowType'] ?? 'registration';

        return PhoneVerificationScreen(
          phoneNumber: phone,
          name: name.isEmpty ? null : name,
          role: role.isEmpty ? null : role,
          gender: gender,
          flowType: flowType,
        );
      },
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      name: 'role_selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Main tab-based navigation
    GoRoute(
      path: '/main',
      name: 'main',
      builder: (context, state) => const MainTabScreen(),
    ),
    
    // Tab screens with deep linking support
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainTabScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const MainTabScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/focus',
      name: 'focus',
      builder: (context, state) => const MainTabScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const MainTabScreen(initialIndex: 3),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) {
        // For parents, settings is index 4, for others it's index 4
        final authProvider = Provider.of<AuthProvider>(context);
        final userRole = authProvider.userModel?.role ?? 'child';
        final index = userRole == 'parent' ? 4 : 4;
        return MainTabScreen(initialIndex: index);
      },
    ),
    
    // Add child
    GoRoute(
      path: '/children/add',
      name: 'add_child',
      builder: (context, state) {
        // For now, navigate to QR scanner to add child
        // In a full implementation, this would be a dedicated add child screen
        return const QrScannerScreen();
      },
    ),
    
    // Child profile (needs parameters)
    GoRoute(
      path: '/children/:childId',
      name: 'child_profile',
      builder: (context, state) {
        final childId = state.pathParameters['childId']!;
        return ChildProfileScreen(childId: childId);
      },
    ),
    
    // Other routes that are not part of main navigation
    GoRoute(
      path: '/mood/history',
      name: 'mood_history',
      builder: (context, state) => const MoodHistoryScreen(),
    ),
    
    // Professional tools
    GoRoute(
      path: '/professional-tools/assessments',
      name: 'professional_assessments',
      builder: (context, state) => const ProfessionalAssessmentToolsScreen(),
    ),
    GoRoute(
      path: '/professional-tools/assessment/:toolId',
      name: 'assessment_tool',
      builder: (context, state) {
        final toolId = state.pathParameters['toolId']!;
        return AssessmentToolScreen(toolId: toolId);
      },
    ),
    GoRoute(
      path: '/professional-tools/client-progress',
      name: 'client_progress',
      builder: (context, state) => const ClientProgressTrackingScreen(),
    ),

    // Network activity monitoring
    GoRoute(
      path: '/network-activity/:childId',
      name: 'network_activity',
      builder: (context, state) {
        final childId = state.pathParameters['childId']!;
        // ChildModel needs to be passed but we'll need to fetch it first
        return NetworkActivityScreen(
          child: ChildModel(
            childId: childId,
            childName: 'Child', // This will be replaced with the actual child name
            parentId: '', // This will be replaced with the actual parent ID
          ),
        );
      },
    ),
    // QR code related routes
    GoRoute(
      path: '/qr-scanner',
      name: 'qr_scanner',
      builder: (context, state) {
        return const QrScannerScreen();
      },
    ),
    GoRoute(
      path: '/qr-code',
      name: 'qr_code',
      builder: (context, state) {
        return const QrCodeDisplayScreen();
      },
    ),
    GoRoute(
      path: '/connection-requests',
      name: 'connection_requests',
      builder: (context, state) {
        return const ConnectionRequestsScreen();
      },
    ),
  ],
);