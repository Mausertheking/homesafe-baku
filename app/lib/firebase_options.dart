// TODO(team): replace the production part of this file by running
// `flutterfire configure` with the real HomeSafe Firebase project.
//
// Two modes today:
// - Default build: Firebase is not configured, the app runs offline-only
//   (emergency screen, onboarding and the checks work; account features say
//   "not available").
// - `--dart-define=USE_EMULATORS=true`: uses the local Firebase emulators with
//   a demo project, so every feature can be tried on this computer. Demo
//   project ids ("demo-...") can never reach real Firebase services.
import 'package:firebase_core/firebase_core.dart';

const useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Host of the emulators. Override for a phone on the same Wi-Fi, or use
/// 10.0.2.2 from the Android emulator.
const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (useEmulators) {
      return const FirebaseOptions(
        apiKey: 'demo-api-key', // Not a real key: demo projects need none.
        appId: '1:1234567890:web:0000000000000000homesafe',
        messagingSenderId: '1234567890',
        projectId: 'demo-homesafe',
        authDomain: 'demo-homesafe.firebaseapp.com',
        storageBucket: 'demo-homesafe.appspot.com',
      );
    }
    throw UnsupportedError('Firebase is not configured yet. Run `flutterfire configure`.');
  }
}
