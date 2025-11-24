# Firestore Index Setup Guide

The MindGuard app requires composite Firestore indexes to perform queries efficiently. When you see errors like "The query requires an index", follow these steps:

## Required Indexes

### 1. Mood Entries Index
- **Collection**: `mood_entries`
- **Fields**: 
  - `userId` (Ascending)
  - `timestamp` (Descending)
- **Direct Link**: [Create Mood Entries Index](https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=Clhwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9tb29kX2VudHJpZXMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg)

### 2. App Usage Index
- **Collection**: `app_usage`
- **Fields**: 
  - `userId` (Ascending)
  - `timestamp` (Descending)
- **Direct Link**: [Create App Usage Index](https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=ClVwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9hcHBfdXNhZ2UvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg)

### 3. Focus Sessions Index
- **Collection**: `focus_sessions`
- **Fields**: 
  - `userId` (Ascending)
  - `startTime` (Descending)
- **Direct Link**: [Create Focus Sessions Index](https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=Clpwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9mb2N1c19zZXNzaW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoNCglzdGFydFRpbWUQAhoMCghfX25hbWVfXxAC)

## Quick Setup Steps

1. **Click each link above** - This will take you to the Firebase Console with the index pre-configured
2. **Click "Create Index"** for each one
3. **Wait for deployment** - Indexes typically take 1-5 minutes to build
4. **Restart your app** - The errors should be resolved

## Manual Setup (Alternative)

If the direct links don't work:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `mind-guard-fr-81a22`
3. Navigate to Firestore Database → Indexes
4. Click "Create Index"
5. For each collection above, add the two fields with the specified order
6. Click "Create"

## Error Handling

The app now includes improved error handling that will show you:
- Which collection needs an index
- The exact field configuration required
- Direct links to create the indexes

This makes troubleshooting much easier when setting up the app for the first time.

## Verification

After creating the indexes, you should see:
- No more "requires an index" errors
- Data loading properly in the dashboard
- Mood entries, app usage, and focus sessions displaying correctly

## Notes

- Indexes are one-time setup per Firebase project
- They're free for the usage levels in this app
- Building indexes can take a few minutes
- The app will work normally once indexes are ready
