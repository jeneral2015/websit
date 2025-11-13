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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqWBz3Wocajqmjy-gpqbpsL4w-JrwZN9U',
    appId: '1:55082936997:web:2630ae4bdb744a045fbb4c',
    messagingSenderId: '55082936997',
    projectId: 'dr-sara-clinic',
    authDomain: 'dr-sara-clinic.firebaseapp.com',
    storageBucket: 'dr-sara-clinic.firebasestorage.app',
    measurementId: 'G-CC9C0GJBXD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqWBz3Wocajqmjy-gpqbpsL4w-JrwZN9U',
    appId: '1:55082936997:web:2630ae4bdb744a045fbb4c',
    messagingSenderId: '55082936997',
    projectId: 'dr-sara-clinic',
    authDomain: 'dr-sara-clinic.firebaseapp.com',
    storageBucket: 'dr-sara-clinic.firebasestorage.app',
    measurementId: 'G-CC9C0GJBXD',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqWBz3Wocajqmjy-gpqbpsL4w-JrwZN9U',
    appId: '1:55082936997:web:2630ae4bdb744a045fbb4c',
    messagingSenderId: '55082936997',
    projectId: 'dr-sara-clinic',
    authDomain: 'dr-sara-clinic.firebaseapp.com',
    storageBucket: 'dr-sara-clinic.firebasestorage.app',
    measurementId: 'G-CC9C0GJBXD',
  );
}
