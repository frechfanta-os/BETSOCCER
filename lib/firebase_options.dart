import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration FlutterFire pour BETSOCCER (Project: betsoccer-60834)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'BND3aJqIS2RcH_um_BUe-KHCCpfEzdJCanC6X19KymUbXhuzWkcD0b7zjVJXc0d0SXzrQm2GnYzHfwdmEdu8uJA',
    appId: '1:561415224411:android:com_ghdinteractivestudio_betsoccer',
    messagingSenderId: '561415224411',
    projectId: 'betsoccer-60834',
    storageBucket: 'betsoccer-60834.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'BND3aJqIS2RcH_um_BUe-KHCCpfEzdJCanC6X19KymUbXhuzWkcD0b7zjVJXc0d0SXzrQm2GnYzHfwdmEdu8uJA',
    appId: '1:561415224411:web:com_ghdinteractivestudio_betsoccer',
    messagingSenderId: '561415224411',
    projectId: 'betsoccer-60834',
    storageBucket: 'betsoccer-60834.firebasestorage.app',
  );
}
