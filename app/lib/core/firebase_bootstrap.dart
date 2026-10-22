import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';

/// Starts Firebase in the background. The app never waits for this before
/// showing UI: the emergency screen, onboarding and the checks all work
/// without Firebase (no internet, or no project configured yet).
///
/// Resolves to `true` when Firebase is usable, `false` otherwise.
/// reCAPTCHA v3 site key for App Check on the web (public, not a secret).
const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

final firebaseReadyProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase not available, running offline-only: $e');
    return false;
  }

  if (useEmulators) {
    // Local test backend (see firebase_options.dart). No App Check locally.
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
    debugPrint('HomeSafe: using local Firebase emulators on $emulatorHost');
    return true;
  }

  try {
    // App Check protects Firestore, Storage and Functions from abuse.
    // Debug providers in debug builds; register their tokens in the console.
    // Web: App Check needs a reCAPTCHA v3 site key, passed at build time
    // (--dart-define=RECAPTCHA_SITE_KEY=...; a site key is public). Without
    // one the web build skips App Check, and the server must be deployed
    // with APP_CHECK_REQUIRED=false (team testing only).
    if (!kIsWeb || recaptchaSiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: kIsWeb ? ReCaptchaV3Provider(recaptchaSiteKey) : null,
        providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
  } catch (e) {
    debugPrint('App Check activation failed: $e');
  }

  // Offline persistence (on by default on mobile; set explicitly so it is
  // obvious and so the cache is big enough for photos' metadata and history).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );
  return true;
});

/// Convenience: `true` only once Firebase finished starting successfully.
final firebaseAvailableProvider = Provider<bool>((ref) => ref.watch(firebaseReadyProvider).value ?? false);
