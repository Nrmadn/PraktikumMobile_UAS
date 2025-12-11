import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // ✅ Android Configuration (dari google-services.json Anda)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUvw-4VwE5Pjds7eRRr-8yVfZiblprPjg',
    appId: '1:102953628830:android:feffa0c0767eee14a2778f',
    messagingSenderId: '102953628830',
    projectId: 'targetibadah-gamifikasi',
    storageBucket: 'targetibadah-gamifikasi.firebasestorage.app',
  );

  // ✅ iOS Configuration (jika diperlukan di masa depan)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUvw-4VwE5Pjds7eRRr-8yVfZiblprPjg',
    appId: '1:102953628830:ios:XXXXXXXXXXXXXX', // Ganti jika ada iOS
    messagingSenderId: '102953628830',
    projectId: 'targetibadah-gamifikasi',
    storageBucket: 'targetibadah-gamifikasi.firebasestorage.app',
    iosBundleId: 'com.example.targetibadahGamifikasi',
  );
}