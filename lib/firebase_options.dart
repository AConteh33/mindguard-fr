import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBojaKFDqMhv3WWwI7Bhm8b8Q483nk3Tdc',
    appId: '1:404679292252:web:84718858b09fd097ed3d99',
    messagingSenderId: '404679292252',
    projectId: 'mind-guard-fr-81a22',
    authDomain: 'mind-guard-fr-81a22.firebaseapp.com',
    storageBucket: 'mind-guard-fr-81a22.firebasestorage.app',
    measurementId: 'G-699ZW6KS21',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnPI5PsaxW5F26MhoUxco7Rkxw-j9ErEU',
    appId: '1:404679292252:android:f2271c6ee2dd0fe7ed3d99',
    messagingSenderId: '404679292252',
    projectId: 'mind-guard-fr-81a22',
    storageBucket: 'mind-guard-fr-81a22.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_DQA29xx8fD4oE2xoCdG8h0WjImrjmg8',
    appId: '1:404679292252:ios:0dd6cd8e6a619985ed3d99',
    messagingSenderId: '404679292252',
    projectId: 'mind-guard-fr-81a22',
    storageBucket: 'mind-guard-fr-81a22.firebasestorage.app',
    iosBundleId: 'com.example.mindguardFr',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC_DQA29xx8fD4oE2xoCdG8h0WjImrjmg8',
    appId: '1:404679292252:ios:0dd6cd8e6a619985ed3d99',
    messagingSenderId: '404679292252',
    projectId: 'mind-guard-fr-81a22',
    storageBucket: 'mind-guard-fr-81a22.firebasestorage.app',
    iosBundleId: 'com.example.mindguardFr',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBojaKFDqMhv3WWwI7Bhm8b8Q483nk3Tdc',
    appId: '1:404679292252:web:ba22de49fdfc73c6ed3d99',
    messagingSenderId: '404679292252',
    projectId: 'mind-guard-fr-81a22',
    authDomain: 'mind-guard-fr-81a22.firebaseapp.com',
    storageBucket: 'mind-guard-fr-81a22.firebasestorage.app',
    measurementId: 'G-Z043CNHYDZ',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789:linux:XXXXXXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: '123456789',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
  );
}