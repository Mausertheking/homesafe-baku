import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import 'firebase_bootstrap.dart';

/// Region of all callable functions. Must match functions/src/config.ts.
const functionsRegion = 'europe-west1';

class BackendUnavailable implements Exception {}

class Callables {
  Callables(this._available);
  final bool _available;

  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data,
      {Duration timeout = const Duration(seconds: 60)}) async {
    if (!_available) throw BackendUnavailable();
    final functions = FirebaseFunctions.instanceFor(region: functionsRegion);
    if (useEmulators) functions.useFunctionsEmulator(emulatorHost, 5001);
    final fn = functions.httpsCallable(name,
        options: HttpsCallableOptions(timeout: timeout, limitedUseAppCheckToken: !useEmulators));
    final result = await fn.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(result.data);
  }
}

final callablesProvider = Provider<Callables>((ref) => Callables(ref.watch(firebaseAvailableProvider)));
