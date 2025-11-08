// firebase_options.dart - Generated from Firebase configuration files
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
    appId: '1:874650302795:android:798d58c0997c1eafac10ce',
    messagingSenderId: '874650302795',
    projectId: 'parkme-lisboa',
    storageBucket: 'parkme-lisboa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChHUVQDI0yHeSRjnlI1XzAGAQIM8jexIE',
    appId: '1:874650302795:ios:de2546e4c1a72d0fac10ce',
    messagingSenderId: '874650302795',
    projectId: 'parkme-lisboa',
    storageBucket: 'parkme-lisboa.firebasestorage.app',
  );
}