import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_bootstrap.dart';

/// Privacy-safe analytics. Only allow-listed events and parameters can be
/// sent, and parameter values must be short enum-like strings, so no
/// personal data (names, phone numbers, addresses, free text, answers,
/// photos) can ever reach Analytics.
class Analytics {
  Analytics(this._enabled);
  final bool _enabled;

  static const _allowed = <String, Set<String>>{
    'onboarding_complete': {'language'},
    'check_started': {'check'},
    'check_completed': {'check', 'level'},
    'emergency_opened': {'source'},
    'evidence_added': {'type'},
    'report_generated': {},
    'letter_generated': {'problem', 'recipient', 'language'},
    'chat_message_sent': {},
    'chat_emergency_blocked': {},
    'language_changed': {'language'},
  };
  static final _safeValue = RegExp(r'^[a-z0-9_]{1,40}$');

  Future<void> log(String event, [Map<String, String> params = const {}]) async {
    final allowedKeys = _allowed[event];
    assert(allowedKeys != null, 'Analytics event "$event" is not allow-listed');
    if (allowedKeys == null) return;
    final clean = <String, Object>{
      for (final e in params.entries)
        if (allowedKeys.contains(e.key) && _safeValue.hasMatch(e.value)) e.key: e.value,
    };
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: event, parameters: clean);
    } catch (e) {
      debugPrint('analytics failed: $e');
    }
  }
}

final analyticsProvider = Provider<Analytics>((ref) => Analytics(ref.watch(firebaseAvailableProvider)));
