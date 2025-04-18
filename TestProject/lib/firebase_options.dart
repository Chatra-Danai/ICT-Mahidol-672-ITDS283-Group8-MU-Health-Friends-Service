// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAl3f7VL_YAKza3HnKTdP3ah09hrLtJYJ8',
    appId: '1:505742813441:web:b0f3c784febfeb29419300',
    messagingSenderId: '505742813441',
    projectId: 'mu-health-friends-service',
    authDomain: 'mu-health-friends-service.firebaseapp.com',
    storageBucket: 'mu-health-friends-service.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA5AIJDTsnxoNGeOUoyjLPeCKOmFC7G97I',
    appId: '1:505742813441:android:d6e62e8239288568419300',
    messagingSenderId: '505742813441',
    projectId: 'mu-health-friends-service',
    storageBucket: 'mu-health-friends-service.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMBcloxE3a14WY6oSF6KpFYjjbTgFJ56w',
    appId: '1:505742813441:ios:a31d60665c35eeda419300',
    messagingSenderId: '505742813441',
    projectId: 'mu-health-friends-service',
    storageBucket: 'mu-health-friends-service.firebasestorage.app',
    iosBundleId: 'com.example.userSide',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAMBcloxE3a14WY6oSF6KpFYjjbTgFJ56w',
    appId: '1:505742813441:ios:a31d60665c35eeda419300',
    messagingSenderId: '505742813441',
    projectId: 'mu-health-friends-service',
    storageBucket: 'mu-health-friends-service.firebasestorage.app',
    iosBundleId: 'com.example.userSide',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAl3f7VL_YAKza3HnKTdP3ah09hrLtJYJ8',
    appId: '1:505742813441:web:8ac67cf15cf227b2419300',
    messagingSenderId: '505742813441',
    projectId: 'mu-health-friends-service',
    authDomain: 'mu-health-friends-service.firebaseapp.com',
    storageBucket: 'mu-health-friends-service.firebasestorage.app',
  );

}