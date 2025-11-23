import 'package:firebase_auth/firebase_auth.dart';



class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String role, {
    String? name,
    String? gender,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // After successful registration, we would typically update the user's profile
      // and store additional user data in Firestore
      if (user != null) {
        // In a real implementation, we would save user details to Firestore here
        // await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        //   'uid': user.uid,
        //   'email': email,
        //   'role': role,
        //   'name': name ?? '',
        //   'gender': gender ?? '',
        //   'createdAt': FieldValue.serverTimestamp(),
        // });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, {String? name}) async {
    try {
      if (name != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update user email
  Future<void> updateUserEmail(String newEmail, String password) async {
    try {
      // For email updates, Firebase typically requires re-authentication
      // This is a simplified implementation - in practice, you'd need to implement
      // proper re-authentication flow
      // await _auth.currentUser!.updateEmail(newEmail);
    } catch (e) {
      rethrow;
    }
  }

  // Change user password
  Future<void> changeUserPassword(String currentPassword, String newPassword) async {
    try {
      // For password changes, Firebase typically requires re-authentication
      // This would involve creating a new credential with the current password
      // and re-authenticating the user before changing the password
      await _auth.currentUser!.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhone(
    String phoneNumber,
    PhoneVerificationCompleted verificationCompleted,
    PhoneVerificationFailed verificationFailed,
    PhoneCodeSent codeSent,
    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verify SMS code
  Future<UserCredential> verifySMSCode(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Register with phone number
  Future<void> registerWithPhone(
    String phoneNumber,
    PhoneVerificationCompleted verificationCompleted,
    PhoneVerificationFailed verificationFailed,
    PhoneCodeSent codeSent,
    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      rethrow;
    }
  }
}