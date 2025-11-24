import 'package:cloud_firestore/cloud_firestore.dart';

/// This script creates the required Firestore indexes for the MindGuard app
/// Run this once to set up the database indexes properly
Future<void> setupFirestoreIndexes() async {
  final firestore = FirebaseFirestore.instance;
  
  // Index 1: mood_entries collection - userId + timestamp
  await firestore.collection('mood_entries').add({
    '_index_setup': 'userId + timestamp',
    'created_at': FieldValue.serverTimestamp(),
  });
  
  // Index 2: app_usage collection - userId + timestamp
  await firestore.collection('app_usage').add({
    '_index_setup': 'userId + timestamp',
    'created_at': FieldValue.serverTimestamp(),
  });
  
  // Index 3: focus_sessions collection - userId + startTime
  await firestore.collection('focus_sessions').add({
    '_index_setup': 'userId + startTime',
    'created_at': FieldValue.serverTimestamp(),
  });
  
  print('Index setup documents created. Now create the composite indexes manually:');
  print('');
  print('1. Mood Entries Index:');
  print('   Collection: mood_entries');
  print('   Fields: userId (Ascending), timestamp (Descending)');
  print('   URL: https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=Clhwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9tb29kX2VudHJpZXMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg');
  print('');
  print('2. App Usage Index:');
  print('   Collection: app_usage');
  print('   Fields: userId (Ascending), timestamp (Descending)');
  print('   URL: https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=ClVwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9hcHBfdXNhZ2UvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg');
  print('');
  print('3. Focus Sessions Index:');
  print('   Collection: focus_sessions');
  print('   Fields: userId (Ascending), startTime (Descending)');
  print('   URL: https://console.firebase.google.com/v1/r/project/mind-guard-fr-81a22/firestore/indexes?create_composite=Clpwcm9qZWN0cy9taW5kLWd1YXJkLWZyLTgxYTIyL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9mb2N1c19zZXNzaW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoNCglzdGFydFRpbWUQAhoMCghfX25hbWVfXxAC');
}
