# MindGuard FR

MindGuard is a comprehensive digital wellness and mental health application built with Flutter. The app provides role-based dashboards for Parents, Children, and Psychologists to monitor and manage digital wellbeing through phone-based authentication and real-time data tracking.

## ✨ Key Features

### 🔐 Authentication System
- **Phone-based authentication** using Firebase SMS verification
- **International phone support** for 40+ countries
- **Single flow** for both login and registration
- **Auto-verification** on supported devices

### 👨‍👩‍👧‍👦 Parent-Child Linking
- **QR code system** for secure parent-child connections
- **Approval workflow** - children must approve connection requests
- **Real-time updates** using Firestore streams
- **Bidirectional visibility** - both parties see linked relationships

### 📊 Dashboard Features
- **Role-based widgets** tailored to each user type
- **App usage tracking** with smart icons and time formatting
- **Linked people display** showing family connections
- **Screen time statistics** and mood visualization
- **Real-time data** synchronization

### 🎯 Focus Mode
- **Pomodoro timer** with customizable durations (15-60 minutes)
- **App blocking** capabilities during focus sessions
- **Periodic notifications** every 5 minutes
- **Session tracking** and completion analytics

### 📱 App Usage Tracking
- **Top 5 apps** displayed with smart icon recognition
- **Time formatting** (2h 30m, 45m 30s, 30s)
- **Color-coded apps** for visual distinction
- **Daily usage** statistics and insights

## 🛠 Tech Stack

- **Framework**: Flutter 3.x
- **UI Library**: shadcn_ui ^0.38.5
- **State Management**: Provider pattern
- **Authentication**: Firebase Auth (Phone)
- **Database**: Cloud Firestore
- **Navigation**: GoRouter
- **Charts**: fl_chart
- **QR Codes**: mobile_scanner, qr_flutter
- **Notifications**: Firebase Cloud Messaging

## 📁 Project Structure

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── child_model.dart
│   └── focus_session.dart
├── providers/
│   ├── auth_provider.dart
│   ├── children_provider.dart
│   ├── app_usage_provider.dart
│   ├── screen_time_provider.dart
│   ├── mood_provider.dart
│   └── focus_session_provider.dart
├── screens/
│   ├── auth/
│   │   ├── phone_number_screen.dart
│   │   ├── phone_verification_screen.dart
│   │   ├── role_selection_screen.dart
│   │   └── profile_setup_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── focus/
│   │   └── focus_mode_screen.dart
│   ├── qr_scanner_screen.dart
│   ├── qr_code_display_screen.dart
│   ├── connection_requests_screen.dart
│   └── splash_screen.dart
├── widgets/
│   ├── linked_people_widget.dart
│   ├── app_usage_widget.dart
│   └── visual/ (chart components)
├── services/
│   ├── country_codes_service.dart
│   └── focus_notification_service.dart
└── router/
    └── app_router.dart
```

## 🔄 Authentication Flow

1. **Splash Screen** (2.5s) → Check auth state
2. **Phone Number Entry** → Enter number with country code
3. **SMS Verification** → Enter verification code
4. **Auto-detection** → Firebase determines login vs registration
5. **Profile Setup** (if new user) → Complete registration
6. **Dashboard** → Role-specific main screen

## 👥 Role Features

### 🧑 Parent
- **Add children** via QR code scanning
- **Monitor child's** digital wellbeing
- **View linked children** with device information
- **Access all** focus and mood features
- **Real-time updates** when children connect/disconnect

### 👶 Child
- **Generate QR code** for parent linking
- **Approve/reject** parent connection requests
- **Track personal** app usage and screen time
- **Use focus mode** with app blocking
- **View parent** information when linked

### 👨‍⚕️ Psychologist
- **Professional assessment** tools
- **Client progress** tracking
- **Appointment** management
- **Focus mode** for sessions
- **Mood tracking** and analysis

## 🔗 Parent-Child Linking System

### For Children
1. Go to **QR Code** screen
2. **Generate unique** QR code with user ID
3. **Share QR code** with parent
4. **Approve requests** in Connection Requests screen
5. **View parent** in dashboard once linked

### For Parents
1. Go to **Add Child** from dashboard
2. **Scan child's** QR code with camera
3. **Connection request** sent to child
4. **Wait for approval** from child
5. **View child** in dashboard once approved

### Security Features
- **QR code expiration** with timestamps
- **Request expiry** after 7 days
- **Approval required** from children
- **Real-time notifications** for pending requests

## 📊 App Usage Tracking

### Data Collection
- **Package name** and **app name** tracking
- **Usage time** in seconds
- **Timestamp** for daily aggregation
- **Top apps** ranking by usage time

### Smart Features
- **Icon recognition** for popular apps (Instagram, TikTok, YouTube, etc.)
- **Color coding** for visual distinction
- **Time formatting** for readability
- **Empty states** with helpful messages

## 🎯 Focus Mode Features

### Session Management
- **Duration options**: 15, 25, 30, 45, 60 minutes
- **Visual timer** with circular countdown
- **Pause/resume** functionality
- **Session completion** tracking

### App Blocking
- **Top 5 distracting** apps identified
- **Usage time** displayed for each app
- **Focus reminders** every 5 minutes
- **Notification service** integration

## 🔧 Firebase Configuration

1. **Create Firebase project**
2. **Enable Phone Authentication** in Firebase Console
3. **Configure Firestore** with security rules
4. **Add configuration files**:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. **Enable Cloud Messaging** for notifications

### Required Collections
- `users` - User profiles and authentication data
- `children` - Parent-child relationships
- `connection_requests` - Pending linking requests
- `app_usage` - Application usage tracking
- `focus_sessions` - Focus session data
- `mood_entries` - Mood tracking data

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Firebase project
- Android Studio / VS Code

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd mindguard_fr

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Development Setup
1. **Configure Firebase** with your project credentials
2. **Update firebase_options.dart** with your configuration
3. **Test authentication** with real phone numbers
4. **Verify QR code** generation and scanning
5. **Test parent-child** linking workflow

## 🎨 Customization

### Theming
The app uses shadcn_ui for consistent styling. Customize themes in `main.dart`:

```dart
ShadApp.router(
  theme: ShadThemeData(
    colorScheme: ShadSchemes.light(),
    // Custom theme modifications
  ),
)
```

### Role-Based Themes
Each role can have customized color schemes:
- **Child**: Bright, playful colors
- **Parent**: Calm, trustworthy colors  
- **Professional**: Clinical, serious colors

## 📱 Supported Platforms

- **Android** (API 21+)
- **iOS** (iOS 12+)
- **Web** (Chrome, Safari, Firefox)
- **macOS**, **Linux**, **Windows** (Desktop)

## 🔒 Security Features

- **Firebase Authentication** for secure user management
- **Phone verification** prevents fake accounts
- **QR code expiration** prevents unauthorized access
- **Request timeouts** prevent stale connection attempts
- **Firestore security rules** for data protection

## 📈 Performance

- **Lazy loading** of dashboard data
- **Stream-based** real-time updates
- **Efficient state management** with Provider
- **Optimized widgets** for smooth animations
- **Background processing** for notifications

## 📞 Support

For detailed documentation, see [DOCUMENTATION.md](./DOCUMENTATION.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
