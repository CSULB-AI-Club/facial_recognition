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
    apiKey: 'AIzaSyDwNldIl0crEMZVMdlRloGFSB97HMdhj8M',
    appId: '1:778982725198:web:323ad83657ba130769951f',
    messagingSenderId: '778982725198',
    projectId: 'faceapp-d1b7b',
    authDomain: 'faceapp-d1b7b.firebaseapp.com',
    storageBucket: 'faceapp-d1b7b.firebasestorage.app',
    measurementId: 'G-FPSYFBDMY5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-66sneh4lkHtMH_CmE1YkrZY5ql8yQoA',
    appId: '1:778982725198:android:55f6cb920d4050bc69951f',
    messagingSenderId: '778982725198',
    projectId: 'faceapp-d1b7b',
    storageBucket: 'faceapp-d1b7b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_F0PEZzhWMRC5_y1b8K0GT7L7Xdv_hrQ',
    appId: '1:778982725198:ios:d8578fdb1642139d69951f',
    messagingSenderId: '778982725198',
    projectId: 'faceapp-d1b7b',
    storageBucket: 'faceapp-d1b7b.firebasestorage.app',
    iosBundleId: 'com.example.facialRecognition',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA_F0PEZzhWMRC5_y1b8K0GT7L7Xdv_hrQ',
    appId: '1:778982725198:ios:d8578fdb1642139d69951f',
    messagingSenderId: '778982725198',
    projectId: 'faceapp-d1b7b',
    storageBucket: 'faceapp-d1b7b.firebasestorage.app',
    iosBundleId: 'com.example.facialRecognition',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDwNldIl0crEMZVMdlRloGFSB97HMdhj8M',
    appId: '1:778982725198:web:80176cb9aa50451b69951f',
    messagingSenderId: '778982725198',
    projectId: 'faceapp-d1b7b',
    authDomain: 'faceapp-d1b7b.firebaseapp.com',
    storageBucket: 'faceapp-d1b7b.firebasestorage.app',
    measurementId: 'G-TE9R5LX8WF',
  );
}
