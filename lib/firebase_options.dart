import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web; // Fallback ke web jika platform tidak terdeteksi
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8fymJp3DaXKGozJhqD_agIKZ3fxBT4',
    appId: '1:773541060798:web:be1c8fff24cc969b4ffeeef',
    messagingSenderId: '773541060798',
    projectId: 'stok-opname-283b7',
    authDomain: 'stok-opname-283b7.firebaseapp.com',
    storageBucket: 'stok-opname-283b7.firebasestorage.app',
    measurementId: 'G-985VDY6XDX',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8fymJp3DaXKGozJhqD_agIKZ3fxBT4',
    authDomain: 'stok-opname-283b7.firebaseapp.com',
    projectId: 'stok-opname-283b7',
    storageBucket: 'stok-opname-283b7.firebasestorage.app',
    messagingSenderId: '773541060798',
    appId: '1:773541060798:web:be1c8fff24cc969b4ffeef',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8fymJp3DaXKGozJhqD_agIKZ3fxBT4',
    authDomain: 'stok-opname-283b7.firebaseapp.com',
    projectId: 'stok-opname-283b7',
    storageBucket: 'stok-opname-283b7.firebasestorage.app',
    messagingSenderId: '773541060798',
    appId: '1:773541060798:web:be1c8fff24cc969b4ffeef',
    iosBundleId: 'com.example.mobileOpnameBarang',
  );
}