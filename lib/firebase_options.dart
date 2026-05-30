// File generated from android/app/google-services.json (Firebase project: lendledgerapp).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for web in this project.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Add ios/Runner/GoogleService-Info.plist and run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYZeiEvZMqY1tQbwhKGiMcmMTUXbPrrMo',
    appId: '1:988730934305:android:10d516cc05672f47c18f60',
    messagingSenderId: '988730934305',
    projectId: 'lendledgerapp',
    storageBucket: 'lendledgerapp.firebasestorage.app',
  );
}
