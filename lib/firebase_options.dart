import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Replace this file by running `flutterfire configure`.
/// This placeholder avoids web runtime type crashes and shows a clear setup error.
class DefaultFirebaseOptions {
  static const bool isConfigured = true;

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
          'Firebase options are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAocnCFr1RdD0RB-48U4ulvyJdCT300LJM',
    appId: '1:818523681726:web:f9439536f111eb5d21bfef',
    messagingSenderId: '818523681726',
    projectId: 'pbl6-e6ea4',
    authDomain: 'pbl6-e6ea4.firebaseapp.com',
    databaseURL:
        'https://pbl6-e6ea4-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'pbl6-e6ea4.firebasestorage.app',
    measurementId: 'G-51DLK5H2S6',
  );

  // Placeholder values. Generate real values using `flutterfire configure`.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4h5tdUJF40iKVvUCfjPu70smMcczWbXA',
    appId: '1:818523681726:android:940d6c31f0de7d5e21bfef',
    messagingSenderId: '818523681726',
    projectId: 'pbl6-e6ea4',
    databaseURL:
        'https://pbl6-e6ea4-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'pbl6-e6ea4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAAHjNavsHfCcYddK2Po7Q_ZoReUSSF4uE',
    appId: '1:818523681726:ios:649c89f093d0ec3321bfef',
    messagingSenderId: '818523681726',
    projectId: 'pbl6-e6ea4',
    databaseURL:
        'https://pbl6-e6ea4-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'pbl6-e6ea4.firebasestorage.app',
    iosBundleId: 'com.example.smartHomeApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAAHjNavsHfCcYddK2Po7Q_ZoReUSSF4uE',
    appId: '1:818523681726:ios:649c89f093d0ec3321bfef',
    messagingSenderId: '818523681726',
    projectId: 'pbl6-e6ea4',
    databaseURL:
        'https://pbl6-e6ea4-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'pbl6-e6ea4.firebasestorage.app',
    iosBundleId: 'com.example.smartHomeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAocnCFr1RdD0RB-48U4ulvyJdCT300LJM',
    appId: '1:818523681726:web:c49c5bd8c004284321bfef',
    messagingSenderId: '818523681726',
    projectId: 'pbl6-e6ea4',
    authDomain: 'pbl6-e6ea4.firebaseapp.com',
    databaseURL:
        'https://pbl6-e6ea4-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'pbl6-e6ea4.firebasestorage.app',
    measurementId: 'G-HZR8PYGNBQ',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_LINUX_API_KEY',
    appId: 'REPLACE_WITH_LINUX_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    databaseURL: 'REPLACE_WITH_DATABASE_URL',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );
}
