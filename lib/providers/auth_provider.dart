import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mindguard_fr/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/phone_verification_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoggedIn = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    // Initialize with no user
    _userModel = null;
    _isLoggedIn = false;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadUserFromFirestore(user.uid);
      } else {
        _userModel = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    });
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await loadUserFromFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur de connexion.';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé avec cet email.';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect.';
      }
      throw Exception(message);
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhone(String phone) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices
          await _auth.signInWithCredential(credential);
          await loadUserFromFirestore(_auth.currentUser!.uid);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Échec de la vérification du numéro: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store verificationId for later use
          // In a real app, you would show a dialog to enter the code
          PhoneVerificationService().verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur d\'authentification par téléphone.';
      if (e.code == 'invalid-phone-number') {
        message = 'Numéro de téléphone invalide.';
      } else if (e.code == 'too-many-requests') {
        message = 'Trop de tentatives. Veuillez réessayer plus tard.';
      }
      throw Exception(message);
    }
  }

  // Verify phone code and complete registration
  Future<void> verifyPhoneCodeAndRegister(String verificationId, String smsCode, String? name, String? role, {String? gender}) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': null,
        'phone': userCredential.user!.phoneNumber,
        'role': role ?? 'child', // Default to child if not provided
        'name': name ?? 'Nouvel Utilisateur', // Default name if not provided
        'gender': gender,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Load the user data
      await loadUserFromFirestore(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur de vérification du code.';
      if (e.code == 'invalid-verification-code') {
        message = 'Code de vérification invalide.';
      } else if (e.code == 'session-expired') {
        message = 'Session expirée. Veuillez réessayer.';
      }
      throw Exception(message);
    }
  }

  // Register with phone number - creates a temporary user entry
  Future<void> registerWithPhone(String phone, String? name, String? role, {String? gender}) async {
    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(phone);

      // Store user information temporarily (until phone verification is completed)
      // This is a simplified approach - in a full implementation, you might use
      // a temporary collection or store details differently

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices
          final userCredential = await _auth.signInWithCredential(credential);

          // Create user profile in Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': null,
            'phone': userCredential.user!.phoneNumber,
            'role': role ?? 'child',
            'name': name ?? 'Nouvel Utilisateur',
            'gender': gender,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Load the user data
          await loadUserFromFirestore(userCredential.user!.uid);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Échec de la vérification du numéro: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store the verification ID in the service so it can be accessed later
          PhoneVerificationService().verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur d\'inscription par téléphone.';
      if (e.code == 'invalid-phone-number') {
        message = 'Numéro de téléphone invalide.';
      } else if (e.code == 'too-many-requests') {
        message = 'Trop de tentatives. Veuillez réessayer plus tard.';
      }
      throw Exception(message);
    }
  }

  // Register with email and password
  Future<void> register(String email, String password, String role, {String? name, String? gender}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'phone': null,
        'role': role,
        'name': name ?? 'Nouvel Utilisateur',
        'gender': gender,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadUserFromFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur d\'inscription.';
      if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Un compte avec cet email existe déjà.';
      }
      throw Exception(message);
    }
  }

  // Helper method to load user from Firestore
  Future<void> loadUserFromFirestore(String uid) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;
        _userModel = UserModel.fromMap(userData);
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user from Firestore: $e');
      _userModel = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({String? name, String? role}) async {
    if (_userModel != null && _auth.currentUser != null) {
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          if (name != null) 'name': name,
          if (role != null) 'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Reload user data
        await loadUserFromFirestore(_auth.currentUser!.uid);
      } catch (e) {
        if (kDebugMode) print('Error updating profile: $e');
        rethrow;
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userModel = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error signing out: $e');
      rethrow;
    }
  }

  // Quick login for development purposes - only used in debug builds
  Future<void> quickLogin(String role, {String? name, String? email}) async {
    if (kDebugMode) {
      // Create a mock user for development purposes
      _userModel = UserModel(
        uid: 'dev_${role.toLowerCase()}_user',
        name: name ?? '${role.substring(0, 1).toUpperCase() + role.substring(1).toLowerCase()} User',
        email: email ?? '${role.toLowerCase()}@example.com',
        phone: null,
        role: role,
        gender: null,
        isActive: true,
        createdAt: DateTime.now(),
      );
      _isLoggedIn = true;
      notifyListeners();
    } else {
      throw Exception('Quick login is only available in debug mode');
    }
  }

  // Helper method to normalize phone numbers
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it already starts with +, return as is
    if (normalized.startsWith('+')) {
      return normalized;
    }

    // If it starts with 00, replace with +
    if (normalized.startsWith('00')) {
      return '+${normalized.substring(2)}';
    }

    // Define country codes and formats for various countries
    // European Countries
    const Map<String, Map<String, dynamic>> countries = {
      // Benin
      'BJ': {'code': '+229', 'lengths': [8], 'localStart': '0'},
      // Sierra Leone
      'SL': {'code': '+232', 'lengths': [8], 'localStart': '0'},
      // Saudi Arabia
      'SA': {'code': '+966', 'lengths': [9], 'localStart': '0'},
      // European countries
      'GB': {'code': '+44', 'lengths': [10], 'localStart': '0'}, // UK
      'FR': {'code': '+33', 'lengths': [9], 'localStart': '0'}, // France
      'DE': {'code': '+49', 'lengths': [10, 11], 'localStart': '0'}, // Germany
      'IT': {'code': '+39', 'lengths': [9, 10], 'localStart': ''}, // Italy
      'ES': {'code': '+34', 'lengths': [9], 'localStart': ''}, // Spain
      'PL': {'code': '+48', 'lengths': [9], 'localStart': ''}, // Poland
      'NL': {'code': '+31', 'lengths': [9], 'localStart': '0'}, // Netherlands
      'BE': {'code': '+32', 'lengths': [9], 'localStart': '0'}, // Belgium
      'CZ': {'code': '+420', 'lengths': [9], 'localStart': ''}, // Czech Republic
      'RO': {'code': '+40', 'lengths': [9], 'localStart': '0'}, // Romania
      'GR': {'code': '+30', 'lengths': [10], 'localStart': ''}, // Greece
      'PT': {'code': '+351', 'lengths': [9], 'localStart': ''}, // Portugal
      'HU': {'code': '+36', 'lengths': [9], 'localStart': '0'}, // Hungary
      'AT': {'code': '+43', 'lengths': [10, 11, 12, 13], 'localStart': ''}, // Austria
      'BG': {'code': '+359', 'lengths': [9], 'localStart': '0'}, // Bulgaria
      'DK': {'code': '+45', 'lengths': [8], 'localStart': ''}, // Denmark
      'FI': {'code': '+358', 'lengths': [9, 10], 'localStart': '0'}, // Finland
      'HR': {'code': '+385', 'lengths': [8, 9], 'localStart': '0'}, // Croatia
      'IE': {'code': '+353', 'lengths': [9], 'localStart': '0'}, // Ireland
      'LT': {'code': '+370', 'lengths': [8], 'localStart': ''}, // Lithuania
      'LU': {'code': '+352', 'lengths': [9], 'localStart': ''}, // Luxembourg
      'LV': {'code': '+371', 'lengths': [8], 'localStart': ''}, // Latvia
      'MT': {'code': '+356', 'lengths': [8], 'localStart': ''}, // Malta
      'NO': {'code': '+47', 'lengths': [8], 'localStart': ''}, // Norway
      'SE': {'code': '+46', 'lengths': [9], 'localStart': '0'}, // Sweden
      'SI': {'code': '+386', 'lengths': [8], 'localStart': '0'}, // Slovenia
      'SK': {'code': '+421', 'lengths': [9], 'localStart': '0'}, // Slovakia
      'AL': {'code': '+355', 'lengths': [9], 'localStart': '0'}, // Albania
      'EE': {'code': '+372', 'lengths': [7, 8], 'localStart': ''}, // Estonia
      'RS': {'code': '+381', 'lengths': [9], 'localStart': '0'}, // Serbia
      'CH': {'code': '+41', 'lengths': [9], 'localStart': '0'}, // Switzerland
      'CY': {'code': '+357', 'lengths': [8], 'localStart': ''}, // Cyprus
      'IS': {'code': '+354', 'lengths': [7], 'localStart': ''}, // Iceland
      'LI': {'code': '+423', 'lengths': [7], 'localStart': ''}, // Liechtenstein
      'MC': {'code': '+377', 'lengths': [8, 9], 'localStart': ''}, // Monaco
      'ME': {'code': '+382', 'lengths': [8, 9], 'localStart': '0'}, // Montenegro
      'MK': {'code': '+389', 'lengths': [8], 'localStart': '0'}, // North Macedonia
      'AD': {'code': '+376', 'lengths': [6], 'localStart': ''}, // Andorra
      'GI': {'code': '+350', 'lengths': [8], 'localStart': ''}, // Gibraltar
      'VA': {'code': '+379', 'lengths': [10], 'localStart': ''}, // Vatican City
    };

    // Check if the normalized number matches any specific country length pattern
    for (var country in countries.values) {
      List<int> lengths = country['lengths'] as List<int>;
      bool hasMatchingLength = lengths.any((length) => normalized.length == length);

      if (hasMatchingLength && country['localStart'] == '') {
        // For countries where the full number without country code is provided
        return '${country['code']}$normalized';
      }
    }

    // Check if it starts with 0 (common in many countries for domestic dialing)
    if (normalized.startsWith('0')) {
      // Check if the number length matches any known country pattern
      for (var country in countries.values) {
        List<int> lengths = country['lengths'] as List<int>;
        bool hasMatchingLength = lengths.any((length) => normalized.length == 1 + length);

        if (hasMatchingLength && country['localStart'] == '0') {
          return '${country['code']}${normalized.substring(1)}';
        }
      }
      // Default to Benin if no match is found
      return '+229${normalized.substring(1)}';
    }

    // If none of the above, return as is with + prefix (assuming it has the country code already)
    return '+$normalized';
  }
}
