import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import 'emergency_keywords.dart';

class EmergencyNumber {
  const EmergencyNumber({required this.id, required this.labelKey, required this.number});
  final String id;
  final String labelKey;
  final String number;

  static EmergencyNumber fromJson(Map<String, Object?> j) =>
      EmergencyNumber(id: j['id'] as String, labelKey: j['labelKey'] as String, number: j['number'] as String);

  Map<String, Object?> toJson() => {'id': id, 'labelKey': labelKey, 'number': number};
}

class EmergencyConfig {
  const EmergencyConfig({required this.numbers, required this.verified, required this.version});
  final List<EmergencyNumber> numbers;

  /// False until the team verifies the numbers (shows a banner in debug builds).
  final bool verified;
  final int version;

  static EmergencyConfig fromJson(Map<String, Object?> j) => EmergencyConfig(
        numbers: [for (final n in j['numbers'] as List) EmergencyNumber.fromJson((n as Map).cast())],
        verified: j['verified'] == true,
        version: j['version'] as int? ?? 0,
      );

  Map<String, Object?> toJson() =>
      {'numbers': [for (final n in numbers) n.toJson()], 'verified': verified, 'version': version};
}

const _cacheKey = 'emergency.config.cache';

/// Loads the emergency numbers with NO network: a copy of config/app that was
/// cached on a previous online run wins, otherwise the bundled file.
/// Called from main() before the first frame (takes a few milliseconds).
Future<EmergencyConfig> loadEmergencyConfig(AssetBundle bundle, {String? cachedJson}) async {
  if (cachedJson != null) {
    try {
      return EmergencyConfig.fromJson(jsonDecode(cachedJson) as Map<String, Object?>);
    } catch (_) {
      // Corrupt cache: fall through to the bundled copy.
    }
  }
  final raw = await bundle.loadString('assets/config/emergency.json');
  return EmergencyConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

String? readCachedEmergencyConfig(SharedPreferences prefs) => prefs.getString(_cacheKey);

/// Stores a newer remote config for next time. Only accepts well-formed data
/// with at least one number, so a bad remote value can never empty the screen.
Future<void> cacheRemoteEmergencyConfig(Ref ref, Object? remoteNumbers, {required bool verified, required int version}) async {
  if (remoteNumbers is! List || remoteNumbers.isEmpty) return;
  try {
    final config = EmergencyConfig(
      numbers: [for (final n in remoteNumbers) EmergencyNumber.fromJson((n as Map).cast())],
      verified: verified,
      version: version,
    );
    await ref.read(sharedPreferencesProvider).setString(_cacheKey, jsonEncode(config.toJson()));
  } catch (_) {
    // Ignore malformed remote config.
  }
}

/// Both overridden in main() with preloaded values.
final emergencyConfigProvider = Provider<EmergencyConfig>((ref) => throw UnimplementedError('preloaded in main'));
final emergencyDetectorProvider =
    Provider<EmergencyKeywordDetector>((ref) => throw UnimplementedError('preloaded in main'));
