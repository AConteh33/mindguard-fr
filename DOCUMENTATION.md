# MindGuard FR - Documentation

## Table of Contents
1. [Authentication Flow](#authentication-flow)
2. [Parent-Child Linking System](#parent-child-linking-system)
3. [Dashboard Features](#dashboard-features)
4. [App Usage Tracking](#app-usage-tracking)
5. [Focus Mode](#focus-mode)
6. [User Roles & Permissions](#user-roles--permissions)

---

## Authentication Flow

### Overview
The app uses Firebase Authentication with phone number verification as the primary method.

### Login Flow
1. **Splash Screen** (2.5 seconds)
   - Checks if user is already authenticated
   - If logged in → `/main` (dashboard)
   - If not logged in → `/phone-number`

2. **Phone Number Entry** (`/phone-number`)
   - User enters phone number with country code selection
   - Supports 40+ countries with automatic normalization
   - Sends SMS verification code via Firebase

3. **Phone Verification** (`/phone-verification`)
   - User enters SMS code
   - Firebase automatically determines if user exists (login) or needs registration
   - New users → `/profile-setup`
   - Existing users → `/main`

### Key Features
- **International Phone Support**: 40+ countries with proper formatting
- **Auto-verification**: Works on supported devices
- **Single Flow**: Same process for login and registration
- **Error Handling**: User-friendly French error messages

---

## Parent-Child Linking System

### Overview
Parents can link with their children through a QR code system with approval workflow.

### Linking Process

#### For Children
1. **Generate QR Code** (`/qr-code`)
   - Child generates unique QR code with their user ID
   - QR format: `mindguard://link_child/{childId}/{timestamp}`
   - Shows notification badge for pending requests

2. **Approve Requests** (`/connection-requests`)
   - Child views pending parent connection requests
   - Can accept or reject requests
   - Real-time updates with StreamBuilder

#### For Parents
1. **Add Child** (`/children/add`)
   - Parent scans child's QR code using camera
   - Creates connection request in Firestore
   - Request expires in 7 days

2. **View Linked Children**
   - Dashboard shows all linked children
   - Displays child name, device info, and status
   - Real-time updates when connections change

### Data Structure

#### Connection Requests Collection
```dart
{
  'parentId': 'parent_user_id',
  'childId': 'child_user_id', 
  'parentName': 'Parent Name',
  'status': 'pending', // pending, approved, rejected
  'requestedAt': Timestamp,
  'expiresAt': Timestamp,
  'approvedAt': Timestamp, // if approved
  'rejectedAt': Timestamp, // if rejected
}
```

#### Children Collection
```dart
{
  'childId': 'child_user_id',
  'childName': 'Child Name',
  'parentId': 'parent_user_id',
  'deviceId': 'device_id', // optional
  'deviceName': 'Device Name', // optional
  'isActive': true,
  'createdAt': Timestamp,
  'linkedAt': Timestamp,
}
```

### Key Features
- **Security**: QR codes expire, requests expire in 7 days
- **Approval Required**: Children must approve connections
- **Real-time**: Live updates using Firestore streams
- **Bidirectional**: Both parties can see the connection

---

## Dashboard Features

### Overview
Role-based dashboard with personalized widgets and real-time data.

### Dashboard Components

#### 1. Linked People Widget
- **For Parents**: Shows all linked children with device info
- **For Children**: Shows their linked parent information
- **Empty States**: Helpful CTAs when no connections exist
- **Real-time**: Updates immediately when connections change

#### 2. App Usage Widget
- **Top 5 Apps**: Most used applications today
- **Smart Icons**: Dynamic icons based on app names
- **Time Formatting**: Human-readable time (2h 30m, 45m 30s, 30s)
- **Color Coding**: Each app gets unique color
- **Empty State**: Message when no usage data available

#### 3. Stats Cards
- **Screen Time Today**: Total device usage
- **Productive Time**: Percentage of productive usage
- **Sessions Today**: Number of app sessions
- **Average Mood**: Mood score from entries

#### 4. Mood Visualization
- **Recent Mood**: Visual representation of mood entries
- **Trends**: Mood patterns over time
- **Interactive**: Tap to view detailed history

### Data Loading
```dart
// Dashboard loads data based on user role
if (userRole == 'parent') {
  childrenProvider.loadChildrenForParent(userId);
} else if (userRole == 'child') {
  childrenProvider.getParentForChild(userId);
}

// Always load personal data
screenTimeProvider.loadScreenTimeData(userId);
moodProvider.loadMoodEntries(userId);
appUsageProvider.loadAppUsageData(userId, daysBack: 1); // Today only
```

---

## App Usage Tracking

### Overview
Tracks application usage patterns and provides insights on screen time.

### Data Collection
- **Package Name**: App identifier (e.g., com.instagram.android)
- **App Name**: Display name (e.g., Instagram)
- **Usage Time**: Time spent in seconds
- **Timestamp**: When usage was recorded

### Provider Methods

#### AppUsageProvider
```dart
// Load usage data for specific timeframe
loadAppUsageData(String userId, {int daysBack = 7})

// Get top apps by usage time
getTopAppsByUsage({int limit = 10})

// Get total usage for specific app
getTotalUsageTimeForApp(String appName)

// Get usage statistics
getUsageStats() // Returns totalApps, totalUsageTime, averageDailyUsage, mostUsedApp
```

### Smart Icon Mapping
The app usage widget automatically detects app types:

| App Name Pattern | Icon | Color |
|------------------|------|-------|
| Instagram | camera_alt | Blue |
| Facebook | facebook | Blue |
| Twitter/X | alternate_email | Blue |
| YouTube | play_circle | Red |
| TikTok | music_video | Black |
| Snapchat | camera | Yellow |
| WhatsApp | message | Green |
| Gmail/Mail | mail | Red |
| Chrome/Browser | language | Blue/Green |
| Games | sports_esports | Orange |
| Spotify/Music | music_note | Green |
| Netflix/Video | movie | Red |
| Maps/GPS | map | Blue |
| Default | apps | Gray |

### Time Formatting
- **> 1 hour**: "2h 30m"
- **< 1 hour**: "45m 30s" 
- **< 1 minute**: "30s"
- **Additional context**: "150 min"

---

## Focus Mode

### Overview
Pomodoro-style focus timer with optional app blocking and notifications.

### Features

#### Session Management
- **Duration Options**: 15, 25, 30, 45, 60 minutes
- **Visual Timer**: Circular countdown display
- **Pause/Resume**: Full session control
- **Auto-stop**: Timer completion handling

#### App Blocking (Optional)
- **Focus Reminders**: Periodic notifications every 5 minutes
- **Distracting Apps**: Shows top 5 most used apps
- **Usage Time**: Displays time spent on each app
- **Notification Service**: Background notifications

#### Session States
1. **Setup Mode**: Select duration and options
2. **Active Mode**: Running timer with controls
3. **Paused Mode**: Timer stopped, can resume
4. **Completed Mode**: Session finished, data saved

### Data Storage
```dart
// Focus session saved to Firestore
{
  'id': 'session_id',
  'userId': 'user_id',
  'startTime': Timestamp,
  'endTime': Timestamp,
  'durationMinutes': 25,
  'completed': true,
  'blockedApps': ['Instagram', 'TikTok'],
  'createdAt': Timestamp,
}
```

### Notification Flow
1. **Session Start**: "Mode Focus Activé" notification
2. **Periodic Reminders**: Every 5 minutes during session
3. **Session End**: "Mode Focus Terminé" notification

---

## User Roles & Permissions

### Roles Overview

#### Child
- **Dashboard**: Personal usage stats and parent info
- **Focus Mode**: Full access to focus tools
- **Mood Tracking**: Can track and view mood history
- **QR Code**: Generate for parent linking
- **Connection Requests**: Approve parent connections

#### Parent
- **Dashboard**: Child overview and personal stats
- **Child Management**: Add/view linked children
- **Focus Mode**: Full access to focus tools
- **Mood Tracking**: Can track and view mood history
- **QR Scanner**: Scan child QR codes to link
- **Monitoring**: View child's digital wellbeing (future feature)

#### Professional (Psychologist)
- **Dashboard**: Client overview and professional tools
- **Assessment Tools**: Professional assessment instruments
- **Client Management**: Track client progress
- **Focus Mode**: Full access to focus tools
- **Mood Tracking**: Can track and view mood history

### Navigation by Role
- **All Roles**: Dashboard, Focus, Profile, Settings
- **Parent Only**: Children management, QR scanner
- **Child Only**: QR code generation, connection requests
- **Professional Only**: Assessment tools, client tracking

### Theme Adaptation
The app adapts its color scheme based on user role:
- **Child**: Youth-friendly colors (bright, playful)
- **Parent**: Mature colors (calm, trustworthy)
- **Professional**: Professional colors (serious, clinical)

---

## Technical Architecture

### State Management
- **Provider Pattern**: Using ChangeNotifier for global state
- **Firebase Integration**: Firestore for data, Auth for authentication
- **Real-time Updates**: StreamBuilder for live data

### Key Providers
- **AuthProvider**: User authentication and profile management
- **ChildrenProvider**: Parent-child relationship management
- **AppUsageProvider**: Application usage tracking
- **ScreenTimeProvider**: Device usage statistics
- **MoodProvider**: Mood entry tracking and analysis
- **FocusSessionProvider**: Focus session management

### Navigation
- **GoRouter**: Declarative routing with deep linking
- **Route Guards**: Protected routes based on authentication
- **Tab Navigation**: Bottom navigation for main sections

### Data Models
- **UserModel**: Basic user information and role
- **ChildModel**: Parent-child relationship data
- **FocusSession**: Focus session tracking
- **AppUsageEntry**: Application usage records

### Security Features
- **Firebase Auth**: Secure authentication backend
- **QR Code Expiration**: Time-limited linking codes
- **Request Expiration**: 7-day expiry for connection requests
- **Role-based Access**: Different features per user type

---

## Development Notes

### Getting Started
1. Run `flutter pub get` to install dependencies
2. Configure Firebase in `firebase_options.dart`
3. Update `pubspec.yaml` with required packages
4. Run `flutter run` to start development

### Key Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Backend services
- `provider`, `go_router`: State management and navigation
- `shadcn_ui`: UI component library
- `mobile_scanner`, `qr_flutter`: QR code functionality
- `fl_chart`: Chart visualizations
- `circular_countdown_timer`: Focus timer display

### Testing
- Use `flutter test` to run unit tests
- Test authentication flows with Firebase emulators
- Verify QR code generation and scanning
- Test parent-child linking workflow

### Deployment
- Configure Firebase for production
- Update app icons and splash screens
- Test on real devices for camera functionality
- Verify international phone number formatting
