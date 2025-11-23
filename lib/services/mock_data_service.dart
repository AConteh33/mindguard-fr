import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MockDataService {
  static const String _usersKey = 'users';
  static const String _moodEntriesKey = 'mood_entries';
  static const String _screenTimeKey = 'screen_time';
  static const String _childrenKey = 'children';
  static const String _assessmentsKey = 'assessments';

  // Initialize mock data from shared preferences
  static Future<Map<String, dynamic>> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize default users if not present
    if (!prefs.containsKey(_usersKey)) {
      await prefs.setString(_usersKey, jsonEncode({
        'child@example.com': {
          'uid': 'child123',
          'email': 'child@example.com',
          'role': 'child',
          'name': 'Enfant Test',
          'isActive': true,
        },
        'parent@example.com': {
          'uid': 'parent123',
          'email': 'parent@example.com',
          'role': 'parent',
          'name': 'Parent Test',
          'isActive': true,
        },
        'psychologist@example.com': {
          'uid': 'psych123',
          'email': 'psychologist@example.com',
          'role': 'psychologist',
          'name': 'Psychologue Test',
          'isActive': true,
        },
      }));
    }
    
    // Initialize mood entries if not present
    if (!prefs.containsKey(_moodEntriesKey)) {
      await prefs.setString(_moodEntriesKey, jsonEncode({}));
    }
    
    // Initialize screen time if not present
    if (!prefs.containsKey(_screenTimeKey)) {
      await prefs.setString(_screenTimeKey, jsonEncode({}));
    }
    
    // Initialize children if not present
    if (!prefs.containsKey(_childrenKey)) {
      await prefs.setString(_childrenKey, jsonEncode({}));
    }
    
    // Initialize assessments if not present
    if (!prefs.containsKey(_assessmentsKey)) {
      await prefs.setString(_assessmentsKey, jsonEncode({}));
    }
    
    return {
      'users': jsonDecode(prefs.getString(_usersKey) ?? '{}'),
      'mood_entries': jsonDecode(prefs.getString(_moodEntriesKey) ?? '{}'),
      'screen_time': jsonDecode(prefs.getString(_screenTimeKey) ?? '{}'),
      'children': jsonDecode(prefs.getString(_childrenKey) ?? '{}'),
      'assessments': jsonDecode(prefs.getString(_assessmentsKey) ?? '{}'),
    };
  }
  
  // Users operations
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final users = jsonDecode(prefs.getString(_usersKey) ?? '{}');
    return users[email] as Map<String, dynamic>?;
  }
  
  static Future<void> updateUser(String email, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final users = jsonDecode(prefs.getString(_usersKey) ?? '{}');
    users[email] = {...users[email] as Map<String, dynamic>, ...data};
    await prefs.setString(_usersKey, jsonEncode(users));
  }
  
  // Mood entries operations
  static Future<List<Map<String, dynamic>>> getMoodEntriesForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final moodEntries = jsonDecode(prefs.getString(_moodEntriesKey) ?? '{}');
    
    List<Map<String, dynamic>> userEntries = [];
    moodEntries.forEach((key, value) {
      if (value['userId'] == userId) {
        Map<String, dynamic> entryCopy = Map<String, dynamic>.from(value);
        entryCopy['date'] = DateTime.parse(entryCopy['date']);
        userEntries.add(entryCopy);
      }
    });
    
    // Sort by date, newest first
    userEntries.sort((a, b) => b['date'].compareTo(a['date']));
    return userEntries;
  }
  
  static Future<void> addMoodEntry(String userId, int moodValue, String notes) async {
    final prefs = await SharedPreferences.getInstance();
    final moodEntries = jsonDecode(prefs.getString(_moodEntriesKey) ?? '{}');
    
    final entryId = DateTime.now().millisecondsSinceEpoch.toString();
    moodEntries[entryId] = {
      'id': entryId,
      'userId': userId,
      'moodValue': moodValue,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_moodEntriesKey, jsonEncode(moodEntries));
  }
  
  // Screen time operations
  static Future<Map<String, dynamic>?> getScreenTimeForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final screenTime = jsonDecode(prefs.getString(_screenTimeKey) ?? '{}');
    return screenTime[userId] as Map<String, dynamic>?;
  }
  
  static Future<void> updateScreenTime(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final screenTime = jsonDecode(prefs.getString(_screenTimeKey) ?? '{}');
    screenTime[userId] = data;
    await prefs.setString(_screenTimeKey, jsonEncode(screenTime));
  }
  
  // Children operations
  static Future<Map<String, dynamic>?> getChildById(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final children = jsonDecode(prefs.getString(_childrenKey) ?? '{}');
    return children[childId] as Map<String, dynamic>?;
  }
  
  static Future<List<Map<String, dynamic>>> getChildrenForParent(String parentId) async {
    final prefs = await SharedPreferences.getInstance();
    final children = jsonDecode(prefs.getString(_childrenKey) ?? '{}');
    
    List<Map<String, dynamic>> parentChildren = [];
    children.forEach((key, value) {
      if (value['parentId'] == parentId) {
        parentChildren.add(Map<String, dynamic>.from(value));
      }
    });
    
    return parentChildren;
  }
  
  static Future<void> addChildToParent(String parentId, Map<String, dynamic> childData) async {
    final prefs = await SharedPreferences.getInstance();
    final children = jsonDecode(prefs.getString(_childrenKey) ?? '{}');
    
    final childId = 'child_${DateTime.now().millisecondsSinceEpoch}';
    children[childId] = {
      'id': childId,
      ...childData,
      'parentId': parentId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_childrenKey, jsonEncode(children));
  }
  
  // Assessment operations
  static Future<List<Map<String, dynamic>>> getAssessmentsForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final assessments = jsonDecode(prefs.getString(_assessmentsKey) ?? '{}');
    
    List<Map<String, dynamic>> userAssessments = [];
    assessments.forEach((key, value) {
      if (value['userId'] == userId) {
        Map<String, dynamic> assessmentCopy = Map<String, dynamic>.from(value);
        if (assessmentCopy['createdAt'] != null) {
          assessmentCopy['createdAt'] = DateTime.parse(assessmentCopy['createdAt']);
        }
        userAssessments.add(assessmentCopy);
      }
    });
    
    return userAssessments;
  }
  
  static Future<void> saveAssessmentResult(String userId, String toolId, int score, List<int> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final assessments = jsonDecode(prefs.getString(_assessmentsKey) ?? '{}');
    
    final assessmentId = 'assessment_${DateTime.now().millisecondsSinceEpoch}';
    assessments[assessmentId] = {
      'id': assessmentId,
      'userId': userId,
      'toolId': toolId,
      'score': score,
      'answers': answers,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_assessmentsKey, jsonEncode(assessments));
  }
}