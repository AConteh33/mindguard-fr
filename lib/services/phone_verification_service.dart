import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationService {
  String? verificationId;
  String? phoneNumber;
  String? tempName;
  String? tempRole;
  String? tempGender;
  
  // Callbacks for handling phone verification events
  Function(String, int?)? codeSentCallback;
  Function(FirebaseAuthException)? verificationFailedCallback;
  Function(String)? codeAutoRetrievalTimeoutCallback;
  
  // These are set when the verification is completed
  PhoneAuthCredential? credential;
  Function(PhoneAuthCredential)? verificationCompletedCallback;
  
  static final PhoneVerificationService _instance = PhoneVerificationService._internal();
  factory PhoneVerificationService() => _instance;
  PhoneVerificationService._internal();
  
  void clear() {
    verificationId = null;
    phoneNumber = null;
    tempName = null;
    tempRole = null;
    tempGender = null;
  }
}