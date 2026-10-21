import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/content_strings.dart';
import 'core/firebase_bootstrap.dart';
import 'core/settings.dart';
import 'features/emergency/emergency_config.dart';
import 'features/emergency/emergency_keywords.dart';

/// Startup is deliberately small: only LOCAL data is loaded before the first
/// frame (preferences, bundled emergency numbers, bundled texts). Firebase
/// starts afterwards in the background, so the emergency screen is usable
/// within the first second, with or without internet.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final (emergency, catalog, keywords, _) = await (
    loadEmergencyConfig(rootBundle, cachedJson: readCachedEmergencyConfig(prefs)),
    ContentCatalog.load(rootBundle),
    rootBundle.loadString('assets/config/emergency_keywords.json'),
    initializeDateFormatting(),
  ).wait;

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    emergencyConfigProvider.overrideWithValue(emergency),
    contentCatalogProvider.overrideWithValue(catalog),
    emergencyDetectorProvider.overrideWithValue(EmergencyKeywordDetector.fromJsonString(keywords)),
  ]);

  runApp(UncontrolledProviderScope(container: container, child: const HomeSafeApp()));

  // Not awaited: Firebase must never block the UI.
  container.read(firebaseReadyProvider);
}
