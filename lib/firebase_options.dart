// Firebase config for TravelMate (project travel-mate-vn). Hand-written from the Firebase console
// values (Android google-services.json + Web app config) instead of running `flutterfire configure`.
// These are public client identifiers, not secrets. Only Android + Web are supported targets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'FirebaseOptions are not configured for $defaultTargetPlatform — '
          'only Android and Web are set up.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4P1zzE1gl2jmbhQu3lczrdQgeYaFbvDE',
    appId: '1:542406829306:web:b31177524b6fe0aff21543',
    messagingSenderId: '542406829306',
    projectId: 'travel-mate-vn',
    authDomain: 'travel-mate-vn.firebaseapp.com',
    storageBucket: 'travel-mate-vn.firebasestorage.app',
    measurementId: 'G-60R9ERJE6X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArgiIrN2hAt4Y5CiINI8gznq7ouhANQZc',
    appId: '1:542406829306:android:8c24bf5310ace84ff21543',
    messagingSenderId: '542406829306',
    projectId: 'travel-mate-vn',
    storageBucket: 'travel-mate-vn.firebasestorage.app',
  );
}
