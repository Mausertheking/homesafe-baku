import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content_strings.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';
import '../../rules_engine/rules_engine.dart';
import '../emergency/emergency_config.dart';

const checkIds = ['gas_co', 'damp_mold'];
String _cacheKey(String check) => 'rules.cache.$check';

/// The rule set to use for a check: a newer copy downloaded from Firestore if
/// we have one and it is valid, otherwise the copy bundled with the app.
/// Never needs the network.
final ruleSetProvider = FutureProvider.family<RuleSet, String>((ref, check) async {
  final bundled = RuleSet.fromJson(jsonDecode(await rootBundle.loadString('assets/rules/$check.json')));
  final cached = ref.read(sharedPreferencesProvider).getString(_cacheKey(check));
  if (cached != null) {
    try {
      final remote = RuleSet.fromJson(jsonDecode(cached));
      if (remote.rulesVersion > bundled.rulesVersion) return remote;
    } catch (e) {
      debugPrint('ignoring bad cached rules for $check: $e');
    }
  }
  return bundled;
});

/// Runs once Firebase is up: reads config/app, caches emergency numbers for
/// offline use, and downloads newer rules. Any failure leaves the current
/// (bundled or cached) data in place.
final remoteSyncProvider = FutureProvider<void>((ref) async {
  if (!ref.watch(firebaseAvailableProvider)) return;
  final db = FirebaseFirestore.instance;
  final prefs = ref.read(sharedPreferencesProvider);
  try {
    final config = (await db.doc('config/app').get()).data();
    if (config == null) return;

    await cacheRemoteEmergencyConfig(ref, config['emergencyNumbers'],
        verified: config['emergencyNumbersVerified'] == true, version: (config['rulesVersion'] as num?)?.toInt() ?? 0);

    final remoteVersion = (config['rulesVersion'] as num?)?.toInt();
    if (remoteVersion == null) return;
    final content = ref.read(contentCatalogProvider).forLanguage('en');
    for (final check in checkIds) {
      final current = await ref.read(ruleSetProvider(check).future);
      if (remoteVersion <= current.rulesVersion) continue;
      final docs = await db.collection('rules').where('check', isEqualTo: check).get();
      final json = {
        'check': check,
        'rulesVersion': remoteVersion,
        'rules': [for (final d in docs.docs) d.data()['rule']],
      };
      final RuleSet parsed;
      try {
        parsed = RuleSet.fromJson(json);
      } on RuleFormatException catch (e) {
        debugPrint('rejecting remote rules for $check: $e');
        continue;
      }
      // Rules may only use texts this app version ships with.
      final missing = [
        for (final r in parsed.rules) ...[r.result.reasonKey, ...r.result.stepKeys]
      ].where((k) => !content.has(k)).toSet();
      if (missing.isNotEmpty || parsed.rules.isEmpty) {
        debugPrint('rejecting remote rules for $check, unknown text keys: $missing');
        continue;
      }
      await prefs.setString(_cacheKey(check), jsonEncode(json));
      ref.invalidate(ruleSetProvider(check));
    }
  } catch (e) {
    debugPrint('remote sync failed (offline?): $e');
  }
});
