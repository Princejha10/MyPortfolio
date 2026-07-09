import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDi0kQy1wXgWSqiC8Mgs9izG2YwlA01IUw',
        appId: '1:439682624436:web:7cef02959b081ab90120e1',
        messagingSenderId: '439682624436',
        projectId: 'finesense-3438a',
        storageBucket: 'finesense-3438a.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDi0kQy1wXgWSqiC8Mgs9izG2YwlA01IUw',
          appId: '1:439682624436:android:7cef02959b081ab90120e1',
          messagingSenderId: '439682624436',
          projectId: 'finesense-3438a',
          storageBucket: 'finesense-3438a.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDi0kQy1wXgWSqiC8Mgs9izG2YwlA01IUw',
          appId: '1:439682624436:ios:7cef02959b081ab90120e1',
          messagingSenderId: '439682624436',
          projectId: 'finesense-3438a',
          storageBucket: 'finesense-3438a.firebasestorage.app',
          iosBundleId: 'com.finsense.app',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
